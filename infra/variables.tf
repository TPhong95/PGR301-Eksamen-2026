variable "region" {
  description = "region where server is"
  type        = string
}

variable "account_id" {
  description = "account id"
  type        = string
}

variable "kandidatnummer" {
  description = "Candidate number"
  type        = string
}

variable "image_tag" {
  description = "Tag of the image in ECR to deploy, e.g. 1.0.0-a1b2c3d"
  type        = string
}

variable "image_location" {
  description = "location of the image"
  type        = string
}

variable "execution_role_name" {
  description = "Name of the premade ECS task execution role"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket the app uses"
  type        = string
}