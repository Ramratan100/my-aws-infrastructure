# Declare the access key variable
variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
}

# Declare the secret key variable
variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
}

# Declare the region variable
variable "aws_default_region" {
  description = "AWS Default Region"
  type        = string
  default     = "us-east-1"  # You can specify the default region or make it an optional input
}
