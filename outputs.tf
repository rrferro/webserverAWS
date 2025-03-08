output "vpc_information" {
  description = "VPC Information about Environment"
  value       = "Your ${aws_vpc.my_vpc.tags.Environment} VPC has an ID of ${aws_vpc.my_vpc.id}"
}

output "public_ip" {
  value       = aws_eip.eip.public_ip
  description = "The public IP address of the EC2 instance"
}