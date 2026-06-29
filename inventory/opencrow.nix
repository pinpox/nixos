# All opencrow bots + their Matrix/NATS keys. Auto-merged into inventory.nix's
# `instances`; the `matrix` and `nats` instances live there (keys merged in here).
{ self, lib, ... }:
let
  # mango's llama-swap OpenAI API via its .pin name; apiKey is the env-var NAME
  # omp reads (from the shared pi-llama-swap-key env file).
  mangoPiModels.providers.mango = {
    baseUrl = "http://mango.pin:8012/v1";
    api = "openai-completions";
    apiKey = "LLAMA_SWAP_API_KEY";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
    };
    models = [
      {
        id = "gemma4:e4b";
        reasoning = true;
      }
    ];
  };

  # Shared llama-swap key (share = true; identical defs merge on mango with the
  # spaces `pi` service and the other personas).
  mkLlamaSwapKey = pkgs: {
    share = true;
    files."key" = { };
    files."env" = { };
    runtimeInputs = [ pkgs.openssl ];
    script = ''
      key="sk-$(openssl rand -hex 32)"
      printf '%s' "$key" > "$out/key"
      printf 'LLAMA_SWAP_API_KEY=%s\n' "$key" > "$out/env"
    '';
  };

  # Shared per-instance wiring (identity seed, LLM key, Matrix login, the NATS
  # CLI, container hosts) — identical for every bot regardless of persona.
  # Declared once; both the generic and persona builders consume it.
  mkBaseExtra =
    name:
    (
      {
        config,
        pkgs,
        pinpox-utils,
        ...
      }:
      {
        clan.core.vars.generators."nats-key-opencrow-${name}" =
          import (self + "/clan-service-modules/nats/nkey.nix")
            {
              inherit pkgs;
              owner = "root";
            };
        clan.core.vars.generators."pi-llama-swap-key" = mkLlamaSwapKey pkgs;
        # Shared account password: created on the homeserver by the matrix
        # reconciler, used here to log in (OPENCROW_MATRIX_PASSWORD_FILE).
        clan.core.vars.generators."matrix-user-opencrow_${name}" = pinpox-utils.mkMatrixPassword;
        services.opencrow.instances.${name} = {
          extraPackages = [ pkgs.natscli ];
          # NKEY seed → systemd credential, read at %d/nats-seed (see NATS_NKEY).
          credentialFiles.nats-seed =
            config.clan.core.vars.generators."nats-key-opencrow-${name}".files.seed.path;
          environmentFiles = [
            config.clan.core.vars.generators."pi-llama-swap-key".files.env.path
          ];
        };
        containers."opencrow-${name}".config.networking.extraHosts = config.networking.extraHosts;
      }
    );

  # ── Personas ────────────────────────────────────────────────────────────
  # Every bot is a persona: one profile compiles into three artefacts that
  # cannot drift — the broker ACL (`authorizations.<name>`), the system prompt
  # (OPENCROW_SOUL_FILE) and a generated capability-index skill, so the agent is
  # told exactly, and only, what it may do. A generic chat bot is simply the
  # empty profile `{ }`: nats skill, default soul, private opencrow.<name>.>
  # namespace. Profile fields are declared and type-checked by `personaType`
  # below, so a typo or wrong type fails at eval instead of being silently dropped.

  # Least-privilege, read-only JetStream surface for one stream: discover +
  # inspect + create/use/drop a consumer ON THAT STREAM ONLY. No stream
  # create/update/delete/purge and no access to other streams; combined with
  # never granting publish on the stream's subjects, the persona cannot alter
  # retained history — it can only replay it.
  jsReadGrant = stream: [
    "$JS.API.INFO"
    "$JS.API.STREAM.NAMES"
    "$JS.API.STREAM.INFO.${stream}"
    "$JS.API.CONSUMER.CREATE.${stream}"
    "$JS.API.CONSUMER.CREATE.${stream}.>"
    "$JS.API.CONSUMER.INFO.${stream}.>"
    "$JS.API.CONSUMER.MSG.NEXT.${stream}.>"
    "$JS.API.CONSUMER.DELETE.${stream}.>"
  ];

  # Render the capability-index SKILL.md from a profile. Only non-empty sections
  # appear, so the agent reads exactly the affordances it holds.
  renderCapabilitySkill =
    name: p:
    let
      section = items: lib.concatStringsSep "\n" (map (s: "- `${s}`") items);
    in
    ''
      ---
      name: ${name}-capabilities
      description: How you, the clan ${name}, use the NATS bus
      ---

      You are the clan **${name}**. The NATS bus is your main instrument: the
      clan's events flow through it, and your authority is exactly what the
      broker grants you — nothing more. Confirm your grant any time with:

      ```bash
      nats req '$SYS.REQ.USER.INFO' "" --raw
      ```

      Use compact single-line JSON payloads. Anything outside the lists below is
      denied by the broker — if you need more reach, say so rather than retrying.
    ''
    + lib.optionalString (p.events or [ ] != [ ]) ''

      ## Watch live events

      Core NATS keeps no history, so bound every read with `--count`/`--wait`:

      ```bash
      nats sub --count 20 --wait 30s "<subject>"
      ```

      Subjects you may subscribe to:
      ${section p.events}
    ''
    + lib.optionalString (p.streams or [ ] != [ ]) ''

      ## Replay history (JetStream)

      To investigate something that already happened, read it back from a
      retained stream:

      ```bash
      nats stream view <stream>                       # browse retained messages
      nats consumer next <stream> <name> --count 50   # pull a batch
      ```

      Streams you may read (read-only):
      ${section p.streams}
    ''
    + lib.optionalString (p.data or [ ] != [ ]) ''

      ## Ask data services

      Request/reply to a clan data service and wait for the answer:

      ```bash
      nats request <subject> '{"q":"..."}' --timeout=5s
      ```

      Services you may query:
      ${section (map (d: "data.${d}.req") p.data)}
    ''
    + lib.optionalString (p.emit or [ ] != [ ]) ''

      ## Raise signals

      ```bash
      nats pub <subject> '{"...":"..."}'
      ```

      You may publish to:
      ${section p.emit}
    ''
    + lib.optionalString (p.actions or [ ] != [ ]) ''

      ## Trigger actions

      These take effect on the cluster — use deliberately and report what you did:

      ```bash
      nats request action.<verb>.req '{"...":"..."}' --timeout=10s
      ```

      Actions you may invoke:
      ${section (map (a: "action.${a}.req") p.actions)}
    '';

  # Compile a profile into its three artefacts. Pure (strings only); the soul/
  # skill strings are wrapped into derivations in mkInstance where pkgs is
  # available. `soul`/`capabilitySkill` are null when the profile omits them, so
  # the empty profile yields a plain generic bot. `permissions` feeds the nats
  # authorizer directly.
  compilePersona =
    name: p:
    let
      hasCaps =
        p.events or [ ] != [ ]
        || p.streams or [ ] != [ ]
        || p.data or [ ] != [ ]
        || p.emit or [ ] != [ ]
        || p.actions or [ ] != [ ];
    in
    {
      permissions = {
        publish.allow = lib.unique (
          [ "opencrow.${name}.>" ]
          ++ map (d: "data.${d}.req") (p.data or [ ])
          ++ map (a: "action.${a}.req") (p.actions or [ ])
          ++ (p.emit or [ ])
          ++ lib.concatMap jsReadGrant (p.streams or [ ])
        );
        subscribe.allow = [ "opencrow.${name}.>" ] ++ (p.events or [ ]);
      };
      soul = p.soul or null;
      capabilitySkill = if hasCaps then renderCapabilitySkill name p else null;
    };

  # The single instance builder. `c` is the compiled profile. A bot on mango:
  # Matrix @opencrow_<name>:pinpox.com, NATS (own nkey seed) and mango's
  # llama-swap LLM. The soul file and capability skill are wired only when the
  # profile provides them; otherwise the bot keeps the default soul and just the
  # nats skill. The generated capability skill is appended via OPENCROW_PI_SKILLS
  # so the upstream `web` skill in OPENCROW_PI_SKILLS_DIR is left untouched.
  mkInstance = name: c: {
    module.input = "self";
    module.name = "@pinpox/opencrow";
    roles.default.machines.mango.settings = {
      environment = {
        OPENCROW_MATRIX_HOMESERVER = "https://matrix.pinpox.com";
        OPENCROW_MATRIX_USER_ID = "@opencrow_${name}:pinpox.com";
        OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
        OPENCROW_PI_PROVIDER = "mango";
        OPENCROW_PI_MODEL = "gemma4:e4b";
        NATS_URL = "nats://kfbox.pin:4222";
        NATS_NKEY = "%d/nats-seed";
      }
      # No capability skill ⇒ the nats skill is the whole list (set here). With
      # one, the list is assembled in the extra module below (nats + skill).
      // lib.optionalAttrs (c.capabilitySkill == null) {
        OPENCROW_PI_SKILLS = "${self}/skills/nats";
      };
      piModels = mangoPiModels;
      matrixPasswordGenerator = "matrix-user-opencrow_${name}";
    };
    roles.default.extraModules =
      [ (mkBaseExtra name) ]
      ++ lib.optional (c.soul != null || c.capabilitySkill != null) (
        { pkgs, ... }:
        lib.mkMerge [
          (lib.optionalAttrs (c.soul != null) {
            services.opencrow.instances.${name}.environment.OPENCROW_SOUL_FILE =
              "${pkgs.writeText "soul-${name}.md" c.soul}";
          })
          (lib.optionalAttrs (c.capabilitySkill != null) (
            let
              capPkg = pkgs.writeTextDir "${name}-capabilities/SKILL.md" c.capabilitySkill;
            in
            {
              services.opencrow.instances.${name}.environment.OPENCROW_PI_SKILLS =
                lib.concatStringsSep "," [
                  "${self}/skills/nats"
                  "${capPkg}/${name}-capabilities"
                ];
            }
          ))
        ]
      );
  };

  # Every mango bot, keyed by short name → profile (`{ }` = generic chat bot).
  bots = {
    one = { };
    two = { };
    guard = {
      soul = ''
        # You are the Guard

        You watch over the clan's machines. Failed logins, intrusions,
        unexpected reboots, configuration drift — you notice them and raise the
        alarm. You are read-only on the infrastructure: you observe and report,
        you never change things. Be precise, cite the events you saw, and don't
        cry wolf. Be resourceful: replay the history and correlate before you
        conclude.

        Your eyes and memory are the NATS bus — see your capabilities skill for
        exactly what you may watch, replay and signal.
      '';
      events = [
        "host.*.ssh.>"
        "host.*.status"
      ];
      streams = [ "telemetry" ];
      data = [ "host" ];
      emit = [ "alerts.guard" ];
      # no `actions` ⇒ zero action.* grants: the guard cannot change the cluster.
    };
  };

  # Persona profile schema. Routing each profile through this rejects unknown
  # keys (typos) and wrong types at eval, and documents every field in one place.
  personaType = lib.types.submodule {
    options = {
      soul = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        description = "System prompt (OPENCROW_SOUL_FILE); null ⇒ upstream default SOUL.md.";
      };
      events = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subjects the persona may SUBSCRIBE to (live tail). → subscribe.allow.";
      };
      streams = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "JetStream streams the persona may READ back, read-only. → scoped $JS.API.* grant.";
      };
      data = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Domains the persona may query → publish data.<d>.req (request/reply).";
      };
      emit = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Subjects the persona may publish fire-and-forget (e.g. alerts). → publish.allow.";
      };
      actions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Side-effecting verbs → publish action.<a>.req (privileged request/reply).";
      };
    };
  };

  # Type-check + default-fill a profile against personaType. Unknown keys and
  # wrong types fail at eval; the context names the offending persona.
  checkProfile =
    name: profile:
    builtins.addErrorContext "while type-checking persona profile '${name}'" (
      (lib.evalModules {
        modules = [
          { options.persona = lib.mkOption { type = personaType; }; }
          { persona = profile; }
        ];
      }).config.persona
    );

  # name → { permissions; soul; capabilitySkill } — one compile per bot.
  compiled = lib.mapAttrs (name: profile: compilePersona name (checkProfile name profile)) bots;

  # opencrow-<name> instances + their broker authorizations, keyed alike.
  botInstances = lib.mapAttrs' (
    name: c: lib.nameValuePair "opencrow-${name}" (mkInstance name c)
  ) compiled;

  botAuths = lib.mapAttrs' (
    name: c: lib.nameValuePair "opencrow-${name}" { inherit (c) permissions; }
  ) compiled;
in
botInstances
// {
  # Original bot on matrix.org/porree (kept verbatim; name = container/state dir).
  opencrow-claude = {
    module.input = "self";
    module.name = "@pinpox/opencrow";
    roles.default.machines.porree.settings.environment = {
      NEXTCLOUD_URL = "https://files.pablo.tools";
      NEXTCLOUD_USER = "pinpox";
      NEXTCLOUD_CALENDAR = "personal";
      WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
      WORK_NEXTCLOUD_USER = "pinpox";
      WORK_NEXTCLOUD_CALENDAR = "personal";
      OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
      OPENCROW_MATRIX_USER_ID = "@p.i.m.p.:matrix.org";
      OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
      OPENCROW_HEARTBEAT_INTERVAL = "30m";
    };
    roles.default.extraModules = [
      (
        { config, pinpox-utils, ... }:
        {
          clan.core.vars.generators."opencrow-nextcloud" = pinpox-utils.mkEnvGenerator [
            "NEXTCLOUD_PASSWORD"
          ];
          clan.core.vars.generators."opencrow-nextcloud-work" = pinpox-utils.mkEnvGenerator [
            "WORK_NEXTCLOUD_PASSWORD"
          ];
          clan.core.vars.generators."opencrow-eversports" = pinpox-utils.mkEnvGenerator [
            "EVERSPORTS_EMAIL"
            "EVERSPORTS_PASSWORD"
          ];
          # Integration env files, appended to the bot's token file (lists merge).
          services.opencrow.instances.claude.environmentFiles = [
            config.clan.core.vars.generators."opencrow-nextcloud".files.envfile.path
            config.clan.core.vars.generators."opencrow-nextcloud-work".files.envfile.path
            config.clan.core.vars.generators."opencrow-eversports".files.envfile.path
          ];
        }
      )
    ];
  };

  # Matrix accounts for the mango bots, deep-merged into the `matrix` instance
  # (opencrow-claude lives on matrix.org and is excluded).
  matrix.roles.server.machines.clementine.settings.users = map (
    n: builtins.replaceStrings [ "opencrow-" ] [ "opencrow_" ] n
  ) (builtins.attrNames botInstances);

  # NATS authorizations, deep-merged into the `nats` instance: each bot's
  # compiled, scoped grant (the empty profile = its private namespace).
  nats.roles.server.settings.authorizations = botAuths;
}
