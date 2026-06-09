output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "alb_url" {
  description = "HTTP URL for the Application Load Balancer"
  value       = "http://${aws_lb.app_alb.dns_name}"
}


output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.web_tg.arn
}