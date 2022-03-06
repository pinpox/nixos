{

	"kind": "pipeline",
		"type": "exec",
		"name": "Build all hosts",

		"platform": {
			"os": "linux",
			"arch": "amd64"
		},

		"clone": { "depth": 1 },


		"steps": [


		{
			"name": "Show flake info",
			"commands": [
				"nix --experimental-features 'nix-command flakes' flake show",
			"nix --experimental-features 'nix-command flakes' flake metadata"
			]
		},


		{
			"name": "test jhsonnet",
			"commands": [
			tost = import info.json;
				"echo " + tost,
			]
		},

		{
			"name": "Run flake checks",
			"commands": [
				"nix --experimental-features 'nix-command flakes' flake check --show-trace"
			]
		},
		{
			"name": "Build kartoffel",
			"commands": [
				"nix build -v -L '.#nixosConfigurations.kartoffel.config.system.build.toplevel'"
			]
		},
		{
			"name": "Build ahorn",
			"commands": [
				"nix build -v -L '.#nixosConfigurations.ahorn.config.system.build.toplevel'"
			]
		},
		{
			"name": "Build porree",
			"commands": [
				"nix build -v -L '.#nixosConfigurations.porree.config.system.build.toplevel'"
			]
		},
		{
			"name": "Build kfbox",
			"commands": [
				"nix build -v -L '.#nixosConfigurations.kfbox.config.system.build.toplevel'"
			]
		},
		{
			"name": "Build bob",
			"commands": [
				"nix build -v -L '.#nixosConfigurations.bob.config.system.build.toplevel'"
			]
		},
		{
			"name": "Build birne",
			"commands": [
				"nix build -v -L '.#nixosConfigurations.birne.config.system.build.toplevel'"
			]
		}

#	
#	 {
#		"name": "Notify",
#		commands: [
#		|||
#			nix run 'github:nixos/nixpkgs#curl' -- -X POST \
#			-d"<p>🛠<fe0f> <strong><font color='#0000ff'>BUILD</font> </strong><code>[$DRONE_REPO_NAME]</code>\
#			>> $DRONE_BUILD_STATUS ($DRONE_BUILD_EVENT)</br>\
#			<blockquote>$DRONE_COMMIT_MESSAGE</br>$DRONE_REPO_LINK</blockquote>" \
#			https://notify:$NOTIFY_TOKEN@notify.pablo.tools/plain
#		|||
#		],
#	 }
#	 

	],

	"environment": {
		"LOGNAME": drone,
		"NOTIFY_TOKEN": { "from_secret": notify_token }
	},

	"trigger": {
		"branch": [ main],
		"event": [ push ]
	}
}

