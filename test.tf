/* START TEST */
resource "aws_vpc" "this" {
  count = var.create_test_instance ? 1 : 0

  cidr_block = "192.168.0.0/16"
}

resource "aws_subnet" "this" {
  count = var.create_test_instance ? 1 : 0

  vpc_id     = aws_vpc.this[count.index].id
  cidr_block = "192.168.1.0/24"

}

resource "aws_security_group" "this" {
  count = var.create_test_instance ? 1 : 0

  name   = "TEST"
  vpc_id = aws_vpc.this[count.index].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*ubuntu-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "this" {
  count = var.create_test_instance ? 2 : 0

  instance_type          = "t2.micro"
  ami                    = data.aws_ami.this.id
  subnet_id              = aws_subnet.this[0].id
  vpc_security_group_ids = [aws_security_group.this[0].id]

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = 10
    volume_type           = "standard"
    delete_on_termination = "true"
  }

  tags = {
    Name = "TEST"
  }
}

/* END TEST */
