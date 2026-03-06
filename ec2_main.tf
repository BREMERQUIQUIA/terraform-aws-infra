# modules/ec2/main.tf
# ─────────────────────────────────────────────────────────────────
# EC2 Module — Web server with security group and optional EIP
# Author: Bremer Quiquia Cirineo
# ─────────────────────────────────────────────────────────────────

# ── Security Group ─────────────────────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "${var.project}-${var.environment}-ec2-sg"
  description = "Security group for EC2 web server"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # SSH — restricted to your IP in production
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
    description = "Allow SSH from trusted IPs only"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-ec2-sg"
  })
}

# ── EC2 Instance ───────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  # Enable detailed monitoring for CloudWatch
  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Deployed by Terraform | ${var.environment}</h1>" > /var/www/html/index.html
  EOF

  tags = merge(var.common_tags, {
    Name        = "${var.project}-${var.environment}-web"
    Environment = var.environment
  })
}

# ── Elastic IP (optional) ──────────────────────────────────────────
resource "aws_eip" "web" {
  count    = var.assign_eip ? 1 : 0
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-eip"
  })
}
