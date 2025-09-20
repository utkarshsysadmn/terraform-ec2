# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "Terraform-VPC" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "Terraform-IGW" }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "Terraform-Public-Subnet" }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Terraform-Public-RT" }
}

# Route Table Association
resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "Terraform-EC2-SG"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    tags = { Name = "Terra-github-Action-SSH" }
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Terraform-SG" }
}

#IAMROLE

resource "aws_iam_role" "ec2_role" {
  name = "TerraformEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


#EC2withMultipleEBS

resource "aws_instance" "my_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ec2_key.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    tags = { Name = "root-drive" }
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "gp3"
    tags = { Name = "Website-Drive" }
  }

  tags = { Name = "Terra-Github-Action" }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "TerraformEC2Profile"
  role = aws_iam_role.ec2_role.name
}
# Create IAM user
resource "aws_iam_user" "dps_user" {
  name = "DPS"
  path = "/"
}

# Attach AdministratorAccess policy to the user
resource "aws_iam_user_policy_attachment" "dps_admin_attach" {
  user       = aws_iam_user.dps_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}