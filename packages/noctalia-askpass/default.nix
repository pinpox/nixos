{
  writeShellApplication,
  noctalia-shell,
  procps,
  coreutils,
}:
writeShellApplication {
  name = "noctalia-askpass";
  runtimeInputs = [
    noctalia-shell
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

    # Ask noctalia to show the password dialog
    noctalia-shell ipc call plugin:noctalia-askpass prompt "$PROMPT" "$CALLER" "$FIFO" &

    # Block until the plugin writes the password (or empty on cancel)
    PASSWORD=$(cat "$FIFO")

    if [ -z "$PASSWORD" ]; then
      exit 1
    fi

    printf '%s' "$PASSWORD"
  '';
}
