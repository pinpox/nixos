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
		}
	]
}

