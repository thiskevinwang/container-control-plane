# TODO NAME

![trifecta](https://github.com/thiskevinwang/traefik-test/assets/26389321/3113eef7-1d4f-40ba-8a19-6ea54b3f88d6)

## What is this?

### Overview

There are three main folders:

- [`/packer`](./packer/) - For infrequently updating an AWS AMI
- [`/terraform`](./terraform/) - For quick spin up and tear down of and EC2 instance, mostly to avoid wasted money.
- [`/nomad`](./nomad/) - For quick iteration and running of Nomad jobs, assuming a Nomad instance is ready.

## Quickstart

### Packer

```bash
packer/build.sh
```

### Terraform

```bash
pushd terraform
terraform apply
popd

# or
terraform -chdir ./terraform apply
```

This will create an EC2 instance, and a permissive security group.
Nomad will already be running.

### Nomad

#### Traefik

```bash
export NOMAD_VAR_token_for_traefik="..."
nomad run ./nomad/traefik.nomad
```

#### Prometheus

```bash
nomad run ./nomad/prometheus.nomad
```

#### Grafana

```bash
nomad run ./nomad/grafana.nomad
```

#### Postgres

```bash
nomad run -var hostname=postgres.thekevinwang.com ./nomad/postgres.nomad
# or
export NOMAD_VAR_hostname="postgres.thekevinwang.com"
nomad run ./nomad/postgres.nomad
```
