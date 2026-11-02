resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "wishapp-${var.kandidatnummer}"

  dashboard_body = jsonencode({
    widgets = [
      # ---------- Business: categories ----------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Images analyzed per room category"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 300
          metrics = [
            [{ expression = "SEARCH('{${var.metrics_namespace},category} MetricName=\"wishapp.rooms.analyzed.count\"', 'Sum', 300)", id = "e1" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Gift suggestions per category"
          view    = "timeSeries"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 300
          metrics = [
            [{ expression = "SEARCH('{${var.metrics_namespace},category} MetricName=\"wishapp.gifts.suggested.count\"', 'Sum', 300)", id = "e2" }],
          ]
        }
      },

      # ---------- Latency ----------
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Bedrock and Rekognition latency"
          view   = "timeSeries"
          region = var.region
          period = 60
          metrics = [
            [var.metrics_namespace, "wishapp.bedrock.duration.avg", "model", var.bedrock_model, { label = "Bedrock avg" }],
            [var.metrics_namespace, "wishapp.bedrock.duration.max", "model", var.bedrock_model, { label = "Bedrock max" }],
            [var.metrics_namespace, "wishapp.rekognition.duration.avg", { label = "Rekognition avg" }],
            [var.metrics_namespace, "wishapp.rekognition.duration.max", { label = "Rekognition max" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Suggestions per request"
          view   = "timeSeries"
          region = var.region
          period = 60
          metrics = [
            [var.metrics_namespace, "wishapp.suggestions.per_request.avg", { label = "avg" }],
          ]
        }
      },

      # ---------- Bedrock tokens ----------
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          title  = "Bedrock tokens per request"
          view   = "timeSeries"
          region = var.region
          period = 60
          metrics = [
            [var.metrics_namespace, "wishapp.bedrock.tokens.input.avg", "model", var.bedrock_model, { label = "input avg" }],
            [var.metrics_namespace, "wishapp.bedrock.tokens.output.avg", "model", var.bedrock_model, { label = "output avg" }],
          ]
        }
      },

      # ---------- Image size vs tokens ----------
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          title  = "Image bytes vs Bedrock input tokens (per minute)"
          view   = "timeSeries"
          region = var.region
          period = 60
          metrics = [
            [var.metrics_namespace, "wishapp.image.bytes.sum", { label = "image bytes", yAxis = "left" }],
            [var.metrics_namespace, "wishapp.bedrock.tokens.input.sum", "model", var.bedrock_model, { label = "input tokens", yAxis = "right" }],
          ]
          yAxis = {
            left  = { label = "bytes" }
            right = { label = "tokens" }
          }
        }
      },

      # ---------- Infrastructure (ECS) ----------
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU and memory"
          view   = "timeSeries"
          region = var.region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
          ]
        }
      },

      # ---------- JVM ----------
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 6
        properties = {
          title  = "JVM heap used and GC pause"
          view   = "timeSeries"
          region = var.region
          period = 60
          metrics = [
            [var.metrics_namespace, "jvm.memory.used.value", "area", "heap", "id", "G1 Old Gen", { label = "heap used (old gen)" }],
            [var.metrics_namespace, "jvm.memory.max.value", "area", "heap", "id", "G1 Old Gen", { label = "heap max (old gen)" }],
          ]
        }
      },

      # ---------- Daily total ----------
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 12
        height = 6
        properties = {
          title  = "Total Bedrock tokens per day"
          view   = "singleValue"
          region = var.region
          period = 86400
          stat   = "Sum"
          metrics = [
            [var.metrics_namespace, "wishapp.bedrock.tokens.total.count", "model", var.bedrock_model],
          ]
        }
      },
    ]
  })
}

# ---------- Alarms ----------

# Alarm when the average Bedrock converse call is over 10 seconds for 1 minute
resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "wishapp-${var.kandidatnummer}-bedrock-slow"
  alarm_description   = "Average Bedrock converse call over 10 seconds for 1 minute"
  namespace           = var.metrics_namespace
  metric_name         = "wishapp.bedrock.duration.avg"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    model = var.bedrock_model
  }
}

# Alarm when total Bedrock tokens in one day exceed the limit
resource "aws_cloudwatch_metric_alarm" "tokens_daily_high" {
  alarm_name          = "wishapp-${var.kandidatnummer}-tokens-daily-high"
  alarm_description   = "Total Bedrock tokens over ${var.daily_token_limit} in one day"
  namespace           = var.metrics_namespace
  metric_name         = "wishapp.bedrock.tokens.total.count"
  statistic           = "Sum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = var.daily_token_limit
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    model = var.bedrock_model
  }
}