variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "public_key" {
  type    = string
  default = ""
}

variable "ansible_public_key" {
  type    = string
  default = ""  
}

variable "windows_private_key" {
  type    = string
  default = ""
}