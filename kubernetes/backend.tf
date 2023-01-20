terraform {
  backend "s3" {
    bucket = "miservio-terraform-state"
    key    = "miservio/tf/state-kubernetes"
    region = "eu-west-1"
  }
}
