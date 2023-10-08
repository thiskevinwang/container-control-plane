variable "hostname" {
  description = "Hostname to detect and route to the postgres service"
  type        = string
  default     = "prometheus.thekevinwang.com"
}

job "prometheus" {
  datacenters = ["dc1"]

  type = "service"

  group "prometheus" {
    count = 1

    network {
      mode = "host"

      port "prom" {
        static = 9090
        to = 9090
      }
    }

    service {
      name     = "prometheus"
      port     = "prom"
      provider = "nomad"


      // - "traefik.http.routers.prometheus.rule=Host(`${PROM_URL}`)"
      // - "traefik.http.routers.prometheus.service=prometheus"
      // - "traefik.http.routers.prometheus.middlewares=traefik-auth"
      // - "traefik.http.services.prometheus.loadbalancer.server.port=9090"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.metrics.rule=PathPrefix(`/metrics`)",
        // "traefik.http.routers.metrics.rule=Host(`foo.bar`)"
        // "traefik.http.routers.metrics.tls=true"
        // "traefik.http.routers.metrics.tls.certResolver=sec"
        "traefik.http.routers.metrics.service=metrics"
        // "traefik.http.routers.metrics.middlewares=myauth"
        // "traefik.http.services.metrics.loadbalancer.server.port=8082"
      ]
    }

    task "server" {
      env {
      }

      driver = "docker"

      config {
        # https://hub.docker.com/r/prom/prometheus
        image = "prom/prometheus:v2.47.1"
        ports = ["prom"]

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]
      }

      template {
        data        = <<EOT
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "traefik"
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
      - targets: ["{{ env "attr.unique.network.ip-address" }}:8080"]
EOT
        destination = "local/prometheus.yml"
      }
    }
  }
}
