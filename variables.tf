variable "additional_addons" {
  type = list(object({
    name    = string
    version = string
  }))

  description = "List of addons to be installed"

  default = [
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.14.1-eksbuild.1"
    }
  ]
}
