# all: deploy-ahorn deploy-kartoffel

# Deploy to localhost
localhost:
	nixos-rebuild switch --flake '.#' --target-host 'root@localhost'

# Deploy single host with e.g. `make deploy-kartoffel` (direct)
deploy-%: machines/% flake.nix
	nixos-rebuild switch --flake '.#$*' --target-host 'root@$*.wireguard' --build-host localhost

# Deploy single host with e.g. `make krops-kartoffel` (with secrets)
krops-%: machines/% flake.nix
	nix-build ./krops.nix -v -A $* && ./result

# Update flake inputs
update:
	nix flake update
	git commit -m'Update flake.lock' flake.lock



