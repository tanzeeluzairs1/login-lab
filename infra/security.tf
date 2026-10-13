resource "aws_security_group" "app" {
  name        = "login-lab-app"
  description = "Access to the login lab EC2 instance"
  vpc_id      = aws_vpc.lab.id

  tags = {
    Name = "login-lab-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH from my public IP"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "frontend" {
  security_group_id = aws_security_group.app.id
  description       = "Frontend from my public IP"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound access for the lab"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}