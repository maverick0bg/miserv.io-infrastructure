# tobs - The Observability Stack for Kubernetes
#https://github.com/timescale/tobs/releases/download/20.7.0/tobs-20.7.0.tgz
resource "helm_release" "tobs" {
  name      = "tobs"
  chart     = "https://github.com/timescale/tobs/releases/download/20.7.0/tobs-20.7.0.tgz"
  namespace = "tobs"
  values = [
    file("${path.module}/tobs_values.yaml")
  ]

  depends_on = [

    aws_eks_addon.addons,
    kubernetes_service_account.ebs_csi_controller_sa

  ]
}