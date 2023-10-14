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
      name     = "traefik-nomad-service"
      provider = "nomad"
      port     = "traefik"

      // How to write a rule to route to the dashboard itself
      // https://community.traefik.io/t/how-to-redirect-to-the-dashboard-from-a-url/4082/6
      tags = [
        "traefik.enable=true",

        # route traefik.thekevinwang.com
        # https://stackoverflow.com/a/74668235/9823455
        # Redirect http://traefik.thekevinwang.com to https
        "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https",
        "traefik.http.middlewares.redirect-to-https.redirectscheme.permanent=true",
        // dashboard middleware
        "traefik.http.routers.dashboard.middlewares=redirect-to-https",
        // dashboard http
        "traefik.http.routers.dashboard.entrypoints=http",
        "traefik.http.routers.dashboard.rule=Host(`traefik.thekevinwang.com`)",
        // daashboard https
        "traefik.http.routers.dashboard-secure.entrypoints=https",
        "traefik.http.routers.dashboard-secure.rule=Host(`traefik.thekevinwang.com`)",
        "traefik.http.routers.dashboard-secure.tls=true", 
        "traefik.http.routers.dashboard-secure.tls.certresolver=myresolver",
        "traefik.http.routers.dashboard-secure.service=api@internal",

        # route /metrics
        // middleware
        "traefik.http.routers.metrics.middlewares=redirect-to-https",
        // http
        "traefik.http.routers.metrics.entrypoints=http",
        "traefik.http.routers.metrics.rule=Host(`traefik.thekevinwang.com`) && PathPrefix(`/metrics`)", // Warning: must use one .rule tag.
        // https
        "traefik.http.routers.metrics-secure.entrypoints=https", 
        "traefik.http.routers.metrics-secure.rule=Host(`traefik.thekevinwang.com`) && PathPrefix(`/metrics`)", // Warning: must use one .rule tag.
        "traefik.http.routers.metrics-secure.tls=true",
        "traefik.http.routers.metrics-secure.tls.certresolver=myresolver",
        "traefik.http.routers.metrics-secure.service=prometheus@internal",

        # route nomad.thekevinwang.com
        // nomad middleware
        "traefik.http.routers.nomad.middlewares=redirect-to-https",
        // nomad http
        "traefik.http.routers.nomad.entrypoints=http",
        "traefik.http.routers.nomad.rule=Host(`nomad.thekevinwang.com`)",
        // nomad https
        "traefik.http.routers.nomad-secure.entrypoints=https",
        "traefik.http.routers.nomad-secure.rule=Host(`nomad.thekevinwang.com`)",
        "traefik.http.routers.nomad-secure.tls=true", 
        "traefik.http.routers.nomad-secure.tls.certresolver=myresolver",
        "traefik.http.services.nomad-secure.loadbalancer.server.port=4646",
      ]
    }

    # task name is used as a prefix on the host machine's
    # docker container name. e.g. "server-6a911a47-efef-ef89-2c62-72c6407f3f69"
    task "server" {
      driver = "docker"
      config {
        image = "traefik:v3.0"
        ports = [
          "http",
          "https",
          "db",
          "traefik",
        ]
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "local/acme.json:/acme.json",
        ]
      }

      env {
        I_GUESS_THIS_IS_NOT_THE_WORST = var.token_for_traefik
      }

      template {
        data = file("./nomad/acme.json")
        destination = "local/acme.json"
        perms = "600"
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

[certificatesResolvers.myresolver.acme]
  email = "kwangsan@gmail.com"
  storage = "acme.json"
  [certificatesResolvers.myresolver.acme.httpChallenge]
    # used during the challenge
    entryPoint = "web"
  [certificatesResolvers.myresolver.acme.tlsChallenge]

[metrics]
  [metrics.prometheus]
    entryPoint       = "traefik"
    addRoutersLabels = true
    manualrouting    = true

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
