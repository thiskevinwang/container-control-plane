# TODO NAME

![trifecta](https://github.com/thiskevinwang/traefik-test/assets/26389321/3113eef7-1d4f-40ba-8a19-6ea54b3f88d6)

## What is this?

### Overview

There are three main folders:

- [`/packer`](./packer/) - For infrequently update one AWS AIM
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

### Traefik

```bash
export NOMAD_VAR_token_for_traefik="..."
nomad run ./nomad/traefik.nomad.hcl
```

### Postgres (optional)

```bash
nomad run -var hostname=foobar.thekevinwang.com ./nomad/postgres.nomad.hcl
# or
export NOMAD_VAR_hostname="foobar.thekevinwang.com"
nomad run ./nomad/postgres.nomad.hcl
```
