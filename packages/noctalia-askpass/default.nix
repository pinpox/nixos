{
  writeShellApplication,
  noctalia,
  jq,
  procps,
  coreutils,
}:
writeShellApplication {
  name = "noctalia-askpass";
  runtimeInputs = [
    noctalia
    jq
    procps
    coreutils
  ];
  text = ''
    # noctalia-askpass — askpass backend that uses noctalia to show
    # a password/PIN entry dialog. Implements the standard askpass
    # contract: prompt as $1, password printed to stdout, exit 1 on cancel.
    #
    # Usage:
    #   SSH_ASKPASS=/path/to/noctalia-askpass
    #   SUDO_ASKPASS=/path/to/noctalia-askpass
    #   PICOHSM_ASKPASS_BACKEND=/path/to/noctalia-askpass
    #
    # The dialog is the pinpox/askpass plugin panel (home-manager noctalia
    # module); it writes the answer to the FIFO created here.

    PROMPT="''${1:-Enter password}"

    # Figure out what program is requesting the password by walking the process tree
    CALLER=""
    if [ -n "''${PPID:-}" ]; then
      PID="$PPID"
      for _ in 1 2 3 4 5; do
        if [ "$PID" -le 1 ] 2>/dev/null; then break; fi
        CMD=$(ps -o comm= "$PID" 2>/dev/null || true)
        if [ -n "$CMD" ] && [ "$CMD" != "bash" ] && [ "$CMD" != "sh" ] && [ "$CMD" != "picohsm-askpass" ] && [ "$CMD" != "noctalia-askpass" ]; then
          if [ -n "$CALLER" ]; then
            CALLER="$CMD → $CALLER"
          else
            CALLER="$CMD"
          fi
        fi
        PID=$(ps -o ppid= "$PID" 2>/dev/null | tr -d ' ' || true)
        if [ -z "$PID" ]; then break; fi
      done
    fi

    # Create a named pipe for the response
    FIFO=$(mktemp -u /tmp/noctalia-askpass-XXXXXX)
    mkfifo -m 600 "$FIFO"
    trap 'rm -f "$FIFO"' EXIT

    CONTEXT=$(jq -cn --arg prompt "$PROMPT" --arg caller "$CALLER" --arg fifo "$FIFO" \
      '{prompt: $prompt, caller: $caller, fifo: $fifo}')

    # `noctalia msg` finds the running instance's socket itself and prints
    # "ok" on success, which must not leak into our stdout (the password
    # channel). A non-zero exit means no shell (or no such panel), in which
    # case nobody would ever write the FIFO below.
    if ! noctalia msg panel-open pinpox/askpass:prompt "$CONTEXT" >/dev/null; then
      echo "noctalia-askpass: could not open the askpass panel; is noctalia running with the pinpox/askpass plugin enabled?" >&2
      exit 1
    fi

    # Block until the panel writes the password (or empty on cancel). The
    # timeout only guards against a panel that never answers.
    PASSWORD=$(timeout 600 cat "$FIFO" || true)

    if [ -z "$PASSWORD" ]; then
      exit 1
    fi

    printf '%s' "$PASSWORD"
  '';
}
