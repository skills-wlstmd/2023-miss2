resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name = "jnc-key"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "jnc-key.pem"
  content = tls_private_key.pk.private_key_pem
}

resource "aws_security_group" "bastion_sg" {
  name = "jnc-bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

    ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }

  tags = {
    Name = "jnc-bastion-sg"
  }
}

resource "aws_security_group" "gateway_app_sg" {
  name = "gateway-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id, aws_security_group.alb_sg.id]
    from_port = "22"
    to_port = "22"
  }

    ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.bastion_sg.id, aws_security_group.alb_sg.id]
    from_port = "8080"
    to_port = "8080"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }

  tags = {
    Name = "gateway-app-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name = "jnc-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }

  tags = {
    Name = "jnc-alb-sg"
  }
}

resource "aws_instance" "bastion_ec2" {
  ami = "ami-0f7712b35774b7da2"
  instance_type = "t3.small"
  subnet_id = aws_subnet.public_a.id
  iam_instance_profile = aws_iam_instance_profile.jnc-bastion-profile.name
  key_name = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]

  tags = {
    Name = "jnc-bastion"
  }

  user_data = file("./bastion-userdata.sh")
}

resource "aws_instance" "gateway_app" {
  ami = "ami-0f7712b35774b7da2"
  instance_type = "c5.large"
  count = 2
  subnet_id = aws_subnet.private_a.id
  iam_instance_profile = aws_iam_instance_profile.gateway-app-profile.name
  key_name = aws_key_pair.key_pair.key_name
  associate_public_ip_address = false
  vpc_security_group_ids = [
    aws_security_group.gateway_app_sg.id
  ]

  tags = {
    Name = "gateway-app"
    "jnc:deploy:group" = "gateway"
  }

  user_data = file("./gateway-app-userdata.sh")
}