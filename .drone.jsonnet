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

local build_hosts() = [
  {
    name: 'Build host: %s' % host,
    commands: [
      "nix build -v -L '.#nixosConfigurations.%s.config.system.build.toplevel' --out-link result-host-%s" % host,
    ],
  }
  for host in hosts
];

local upload_hosts() = [
  {
    name: 'Upload host: %s' % host,
    commands: [
	  "nix copy --to 's3://nix-cache?scheme=https&region=eu-central-1&endpoint=s3.lounge.rocks' $(nix-store -qR result-host-%s) -L" % host,
    ],

	environment: {
      AWS_ACCESS_KEY_ID: { from_secret: 's3_access_key' },
      AWS_SECRET_ACCESS_KEY: { from_secret: 's3_secret_key' },
	},

	depends_on: [ 'Build host: %s' % host ],
  }
  for host in hosts
];

local steps_packages() = std.flatMap(function(package) [
    {
      name: 'Build package: %s' % package,
      commands: [
        "nix build -v -L '.#%s'" % package,
      ],
    },
    {
      name: 'Upload package: %s' % package,
      commands: [
	    // "nix copy --to 's3://nix-cache?scheme=https&region=eu-central-1&endpoint=s3.lounge.rocks' $(nix-store -qR result/) -L"
		"nix run 'github:lounge-rocks/the-lounge#s3uploader' result"
      ],

	  environment: {
        AWS_ACCESS_KEY_ID: { from_secret: 's3_access_key' },
        AWS_SECRET_ACCESS_KEY: { from_secret: 's3_secret_key' },
	  },
    }], packages);

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
  ] + build_hosts() + upload_hosts() + steps_packages(),

  //
  //	 {
  //		"name": "Notify",
  //		commands: [
  //		|||
  //			nix run 'github:nixos/nixpkgs#curl' -- -X POST \
  //			-d"<p>🛠<fe0f> <strong><font color='#0000ff'>BUILD</font> </strong><code>[$DRONE_REPO_NAME]</code>\
  //			>> $DRONE_BUILD_STATUS ($DRONE_BUILD_EVENT)</br>\
  //			<blockquote>$DRONE_COMMIT_MESSAGE</br>$DRONE_REPO_LINK</blockquote>" \
  //			https://notify:$NOTIFY_TOKEN@notify.pablo.tools/plain
  //		|||
  //		],
  //	 }
  //

  environment: {
    LOGNAME: 'drone',
    NOTIFY_TOKEN: { from_secret: 'notify_token' },
  },

  trigger: {
    branch: ['main'],
    event: ['push'],
  },
}
