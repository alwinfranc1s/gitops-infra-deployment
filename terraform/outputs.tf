output "file_path" {
  description = "Path of the file created by Terraform."
  value       = local_file.deployment_info.filename
}

output "file_checksum" {
  description = "SHA-256 checksum of the generated file content."
  value       = local_file.deployment_info.content_sha256
}
