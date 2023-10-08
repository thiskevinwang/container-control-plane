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

      port "http" {
        # to     = 8080 # container port the app runs on
        # static = 80 # host port to expose
        static = 80
      }

      port "https" {
        static = 443
      }

      port "traefik" {
        static = 8080
        to     = 8080
      }


      port "db" {
        static = 5432
        to     = 5432
      }

      // port "prometheus" {
      //   static = 9090
      //   to     = 9090
      // }
    }


    service {
      name     = "traefik-http"
      provider = "nomad"
      port     = "traefik"
    }

    task "server" {
      driver = "docker"
      config {
        # network_mode = "bridge"
        image = "traefik:v3.0"
        ports = [
          "http",
          "https",
          "traefik",
          "db",
        ]
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      env {
        I_GUESS_THIS_IS_NOT_THE_WORST = var.token_for_traefik
      }

      # https://doc.traefik.io/traefik/getting-started/configuration-overview/#configuration-file
      # https://developer.hashicorp.com/nomad/docs/job-specification/template
      template {
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
  [entrypoints.metrics]
    address = ":8082"

[metrics]
  [metrics.prometheus]
    entryPoint       = "metrics" # default is traefik
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

        destination = "local/traefik.toml"
      }
    }
  }
}
