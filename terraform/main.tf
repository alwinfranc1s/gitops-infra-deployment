# A minimal, cloud-free example: Terraform creates a local text file.
# Replace this resource with real infrastructure (e.g. an AWS S3 bucket)
# once you are comfortable with the workflow.
resource "local_file" "deployment_info" {
  filename        = "${path.module}/output/deployment-${var.environment}.txt"
  file_permission = "0644"
  content         = <<-EOT
    Environment: ${var.environment}
    Message:     ${var.message}
  EOT
}
