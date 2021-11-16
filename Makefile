deploy-%: machines/% flake.nix
	nixos-rebuild switch --flake '.#$*' --target-host 'root@$*.public' --build-host localhost

localhost:
	nixos-rebuild switch --flake '.#$*' --target-host 'root@localhost'


# all: deploy-ahorn deploy-kartoffel

# Deploy single host with e.g. `make deploy-kartoffel`
# deploy-%: machines/% flake.nix
# 	nix-build ./krops.nix -v -A $* && ./result
