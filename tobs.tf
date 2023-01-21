# tobs - The Observability Stack for Kubernetes
resource "helm_release" "tobs" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-community/kube-prometheus-stack"
  namespace  = "tobs"
  values = [
    file("${path.module}/kps_values.yaml")
  ]


}