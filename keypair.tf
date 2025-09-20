resource "aws_key_pair" "ec2_key" {
  key_name   = "my-ec2-key"                        # Name in AWS
  public_key = file("${path.module}/keys/my_key.pub")  # Relative path to your public key
}
