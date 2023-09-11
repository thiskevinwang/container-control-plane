traefik:
	nomad run ./nomad/traefik.nomad.hcl

whoami:
	nomad run ./nomad/whoami.nomad.hcl

PHONY: traefik whoami