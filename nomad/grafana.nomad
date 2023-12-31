variable "hostname" {
  description = "($NOMAD_VAR_hostname) Hostname to detect and route to this service"
  type        = string
  default     = "grafana.svc.thekevinwang.com"
}

job "grafana" {
  datacenters = ["dc1"]

  type = "service"

  group "grafana" {
    count = 1

    network {
      mode = "host"

      port "graf" {
        # Leave `static` empty to let Traefik handle the routing
        // static = 3000
        to = 3000
      }
    }

    service {
      name     = "grafana-nomad-service"
      port     = "graf"
      provider = "nomad"


      tags = [
        "traefik.enable=true",
        // middleware
        "traefik.http.routers.grafana.middlewares=redirect-to-https",
        // http
        "traefik.http.routers.grafana.entrypoints=http",
        "traefik.http.routers.grafana.rule=Host(`${var.hostname}`)",
        // https
        "traefik.http.routers.grafana-secure.entrypoints=https",
        "traefik.http.routers.grafana-secure.rule=Host(`${var.hostname}`)",
        "traefik.http.routers.grafana-secure.tls=true",
        "traefik.http.routers.grafana-secure.tls.certresolver=myresolver",
      ]
    }

    task "grafana" {
      env {
        GF_SECURITY_DISABLE_INITIAL_ADMIN_CREATION = "true"
        GF_INSTALL_PLUGINS = "grafana-piechart-panel"
      }
      driver = "docker"

      config {
        # https://hub.docker.com/r/grafana/grafana/tags
        image = "grafana/grafana:10.1.5"
        ports = ["graf"]

        // https://github.com/grafana/grafana/blob/main/conf/sample.ini#L555
        volumes = [
          // https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/#default-paths
          // GF_PATHS_CONFIG=/etc/grafana/grafana.ini
          "local/grafana.ini:/etc/grafana/grafana.ini",
        ]
      }

      template {
        // Nomad HCL is parsed into JSON, in the context of the CLI's
        // current working directory.
        // https://github.com/hashicorp/nomad/issues/10938#issuecomment-959006084
        data = file("./nomad/sample.ini")
        destination = "local/grafana.ini"
      }
    }
  }
}
