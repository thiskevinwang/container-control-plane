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
      name     = "whoami-demo"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        # "traefik.http.routers.whoami-demo.entrypoints=web",
        # "traefik.http.routers.whoami-demo.rule=Host(`whoami.nomad.localhost`)",
        "traefik.http.routers.whoami-demo.rule=Path(`/whoami`)",
        # "traefik.http.routers.whoami-demo.service=whoami-demo",
        # "traefik.http.services.whoami-demo.loadbalancer.server.scheme=https",
        # "traefik.http.services.whoami-demo.loadbalancer.server.port=${NOMAD_PORT_http}",
        # "traefik.http.services.whoami-demo.loadbalancer.server.host=host.docker.internal",
        # "traefik.http.services.whoami-demo.loadbalancer.server.port=24663",
        # "traefik.http.middlewares.test-redirectregex.redirectregex.regex=^http://localhost/(.*)",
        # "traefik.http.middlewares.test-redirectregex.redirectregex.replacement=http://host.docker.internal/$${1}",
      ]
    }

    task "server" {
      env {
        WHOAMI_PORT_NUMBER = NOMAD_PORT_http
      }

      driver = "docker"

      config {
        network_mode = "bridge"
        image        = "traefik/whoami"
        ports        = ["http"]
      }
    }
  }
}
