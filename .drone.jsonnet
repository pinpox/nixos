local get_steps() =
  local info = import 'info.json';
  [
    {
      name: 'Build host: %s' % host,
      commands: [
        "nix build -v -L '.#nixosConfigurations.%s.config.system.build.toplevel'" % host,
      ],
    }
    for host in std.objectFields(info.nixosConfigurations)
  ];

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
    {
      name: 'Build info.json',
      commands: [
        'nix flake show --json > info.json',
      ],
    },
  ] + get_steps(),

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
