terraform {
  backend "s3" {
    bucket = "terraform-state-practico-iac"
    key = "terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}