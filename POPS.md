nix run '.' -- --list-all
nix run '.' -- ahorn:deploy-secrets
nix run '.' -- provision-ahorn


```nix
# flake.nix
# TODO flake input and module import
```

```nix
# configuration.nix

pops.secrets.files = {
	secret1 = {
		cmd = "pass test-password";
		path = "/tmp/secretfile";
	};
};
```
