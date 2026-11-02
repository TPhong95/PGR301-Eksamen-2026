resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "wishapp-${var.kandidatnummer}"

  dashboard_body = jsonencode({
    widgets = [
      # CATEGORY TRACKERS
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
            [{ expression = "SEARCH('{${var.metrics_namespace},category} MetricName=\"wishapp.rooms.analyzed\"', 'Sum', 300)", id = "e1" }],
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
          view    = "bar"
          stacked = false
          region  = var.region
          stat    = "Sum"
          period  = 300
          metrics = [
            [{ expression = "SEARCH('{${var.metrics_namespace},category} MetricName=\"wishapp.gifts.suggested\"', 'Sum', 300)", id = "e2" }],
          ]
        }
      },

      # DURATION FOR CALLS
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
            [var.metrics_namespace, "wishapp.bedrock.duration", "model", var.bedrock_model, { stat = "Average", label = "Bedrock avg" }],
            [var.metrics_namespace, "wishapp.bedrock.duration", "model", var.bedrock_model, { stat = "Maximum", label = "Bedrock max" }],
            [var.metrics_namespace, "wishapp.rekognition.duration", { stat = "Average", label = "Rekognition avg" }],
          ]
        }
      },

      # SUGGESTIONS PER REQUEST
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
            [var.metrics_namespace, "wishapp.suggestions.per_request", { stat = "Average", label = "avg" }],
          ]
        }
      },

      # TOKEN USAGE
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
            [var.metrics_namespace, "wishapp.bedrock.tokens.input", "model", var.bedrock_model, { stat = "Average", label = "input avg" }],
            [var.metrics_namespace, "wishapp.bedrock.tokens.output", "model", var.bedrock_model, { stat = "Average", label = "output avg" }],
          ]
        }
      },
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
            [var.metrics_namespace, "wishapp.bedrock.tokens.total", "model", var.bedrock_model],
          ]
        }
      },

      #IMAGE TO INPUT TOKEN COMPARE
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
            [var.metrics_namespace, "wishapp.image.bytes", { stat = "Sum", label = "image bytes", yAxis = "left" }],
            [var.metrics_namespace, "wishapp.bedrock.tokens.input", "model", var.bedrock_model, { stat = "Sum", label = "input tokens", yAxis = "right" }],
          ]
          yAxis = {
            left  = { label = "bytes" }
            right = { label = "tokens" }
          }
        }
      },

      # INFRASTRUCTURE
      {
        type   = "metric"
        x      = 0
        y      = 12
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
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "ECS running tasks"
          view   = "timeSeries"
          region = var.region
          period = 60
          stat   = "Average"
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
          ]
        }
      },

      # MEMORY AND GARBAGE COLLECTION
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          title  = "JVM heap used and GC pause"
          view   = "timeSeries"
          region = var.region
          period = 60
          metrics = [
            [var.metrics_namespace, "jvm.memory.used", "area", "heap", { stat = "Average", label = "heap used" }],
            [var.metrics_namespace, "jvm.gc.pause", { stat = "Maximum", label = "GC pause max" }],
          ]
        }
      },
    ]
  })
}

#ALARMS
#ALARM FOR SLOW CALLS
resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "wishapp-${var.kandidatnummer}-bedrock-slow"
  alarm_description   = "Average Bedrock converse call over 10 seconds for 1 minutes"
  namespace           = var.metrics_namespace
  metric_name         = "wishapp.bedrock.duration"
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

#ALARM FOR HIGH DAILY TOKEN USAGE
resource "aws_cloudwatch_metric_alarm" "tokens_daily_high" {
  alarm_name          = "wishapp-${var.kandidatnummer}-tokens-daily-high"
  alarm_description   = "Total Bedrock tokens over ${var.daily_token_limit} in one day"
  namespace           = var.metrics_namespace
  metric_name         = "wishapp.bedrock.tokens.total"
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