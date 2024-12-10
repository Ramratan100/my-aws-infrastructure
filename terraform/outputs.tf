output "instance_ip" {
  value = aws_instance.mysql_instance.public_ip
}
