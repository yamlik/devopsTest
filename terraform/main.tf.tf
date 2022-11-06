provider "aws" {
   region = "ap-southeast-1"
   access_key = ""
   secret_key=""
   
}
resource "aws_security_group" "my-security-group" {

    name = "my-security-group"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


        ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    
        egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "ec2_test" {
    ami = "ami-07651f0c4c315a529"
    instance_type = "t2.micro"
    key_name = "yam"
    security_groups = [aws_security_group.my-security-group.name]
    associate_public_ip_address = true
    count = 1
    user_data ="${file("noNginx2.sh")}"
    root_block_device {
        volume_type = "gp2"
        volume_size = "8"
        delete_on_termination = true
    }


    tags = {
        Name = "ec2-${count.index}"
    }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "subnet" {
    vpc_id = data.aws_vpc.default.id
}

resource "aws_lb_target_group" "my-target-group" {
    name = "my-target-group"
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = data.aws_vpc.default.id

    health_check {
        interval = 10
        path = "/"
        protocol = "HTTP"
        timeout = 5
        healthy_threshold = 5
        unhealthy_threshold =2

    }
}

resource "aws_lb_target_group" "my-target-group2" {
    name = "my-target-group2"
    port = 443
    protocol = "HTTPS"
    target_type = "instance"
    vpc_id = data.aws_vpc.default.id

    health_check {
        interval = 10
        path = "/"
        protocol = "HTTPS"
        timeout = 5
        healthy_threshold = 5
        unhealthy_threshold =2

    }
}



resource "aws_lb" "my-lb" {
    name = "my-lb"
    internal = false
    ip_address_type = "ipv4"
    load_balancer_type = "application"
    security_groups = [aws_security_group.my-security-group.id]
    subnets = data.aws_subnet_ids.subnet.ids
}

resource "aws_lb_listener"  "my_alb_listener" {
    load_balancer_arn = aws_lb.my-lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        target_group_arn  = aws_lb_target_group.my-target-group.arn
        type = "forward"
    }
}

resource "aws_lb_listener"  "my_alb_listener2" {
    load_balancer_arn = aws_lb.my-lb.arn
    port = 443
    protocol = "HTTPS"
    certificate_arn = "arn:aws:acm:ap-southeast-1:220564686780:certificate/6aebccfe-2670-4d58-a8c1-dcf327bc61c0"
    default_action {
        target_group_arn  = aws_lb_target_group.my-target-group2.arn
        type = "forward"
    }
}

resource "aws_lb_target_group_attachment" "ec2_test_attach" {
    count = length(aws_instance.ec2_test)
    target_group_arn = aws_lb_target_group.my-target-group.arn
    target_id = aws_instance.ec2_test[count.index].id
}


