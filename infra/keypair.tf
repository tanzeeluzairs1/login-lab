resource "aws_key_pair" "lab" {
  key_name   = "login-lab-key"
  public_key = file("${path.module}/login-lab.pub")

  tags = {
    Name = "login-lab-key"
  }
}