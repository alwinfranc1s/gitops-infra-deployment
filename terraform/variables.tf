variable "environment" {
  description = "Name of the target environment."
  type        = string
  default     = "production"
}

variable "message" {
  description = "Message written to the generated file."
  type        = string
  default     = "Hello from GitOps! This file was created by Terraform through GitHub Actions."
}
