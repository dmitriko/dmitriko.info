variable "users" {
  description = "List of student emails"
  type        = list(any)
}

variable "admins" {
  description = "List of admin user names"
  type        = list(any)
}

variable "cluster_name" {
  default = "dmitriko-info"
}

variable "domain" {
  default = "dmitriko.info"
}

variable "subdomain" {
  default = "students"
}

variable "storage_class" {
  default = "ebs"
}

variable "tag" {
  default = "webide" // or whatever you wish
}

// get it via terraform output while you are in 00-vpceks
variable "ecr_url" {
  default     = "978051452011.dkr.ecr.us-east-1.amazonaws.com/dmitriko-info-web"
  description = "Elastic Container URL for our Docker image"
}