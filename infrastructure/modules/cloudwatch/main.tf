resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/ecs/${var.app_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.environment}-${var.app_name}-logs"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.environment}-${var.app_name}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = []

  dimensions = {
    ClusterName = "${var.environment}-todo-app-cluster"
    ServiceName = "${var.environment}-todo-app-service"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "${var.environment}-${var.app_name}-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = []

  dimensions = {
    ClusterName = "${var.environment}-todo-app-cluster"
    ServiceName = "${var.environment}-todo-app-service"
  }
}
