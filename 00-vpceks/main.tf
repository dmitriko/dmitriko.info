terraform {
  backend "s3" {
    bucket = "dmitriko-info-tf-state"
    key    = "00-vpceks.tfstate"
    region = "us-east-1" // we could not use var here 
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "zones" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}