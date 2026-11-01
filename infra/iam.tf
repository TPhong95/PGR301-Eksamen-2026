data "aws_iam_role" "execution" {
  name = "ecsTaskExecutionRole"
}

data "aws_iam_role" "infrastructure" {
  name = "ecsInfrastructureRoleForExpressServices"
}

data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "task-role-${var.kandidatnummer}"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    sid       = "Rekognition"
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }

  statement {
    sid       = "Bedrock"
    actions   = ["bedrock:InvokeModel"]
    resources = ["*"]
  }

  statement {
    sid       = "S3Objects"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.images.arn}/*"]
  }

  statement {
    sid       = "S3Bucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.images.arn]
  }
}

resource "aws_iam_role_policy" "task_role" {
  name   = "${var.kandidatnummer}-task-role-policy"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_permissions.json
}