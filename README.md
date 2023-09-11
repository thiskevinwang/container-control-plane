# Traefik + Nomad

Nothing to see here, just me fumbling around with Traefik and Nomad.

---

## `nomad` + `docker` tasks

```bash
nomad agent -config=nomad/conf.hcl -dev

nomad run ./nomad/traefik.nomad.hcl

nomad run ./nomad/whoami.nomad.hcl
```

Visit `nomad` dashboard at http://localhost:4646
Visit `traefik` dashboard at http://localhost:8080

TODOS:

- [ ] Make `traefik` route to `whoami` service. Currently getting `502`. Possibly a quirk/limitation of a fully local setup.

## `docker compose` (no nomad)

https://doc.traefik.io/traefik/getting-started/quick-start/

```
docker compose up -d reverse-proxy
```

Visit:

- http://localhost:8080/api/rawdata
- http://localhost:8080/dashboard#/

```
docker compose up -d whoami
```

Visit:

- http://localhost:8080/api/rawdata

```
curl -H Host:whoami.docker.localhost http://127.0.0.1
```

Run more instances of your whoami service with the following command:

```
docker-compose up -d --scale whoami=2
```

```
watch -n 2 "docker compose ps --format json  | jq"
```

```bash
nomad-pack run --var-file="./traefik.hcl" traefik
```
