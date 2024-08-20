certmanager:
  install: false

nginx-ingress:
  enabled: false

global:
  hosts:
    domain: ${domain}
  edition: ce
  ingress:
    enabled: true
    class: alb
    annotations:
      kubernetes.io/ingress.class: "alb"
      alb.ingress.kubernetes.io/scheme: "internet-facing"
      alb.ingress.kubernetes.io/target-type: "ip"
      alb.ingress.kubernetes.io/certificate-arn: "${certificate_arn}"
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/group.name: "${group_name}"
      alb.ingress.kubernetes.io/ssl-redirect: "443"
      alb.ingress.kubernetes.io/healthcheck-path: "/login"

gitaly:
  persistence:
    storageClass: ${storage_class}

postgresql:
  persistence:
    storageClass: ${storage_class}

gitlab-runner:
  runners:
    cache:
      cacheShared: true
      storageClass: ${storage_class}

redis:
  master:
    persistence:
      storageClass: ${storage_class}
  slave:
    persistence:
      storageClass: ${storage_class}

minio:
  persistence:
    storageClass: ${storage_class}
