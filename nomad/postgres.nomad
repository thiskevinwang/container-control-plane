variable "hostname" {
  description = "($NOMAD_VAR_hostname) Hostname to detect and route to the postgres service"
  type        = string
  default     = "postgres.thekevinwang.com"
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
        "traefik.tcp.routers.databases.rule=HostSNI(`*`)",
        // "traefik.tcp.routers.databases.entryPoints=db",
        "traefik.http.routers.databases.rule=Host(`${var.hostname}`)",
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
