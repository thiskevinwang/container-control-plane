variable "hostname" {
  description = "Hostname to detect and route to the postgres service"
  type        = string
}

job "postgres" {
  datacenters = ["dc1"]

  type = "service"

  group "db" {
    count = 1

    network {
      mode = "host"

      port "db" {
        to = 5432
      }
    }

    service {
      name     = "postgres"
      port     = "db"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.tcp.routers.route_db.rule=HostSNI(`*`)",
        "traefik.tcp.routers.route_db.entryPoints=db",
        "traefik.http.routers.whoami-demo.rule=Host(`${var.hostname}`)",
        "traefik.http.services.db.loadbalancer.server.scheme=postgres",
      ]
    }

    task "server" {
      env {
        POSTGRES_DB       = "postgres"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
      }

      driver = "docker"

      config {
        # image = "postgres:15-bookworm"
        image = "timescale/timescaledb:latest-pg13"
        ports = ["db"]
      }
    }
  }
}
