job "rabbitmq" {
  datacenters = ["us-west-2"]
  type        = "service"

  group "cluster" {
    count = 3

    update {
      max_parallel = 1
    }

    network {
      mode = "host"
      # https://stackoverflow.com/questions/63601913/nomad-and-port-mapping
      port "amqp" { static = 5672 }
      port "ui" { static = 15672 }
      port "epmd" { static = 4369 }
      port "internode" { static = 25672 }
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image    = "rabbitmq:3.9-management"
        hostname = attr.unique.hostname

        ports = ["amqp", "ui", "epmd", "internode"]

        mount {
          type     = "bind"
          source   = "local/rabbitmq.conf"
          target   = "/etc/rabbitmq/rabbitmq.conf"
          readonly = false
        }

        mount {
          type     = "bind"
          source   = "local/enabled_plugins"
          target   = "/etc/rabbitmq/enabled_plugins"
          readonly = false
        }
      }

      env {
        RABBITMQ_ERLANG_COOKIE = "ADUMMYSTRINGFORNOW"
        RABBITMQ_DEFAULT_USER  = "test"
        RABBITMQ_DEFAULT_PASS  = "test"
        # RABBITMQ_USE_LONGNAME  = true # https://github.com/rabbitmq/rabbitmq-server/discussions/4229
      }

      service {
        name = "rabbitmq-ui"
        port = "ui"
        tags = ["rabbitmq-ui", "urlprefix-/rabbitmq-ui"]

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        destination   = "local/enabled_plugins"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOF
          [rabbitmq_management,rabbitmq_peer_discovery_consul].
        EOF
      }

      template {
        destination   = "local/rabbitmq.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOF
          # https://www.rabbitmq.com/configure.html
          # https://www.rabbitmq.com/clustering.html#node-names
          # https://www.rabbitmq.com/cluster-formation.html#peer-discovery-consul
          # https://github.com/rabbitmq/rabbitmq-server/blob/master/deps/rabbit/docs/rabbitmq.conf.example

          cluster_formation.consul.include_nodes_with_warnings = true

          cluster_formation.peer_discovery_backend        = consul
          cluster_formation.consul.host                   = {{ env "attr.unique.network.ip-address" }}
          cluster_formation.consul.svc                    = rabbitmq
          cluster_formation.consul.svc_addr_auto          = true
          cluster_formation.consul.svc_addr_use_nodename  = true
          cluster_formation.consul.use_longname           = true
          cluster_formation.consul.scheme                 = http
          cluster_formation.consul.domain_suffix          = consul
          cluster_partition_handling                      = autoheal
          cluster_formation.node_cleanup.only_log_warning = true
        EOF
      }
    }
  }
}
