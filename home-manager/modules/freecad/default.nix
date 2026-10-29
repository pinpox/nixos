{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.freecad;

  # The MCP server settings go into FreeCAD's own wrapper rather than only the
  # launcher below, so a server started from the workbench toolbar listens on
  # the same address and requires the same token. MCP_* beat the addon's
  # mutable config.json.
  freecad = pkgs.freecad.customize {
    modules = [ pkgs.freecad-ai ];
    makeWrapperFlags = [
      "--set-default"
      "MCP_HOST"
      cfg.mcp.host
      "--set-default"
      "MCP_PORT"
      (toString cfg.mcp.port)
    ]
    # Read at launch so the token never enters the store. Must not contain
    # single quotes: customize wraps every flag in them.
    ++ optionals (cfg.mcp.tokenFile != null) [
      "--run"
      ''if [ -r "${cfg.mcp.tokenFile}" ]; then export MCP_AUTH_TOKEN="$(< "${cfg.mcp.tokenFile}")"; fi''
    ];
  };

  # Starts FreeCAD with the MCP server already running. The script opens an
  # empty "Unnamed" document if none is open.
  freecad-mcp = pkgs.writeShellScriptBin "freecad-mcp" ''
    exec ${freecad}/bin/FreeCAD ${pkgs.freecad-ai}/mcp_server_http.py "$@"
  '';
in
{
  options.pinpox.programs.freecad = {

    enable = mkEnableOption "FreeCAD with the freecad-ai workbench (chat panel and MCP server)";

    mcp = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address the freecad-ai MCP server listens on.";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = ''
          Port of the freecad-ai MCP server. Agents connect to
          `http://<host>:<port>/mcp` (Streamable HTTP).
        '';
      };

      tokenFile = mkOption {
        type = types.nullOr types.str;
        default = "${config.xdg.configHome}/freecad-ai/mcp-token";
        defaultText = literalExpression ''"''${config.xdg.configHome}/freecad-ai/mcp-token"'';
        description = ''
          File holding the bearer token every MCP request must present. It is
          generated on activation if missing. Clients send it as
          `Authorization: Bearer <token>`.

          `null` leaves the server unauthenticated: any local process able to
          reach the port can then run arbitrary Python inside FreeCAD.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    home.packages = [
      freecad
      freecad-mcp
    ];

    xdg.desktopEntries.freecad-mcp = {
      name = "FreeCAD (MCP server)";
      genericName = "CAD application with an MCP server for coding agents";
      exec = "freecad-mcp %F";
      icon = "org.freecad.FreeCAD";
      terminal = false;
      categories = [
        "Graphics"
        "Engineering"
      ];
    };

    home.activation.freecadMcpToken = mkIf (cfg.mcp.tokenFile != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        TOKEN_FILE="${cfg.mcp.tokenFile}"
        if [ ! -s "$TOKEN_FILE" ]; then
          run mkdir -p "$(dirname "$TOKEN_FILE")"
          run ${pkgs.bash}/bin/bash -c 'umask 077; ${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 </dev/urandom | ${pkgs.coreutils}/bin/head -c 48 > "$1"' _ "$TOKEN_FILE"
        fi
      ''
    );
  };
}
