provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami                    = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  # access with curl http://3.142.79.211:8080
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # this is because user_data only runs on the first boot
  #  so with this when we run apply it will restart the
  #  instance if user_data changes
  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

#by default AWS doesnt allow incoming or outgoing traffic on
#EC2 instances, this security group is to allow it
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    protocol  = "tcp"
    #0.0.0.0/0 allows any ip address
    cidr_blocks = ["0.0.0.0/0"]
  }
}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  # you can ovveride or set values with either
  # terraform apply -> then type
  # terraform plan -var "server_port=8080"
  # export TF_VAR_server_port=8080; terraform plan
  default = 8080
}

# with output, you can capture values from generated instances
output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

