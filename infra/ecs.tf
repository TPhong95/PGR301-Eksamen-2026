resource "aws_ecs_express_gateway_service" "app" {
  service_name            = "${var.kandidatnummer}-wishapp-service"
  execution_role_arn      = data.aws_iam_role.execution.arn
  infrastructure_role_arn = data.aws_iam_role.infrastructure.arn
  task_role_arn           = aws_iam_role.task_role.arn

  primary_container {
    image          = "${var.image_location}:${var.image_tag}"
    container_port = 8080
    command        = ["java", "-jar", "app.jar"]

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.images.bucket
    }

    environment {
      name  = "AWS_REGION"
      value = var.region
    }
  }
}