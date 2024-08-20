
variable "karpenter_version" {
  default = "1.0.0"
}

variable "cluster_name" {
  default = "dmitriko-info" // it should be the value of variable tag from 00-vpceks
}

variable "karpenter_master_node_label_name" {
  default = "role"
}

variable "karpenter_master_node_label_value" {
  default = "karpenter"
}

variable "storage_class" {
  default = "ebs"
}