terraform {
  backend "s3" {
    bucket = "miservio-terraform-state"
    key    = "miservio/tf/state"
    region = "eu-west-1"
  }
}
