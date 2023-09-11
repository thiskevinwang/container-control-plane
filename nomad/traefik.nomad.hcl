# nomad run ./traefik.nomad.hcl
job "traefik-docker" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    # volume "docker-events" {
    #   type      = "host"
    #   read_only = true
    #   source    = "docker-events"
    # }

    network {
      mode = "host"

      port "http" {
        # to     = 8080 # container port the app runs on
        # static = 80 # host port to expose
        static = 80
      }

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
        network_mode = "bridge"
        image        = "traefik:v2.10"
        ports        = ["http", "traefik"]
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      # volume_mount {
      #   volume      = "docker-events"
      #   destination = "/var/run/docker.sock"
      # }

      # https://doc.traefik.io/traefik/getting-started/configuration-overview/#configuration-file
      template {
        data = <<EOH
# [entryPoints]
#   [entryPoints.http]
#     address = ":{{ env "NOMAD_PORT_http" }}"
#   [entryPoints.traefik]
#     address = ":{{ env "NOMAD_PORT_admin" }}"

# [entryPoints]
#   [entryPoints.web]
#     address = ":80"
#   [entryPoints.websecure]
#     address = ":443"
#   [entryPoints.admin]
#     address = ":9000"

[api]
  dashboard = true
  insecure  = true
  debug = true
[providers.nomad]
  refreshInterval = "5s"
  [providers.nomad.endpoint]
    # address = "{{ env "NOMAD_ADDR" }}"
    address = "http://host.docker.internal:4646"
    # address = "https://0ecb-2600-4041-5878-d300-590a-1bd6-fb5a-388b.ngrok-free.app"

# [http.services]
#   [http.services.whoami-demo.loadBalancer]
#     [[http.services.whoami-demo.loadBalancer.servers]]
#       url = "http://host.docker.internal/"
EOH

        destination = "local/traefik.toml"
      }
    }
  }
}
