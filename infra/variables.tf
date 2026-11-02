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
  default     = "latest"
}

variable "image_location" {
  description = "location of the image"
  type        = string
  default     = "244530008913.dkr.ecr.eu-west-1.amazonaws.com/crud-dud-exam-2026"
}

variable "execution_role_name" {
  description = "Name of the premade ECS task execution role"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket the app uses"
  type        = string
}

variable "metrics_namespace" {
  description = "Namespace of MetricsConfig"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of ecs service"
  type        = string
}

variable "bedrock_model" {
  description = "Bedrock model ID, must match app.bedrock.model-id"
  type        = string
}

variable "daily_token_limit" {
  description = "Total Bedrock tokens per day that triggers the alarm"
  type        = number
  default     = 100000
}