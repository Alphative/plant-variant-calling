variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for naming AWS resources"
  type        = string
  default     = "plant-variant-calling"
}

variable "aws_account_id" {
  description = "AWS account ID, used to build IAM/Batch ARNs"
  type        = string
}

variable "max_vcpus" {
  description = "Maximum vCPUs for the Batch compute environment"
  type        = number
  default     = 16
}

variable "instance_types" {
  description = "EC2 instance types allowed in the Spot compute environment"
  type        = list(string)
  default     = ["optimal"]
}