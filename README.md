# Container Control Plane

![CleanShot 2023-10-14 at 01 08 35@2x](https://github.com/thiskevinwang/container-control-plane/assets/26389321/e8b2838f-1e6a-4c3c-a567-674694d0fd16)

## What is this?

This is a small project that consist of several infrastructure-as-code tools. [Packer][packer] for machine
images as code, [Terraform][terraform] for infrastructure-as-code, and [Nomad][nomad] for containerized jobs
as code.

I am working towards make this fully portable to anyone else with an AWS account, but for now, it makes
some assumptions, like assuming a Route53 hosted zone exists, and there are a few hard coded values that have yet to be converted to variables.

There are also some additional AWS _glue scripts_ that I have yet to find a "best" place for.

### Overview

There are three main folders:

- [`/packer`](./packer/) - For infrequently updating an AWS AMI
- [`/terraform`](./terraform/) - For quick spin up and tear down of and EC2 instance, mostly to avoid wasted money.
- [`/nomad`](./nomad/) - For quick iteration and running of Nomad jobs, assuming a Nomad instance is ready.

## Prerequisites

- [`packer`][packer] CLI
- [`terraform`][terraform] CLI
- [`nomad`][nomad] CLI
- [`aws`](https://aws.amazon.com/cli/) CLI
- AWS Credentials; used by `packer` and `terraform` and `aws`
- A `./nomad/acme.json` file, for TLS support
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

- https://grafana.com/grafana/dashboards/4475-traefik/

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
aws/route53.sh
```

[packer]: https://developer.hashicorp.com/packer
[terraform]: https://developer.hashicorp.com/terraform
[nomad]: https://developer.hashicorp.com/nomad
