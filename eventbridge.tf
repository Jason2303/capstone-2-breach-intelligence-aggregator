#EventBridge Bus
resource "aws_cloudwatch_event_bus" "guardduty_event_bus" {
  name = "event-bus"

  tags = {
    Name        = "GuardDuty Event Bus"
    Environment = "Production"
  }

}

#EventBridge Rule
resource "aws_cloudwatch_event_rule" "event_bus_guardduty" {
  name           = "GuardDuty_Events"
  description    = "Get Events From GuardDuty"
  event_bus_name = aws_cloudwatch_event_bus.guardduty_event_bus.name

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

#EventBridge targets Security Admin SNS
resource "aws_cloudwatch_event_target" "event_bus" {
  rule           = aws_cloudwatch_event_rule.event_bus_guardduty.name
  target_id      = "SendToSecurityAdmin"
  arn            = aws_sns_topic.security_admin.arn
  event_bus_name = aws_cloudwatch_event_bus.guardduty_event_bus.name
}