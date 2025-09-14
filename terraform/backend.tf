terraform {
  backend "s3" {
    bucket         = "REPLACE_ME_tfstate"
    key            = "petclinic/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "REPLACE_ME_tflock"
    encrypt        = true
  }
}
