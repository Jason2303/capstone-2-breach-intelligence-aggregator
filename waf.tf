# WAF resource with IP and Header rate rules
resource "aws_wafv2_web_acl" "waf" {
  name        = "ratelimitbyIPandHeader"
  description = "Managed rule."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "IPRateLimitRule"
    priority = 1
    action {
        block {}
    }

    statement {
      rate_based_statement {
        limit = 300
        aggregate_key_type = "IP"
        evaluation_window_sec = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPRateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "HeaderRateLimitRule"
    priority = 2
    action {
        block {}
    }

    statement {
      rate_based_statement {
        limit = 300
        aggregate_key_type = "CUSTOM_KEYS"
        evaluation_window_sec = 300

        custom_key {
          header {
            name = "x-api-key" 
        
        
            text_transformation {
              priority = 3
              type     = "NONE" 
            }
          }  
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "HeaderRateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "WAF"
    Environment = "Production"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AllWebACLMetric"
    sampled_requests_enabled   = true
  }
}

# WAF association to API Gateway
# resource "aws_wafv2_web_acl_association" "waf" {
#   resource_arn = "arn:aws:apigateway:${data.aws_region.current.region}::/apis/${aws_apigatewayv2_api.apigw.id}/stages/${aws_apigatewayv2_stage.apigw.id}"
#   web_acl_arn  = aws_wafv2_web_acl.waf.arn
# }

# Logging configuration
resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_loggroup.arn]
  resource_arn            = aws_wafv2_web_acl.waf.arn
}



#CloudWatch Log Group for WAF
resource "aws_cloudwatch_log_group" "waf_loggroup" {
  name              = "aws-waf-logs-breach-intelligence"
  kms_key_id        = aws_kms_key.main_kms_key.arn
  retention_in_days = 365

  tags = {
    Name = "WAF"
    Environment = "Production"
  }
}

resource "aws_cloudwatch_metric_alarm" "waf_alarm" {
  alarm_name                = "waf-blocked-requests-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "BlockedRequests"
  namespace                 = "AWS/WAFV2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 300
  alarm_description         = "Threshold for WAF requests have been reached"
  insufficient_data_actions = []
  alarm_actions = [aws_sns_topic.security_admin.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.waf.name
    Region = data.aws_region.current.region
    Rule = "ALL"
  }
}