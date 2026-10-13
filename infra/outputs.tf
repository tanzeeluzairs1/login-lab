output "vpc_id" {
  description = "VPC created for the login lab"
  value       = aws_vpc.lab.id
}

output "public_subnet_id" {
  description = "Subnet for the lab EC2 instance"
  value       = aws_subnet.public.id
}

output "instance_id" {
  value = aws_instance.app.id
}

output "public_ip" {
  value = aws_instance.app.public_ip
}

output "ecr_repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.app :
    name => repository.repository_url
  }
}