resource "aws_key_pair" "ec2_key" {
  key_name   = "my-ec2-key"                        # Name in AWS
  public_key = file("C:/Terraform/keys/my_key.pub")  # Path to your existing public key
}
