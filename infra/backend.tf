terraform {
  backend "s3" {
    bucket       = "login-lab-tfstate-425034746374"
    key          = "login-lab/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}