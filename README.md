# TODO NAME

![trifecta](https://github.com/thiskevinwang/traefik-test/assets/26389321/3113eef7-1d4f-40ba-8a19-6ea54b3f88d6)

## What is this?


### Overview

There are three main folders:

- [`/packer`](./packer/) - For infrequently updating an AWS AMI
- [`/terraform`](./terraform/) - For quick spin up and tear down of and EC2 instance, mostly to avoid wasted money.
- [`/nomad`](./nomad/) - For quick iteration and running of Nomad jobs, assuming a Nomad instance is ready.


## Prerequisites

- [`packer`][packer] CLI
- [`terraform`][terraform] CLI
- [`nomad`][nomad] CLI
- [`aws`][https://aws.amazon.com/cli/] CLI
- AWS Credentials; used by `packer` and `terraform` and `aws`
- A `./nomad/acme.json` file.
  > [!WARNING]
  >
  > Annecdotally, this file poses a bit of a 🐔/🥚 scenario. I'm not sure if nomad `template` references
  > to the file will break if the file doesn't exist yet, so those might have to be commented out if so.
  >
  > Traefik will bootstrap this file on container start. You can `docker exec -it $TRAEFIK_CONTAINER /bin/sh` into
  > the container and find the `acme.json` file, and copy-paste it into your local machine. A persist file
  > will make sure Traefik doesn't run into Let's Encrypt rate limits, especialyl it it needs to restart
  > often.

## Quickstart

### Packer

Build a Amazon machine image

```bash
packer/build.sh
```

### Terraform

Start an EC2 instance with nomad running.

```bash
pushd terraform
terraform apply
popd

# or
terraform -chdir ./terraform apply
```

> [!WARNING]
>
> This will create a permissive security group. I need to look into reducing access.

### Nomad

#### Traefik

```bash
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

> [!NOTE]
>
> admin user is not created on start up.
> https://github.com/grafana/grafana/issues/12638

#### Postgres

```bash
nomad run -var hostname=postgres.thekevinwang.com ./nomad/postgres.nomad
# or
export NOMAD_VAR_hostname="postgres.thekevinwang.com"
nomad run ./nomad/postgres.nomad
```

#### Whoami

### AWS Route53

```bash
aws route53 change-resource-record-sets \
 --hosted-zone-id $HOSTED_ZONE_ID \
 --change-batch file://./route53.json
```

[packer]: https://developer.hashicorp.com/packer
[terraform]: https://developer.hashicorp.com/terraform
[nomad]: https://developer.hashicorp.com/nomad
