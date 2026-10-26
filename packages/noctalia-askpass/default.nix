{
  lib,
  runCommand,
  writeShellApplication,
  noctalia,
  jq,
  procps,
  coreutils,
}:
let
  script = writeShellApplication {
    name = "noctalia-askpass";
    runtimeInputs = [
      noctalia
      jq
      procps
      coreutils
    ];
    text = ''
      # noctalia-askpass — password/PIN entry dialog shown by noctalia (the
      # pinpox/askpass plugin panel, see the home-manager noctalia module).
      # The panel writes the answer to a FIFO created here.
      #
      # Two front-ends, chosen by the name the script is invoked as:
      #
      #   noctalia-askpass    askpass contract: prompt as $1, password on
      #                       stdout, exit 1 on cancel. For SSH_ASKPASS,
      #                       SUDO_ASKPASS, PICOHSM_ASKPASS_BACKEND, ...
      #   pinentry-noctalia   pinentry (Assuan) protocol on stdin/stdout. For
      #                       PINENTRY_PROGRAM, e.g. rage's PIN prompts for
      #                       age plugins.

      # ask PROMPT: show the panel, print the answer to stdout. Returns 1 on
      # cancel or when the panel cannot be opened.
      ask() {
        local prompt="$1"

        # Figure out what program is requesting the password by walking the process tree
        local caller="" pid="$PPID" cmd
        for _ in 1 2 3 4 5; do
          if [ "$pid" -le 1 ] 2>/dev/null; then break; fi
          cmd=$(ps -o comm= "$pid" 2>/dev/null || true)
          if [ -n "$cmd" ] && [ "$cmd" != "bash" ] && [ "$cmd" != "sh" ] && [ "$cmd" != "picohsm-askpass" ] && [ "$cmd" != "noctalia-askpass" ]; then
            if [ -n "$caller" ]; then
              caller="$cmd → $caller"
            else
              caller="$cmd"
            fi
          fi
          pid=$(ps -o ppid= "$pid" 2>/dev/null | tr -d ' ' || true)
          if [ -z "$pid" ]; then break; fi
        done

        # Create a named pipe for the response
        FIFO=$(mktemp -u /tmp/noctalia-askpass-XXXXXX)
        mkfifo -m 600 "$FIFO"
        trap 'rm -f "$FIFO"' EXIT

        local context
        context=$(jq -cn --arg prompt "$prompt" --arg caller "$caller" --arg fifo "$FIFO" \
          '{prompt: $prompt, caller: $caller, fifo: $fifo}')

        # `noctalia msg` finds the running instance's socket itself and prints
        # "ok" on success, which must not leak into our stdout (the password
        # channel). A non-zero exit means no shell (or no such panel), in which
        # case nobody would ever write the FIFO below.
        if ! noctalia msg panel-open pinpox/askpass:prompt "$context" >/dev/null; then
          echo "noctalia-askpass: could not open the askpass panel; is noctalia running with the pinpox/askpass plugin enabled?" >&2
          return 1
        fi

        # Block until the panel writes the password (or empty on cancel). The
        # timeout only guards against a panel that never answers.
        local password
        password=$(timeout 600 cat "$FIFO" || true)
        rm -f "$FIFO"

        if [ -z "$password" ]; then
          return 1
        fi
        printf '%s' "$password"
      }

      # Assuan arguments escape %, CR and LF (and a trailing backslash) as %XX.
      assuan_decode() {
        local s="''${1//\\/\\\\}"
        printf '%b' "''${s//%/\\x}"
      }

      # Data lines must escape %, CR and LF.
      assuan_encode() {
        local s="''${1//%/%25}"
        s="''${s//$'\r'/%0D}"
        printf '%s' "''${s//$'\n'/%0A}"
      }

      # Error codes are gpg-error values with the pinentry error source (5).
      readonly ERR_CANCELED="ERR 83886179 Operation cancelled <Pinentry>"
      readonly ERR_NOT_IMPLEMENTED="ERR 83886149 Not implemented <Pinentry>"
      readonly ERR_UNKNOWN_COMMAND="ERR 83886355 Unknown IPC command <Pinentry>"

      pinentry() {
        local desc="" prompt="" error="" repeat="" repeat_error="" line cmd arg text pin pin2
        echo "OK Pleased to meet you"
        while IFS= read -r line; do
          line="''${line%$'\r'}"
          cmd="''${line%% *}"
          arg=""
          if [ "$cmd" != "$line" ]; then arg=$(assuan_decode "''${line#* }"); fi
          case "''${cmd^^}" in
            SETDESC) desc="$arg"; echo OK ;;
            SETPROMPT) prompt="$arg"; echo OK ;;
            SETERROR) error="$arg"; echo OK ;;
            # The panel has a single input, so a confirmation is a second
            # prompt; matching answers are acknowledged with PIN_REPEATED.
            SETREPEAT) repeat="''${arg:-Repeat}"; echo OK ;;
            SETREPEATERROR) repeat_error="$arg"; echo OK ;;
            # Accepted but not shown: the panel has a fixed layout. SETTIMEOUT
            # is not enforced either; ask() has its own guard, and giving up
            # early would leave the panel open with nobody reading its answer.
            OPTION | SETTITLE | SETOK | SETCANCEL | SETNOTOK | SETTIMEOUT | SETKEYINFO | SETQUALITYBAR | SETQUALITYBAR_TT | SETGENPIN | SETGENPIN_TT | SETREPEATOK | RESET | NOP)
              echo OK ;;
            GETINFO)
              case "$arg" in
                pid) echo "D $$" ;;
                flavor) echo "D noctalia" ;;
              esac
              echo OK ;;
            GETPIN)
              while :; do
                text="''${desc:-''${prompt:-Enter PIN}}"
                if [ -n "$error" ]; then text="$error"$'\n'"$text"; fi
                error=""
                if ! pin=$(ask "$text"); then
                  echo "$ERR_CANCELED"
                  break
                fi
                if [ -n "$repeat" ]; then
                  if ! pin2=$(ask "$repeat"); then
                    echo "$ERR_CANCELED"
                    break
                  fi
                  if [ "$pin" != "$pin2" ]; then
                    error="''${repeat_error:-Entries do not match}"
                    continue
                  fi
                  echo "S PIN_REPEATED"
                fi
                echo "D $(assuan_encode "$pin")"
                echo OK
                break
              done
              pin=""
              pin2="" ;;
            CONFIRM | MESSAGE) echo "$ERR_NOT_IMPLEMENTED" ;;
            BYE) echo "OK closing connection"; return 0 ;;
            "") ;;
            *) echo "$ERR_UNKNOWN_COMMAND" ;;
          esac
        done
      }

      case "$(basename "$0")" in
        pinentry-noctalia) pinentry ;;
        *) ask "''${1:-Enter password}" ;;
      esac
    '';
  };
in
runCommand "noctalia-askpass" { meta.mainProgram = "noctalia-askpass"; } ''
  mkdir -p $out/bin
  ln -s ${lib.getExe script} $out/bin/noctalia-askpass
  ln -s ${lib.getExe script} $out/bin/pinentry-noctalia
''
