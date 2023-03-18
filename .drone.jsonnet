// Create/Update flake info file with:
// nix flake show --json > info.json

local info = import 'info.json';

// Test configuration with:
// nix-shell -p jsonnet --run 'jsonnet .drone.jsonnet'

local hosts = std.objectFields(info.nixosConfigurations);
local packages = std.objectFields(info.packages['x86_64-linux']);

// To overerride the lists use:
// local hosts = ['ahorn', 'birne', 'bob', 'kartoffel', 'kfbox', 'porree'];
// local packages = [ 'filebrowser', 'fritzbox_exporter', 'hello-custom', ];

local steps_hosts() = std.flatMap(function(host) [
  {
    name: 'Build host: %s' % host,
    commands: [
      "nix build -L '.#nixosConfigurations.%s.config.system.build.toplevel'" % host,
    ],
  },
  {
    name: 'Upload host: %s' % host,
    commands: [
		"nix run 'github:lounge-rocks/the-lounge#s3uploader' result"
    ],

	// depends_on: [ 'Build host: %s' % host ],

    environment: {
      AWS_ACCESS_KEY_ID: { from_secret: 's3_access_key' },
      AWS_SECRET_ACCESS_KEY: { from_secret: 's3_secret_key' },
    },
  }
], hosts);

local steps_packages() = std.flatMap(function(package) [
    {
      name: 'Build package: %s' % package,
      commands: [
        "nix build -L '.#%s'" % package,
      ],
    },
    {
      name: 'Upload package: %s' % package,
      commands: [
		"nix run 'github:lounge-rocks/the-lounge#s3uploader' result"
      ],

	  // depends_on: [ 'Upload package: %s' % package ],

	  environment: {
        AWS_ACCESS_KEY_ID: { from_secret: 's3_access_key' },
        AWS_SECRET_ACCESS_KEY: { from_secret: 's3_secret_key' },
	  },
    }
], packages);

{

  kind: 'pipeline',
  type: 'exec',
  name: 'Build all hosts',

  platform: {
    os: 'linux',
    arch: 'amd64',
  },

  clone: { depth: 1 },

  steps: [
	// {
      // name: 'Notify Test',
      // commands: [
        // "nix run nixpkgs#curl -- -u $ntfy-user:$ntfy-pass -H 'Title: $DRONE_REPO build: $DRONE_BUILD_STATUS' -H 'Priority: low' -H 'Tags: drone,build,nixos' -d '[$DRONE_REPO] $DRONE_COMMIT '$DRONE_COMMIT_MESSAGE': $DRONE_BUILD_STATUS' https://push.pablo.tools/drone_build ",
      // ],
	// }
    {
      name: 'Show flake info',
      commands: [
        "nix --experimental-features 'nix-command flakes' flake show",
        "nix --experimental-features 'nix-command flakes' flake metadata",
      ],
    },
    {
      name: 'Run flake checks',
      commands: [
        "nix --experimental-features 'nix-command flakes' flake check --show-trace",
      ],
    },
  ] + steps_hosts() + steps_packages() + [
  ],

  environment: {
    LOGNAME: 'drone',
    NOTIFY_TOKEN: { from_secret: 'notify_token' },
  },

  trigger: {
    branch: ['main', 'go-task'],
    event: ['push'],
  },
}
