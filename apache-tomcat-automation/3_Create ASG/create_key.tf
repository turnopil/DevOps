resource "aws_key_pair" "New" {
  key_name = "New"
  public_key = "${file("key.pub")}"
}