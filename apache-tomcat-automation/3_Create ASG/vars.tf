

variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "aws_region" {
    default = "us-east-1"
}

#variable "filter_ami" {
#    default = "apache-tomcat-0.3"
#}

variable "subnet_tag_name" {
    default = "Name"
}

variable "subnet_tag_value" {
    default = "public_subnet"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "port_22_cidr" {
    description = "CIDR for the whole VPC"
    default = "203.13.146.0/24"
}

variable "max_instance_asg" {
    default = "5"
}

