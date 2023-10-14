variable "hostname" {
  description = "($NOMAD_VAR_hostname) Hostname to detect and route to this service"
  type        = string
  default     = "whoami.svc.thekevinwang.com"
}

job "whoami" {
  datacenters = ["dc1"]

  type = "service"

  group "demo" {
    count = 1

    network {
      mode = "host"

      port "http" {
        to = 80
      }
    }

    service {
      name     = "whoami-nomad-service"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        // middleware
        "traefik.http.routers.whoami.middlewares=redirect-to-https",
        // http
        "traefik.http.routers.whoami.entrypoints=http",
        "traefik.http.routers.whoami.rule=Host(`${var.hostname}`)",
        // https
        "traefik.http.routers.whoami-secure.entrypoints=https",
        "traefik.http.routers.whoami-secure.rule=Host(`${var.hostname}`)",
        "traefik.http.routers.whoami-secure.tls=true",
        "traefik.http.routers.whoami-secure.tls.certresolver=myresolver",
      ]
    }

    task "whoami" {
      driver = "docker"

      config {
        image = "traefik/whoami"
        ports = ["http"]
      }
    }
  }
}
