output "url" {
  description = "Public endpoint of the ECS Express service"
  value       = aws_ecs_express_gateway_service.app.ingress_paths[0].endpoint
}