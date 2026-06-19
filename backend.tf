# Define the backend Bucket
terraform {
  backend "s3" {
    bucket       = "statebucket2413"
    key          = "terraform/state/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
