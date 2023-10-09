# https://developer.hashicorp.com/nomad/docs/job-specification/hcl2/variables#assigning-values-to-job-variables

# export NOMAD_VAR_token_for_traefik=...
# nomad run ./nomad/traefik.nomad.hcl
variable "token_for_traefik" {
  type = string
}

job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      mode = "host"

      // listen for the folling ports on the host
      port "http" {
        static = 80
      }
      port "https" {
        static = 443
      }
      port "db" {
        static = 5432
      }

      // static port for traefik
      port "traefik" {
        static = 8080
        to     = 8080
      }
    }


    service {
      name     = "traefik-http"
      provider = "nomad"
      port     = "traefik"
    }

    task "server" {
      driver = "docker"
      config {
        image = "traefik:v3.0"
        ports = ["http","https","db","traefik"]
        volumes = ["local/traefik.toml:/etc/traefik/traefik.toml"]
      }

      env {
        I_GUESS_THIS_IS_NOT_THE_WORST = var.token_for_traefik
      }

      # https://doc.traefik.io/traefik/getting-started/configuration-overview/#configuration-file
      # https://developer.hashicorp.com/nomad/docs/job-specification/template
      template {
        destination = "local/traefik.toml"
        data = <<EOT
[entryPoints]
  [entryPoints.http]
    address = ":80"
  [entryPoints.https]
    address = ":443"
  [entryPoints.traefik]
    address = ":8080"
  [entryPoints.db]
    address = ":5432"

[metrics]
  [metrics.prometheus]
    entryPoint       = "traefik"
    addRoutersLabels = true
    # manualrouting    = true

[api]
  # https://doc.traefik.io/traefik/operations/api/#dashboard
  dashboard = true
  insecure  = true
  debug     = true

[providers.nomad]
  refreshInterval = "5s"
  [providers.nomad.endpoint]
    address = "http://{{ env "attr.unique.network.ip-address" }}:4646"
    token   = "{{ env "I_GUESS_THIS_IS_NOT_THE_WORST" }}"

[log]
  level = "DEBUG"
EOT

      }
    }
  }
}
