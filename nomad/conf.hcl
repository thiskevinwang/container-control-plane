# nomad agent -config=nomad/conf.hcl -dev --bind=0.0.0.0
# https://developer.hashicorp.com/nomad/docs/configuration
client {
  enabled = true

  host_volume "traefik-config" {
    path      = "/Users/kevin/repos/traefik-test/traefik.yaml"
    read_only = false
  }

  host_volume "docker-events" {
    path      = "/var/run/docker.sock"
    read_only = false
  }
}

