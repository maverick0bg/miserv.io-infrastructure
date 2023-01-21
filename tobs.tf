# tobs - The Observability Stack for Kubernetes
resource "helm_release" "tobs" {
  name       = "tobs"
  repository = "https://charts.timescale.com/"
  chart      = "timescale/tobs"

  values = [
    file("${path.module}/tobs_values.yaml")
  ]


}