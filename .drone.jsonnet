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

