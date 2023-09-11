job "sample" {
  datacenters = ["dc1"]

  group "traefik" {
    network {
      mode = "bridge"

      port "http" {
        static = 9000
        to     = 9000
      }
    }

    service {
      name = "traefik"
      port = 9000

      connect {
        native = true
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "shoenig/traefik:connect"
        args = [
          "--entrypoints.http=true",
          "--entrypoints.http.address=:9000",

          "--providers.consulcatalog.connectaware=true",
          "--providers.consulcatalog.connectbydefault=false",
          "--providers.consulcatalog.exposedbydefault=false",

          # Nomad will automatically set environment variables for these
          # for Connect native tasks.
          # "--providers.consulcatalog.endpoint.address=<socket|address>"
          # "--providers.consulcatalog.endpoint.tls.ca=<path>"
          # "--providers.consulcatalog.endpoint.tls.cert=<path>"
          # "--providers.consulcatalog.endpoint.tls.key=<path>"
          # "--providers.consulcatalog.endpoint.token=<token>"
        ]
      }
    }
  }

  # An example destination service using a connect sidecar 
  group "kitchen-clock" {
    network {
      mode = "bridge"
    }

    service {
      name = "clock"
      port = "3333"
      tags = [
        "traefik.enable=true",
        "traefik.connect=true",
      ]
      connect {
        sidecar_service {}
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "shoenig/simple-http:v1"
        args  = ["server"]
      }
      env {
        BIND = "0.0.0.0"
        PORT = 3333
      }
    }
  }


  # An example connect native destination service
  group "uuids" {
    network {
      mode = "bridge"
      port "uid" {
        to = 8999
      }
    }

    service {
      name = "uuid-api"
      port = "uid"
      tags = [
        "traefik.enable=true",
        "traefik.connect=true",
      ]
      connect {
        native = true
      }
    }

    task "uuid-api" {
      driver = "docker"
      config {
        image = "hashicorpnomad/uuid-api:v5"
      }

      env {
        BIND = "0.0.0.0"
        PORT = 8999

        # If using Consul TLS, this is also required
        # until #10805 is fixed
        CONSUL_TLS_SERVER_NAME = "localhost"
      }
    }
  }
}
