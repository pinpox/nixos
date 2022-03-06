# Create/Update flake info file with:
# nix flake show --json > info.json

# Test configuration with:
# nix-shell -p jsonnet --run 'jsonnet .drone.jsonnet'


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
        "env",
        "ls -la ",
      ],
    },
  ], 

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
