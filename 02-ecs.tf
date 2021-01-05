resource "aws_ecs_task_definition" "this" {
  family                = "httpbin-service"
  container_definitions = file("httpbin-service.json")
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.httpbin_execution_role.arn
  network_mode = "awsvpc"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "awslogs-httpbin"
  retention_in_days = 1
}

resource "aws_iam_role" "httpbin_execution_role" {
  name = "httpbin-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "httpbin_execution_role_policy_attachement" {
  role       = aws_iam_role.httpbin_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "this" {
  name               = "httpbin"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_service" "httpbin" {
  name            = "httpbin"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = aws_subnet.privates.*.id
    security_groups  = [aws_security_group.httpbin-tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "httpbin"
    container_port   = 80
  }
}

resource "aws_lb_target_group" "this" {
  name     = "httpbin"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
  target_type = "ip"

  health_check {
    enabled = true
    path = "/status/200"
    port = "80"
    matcher = "200"
  }

  depends_on = [aws_lb.this]
}


# ... listener for 443

resource "aws_lb" "this" {
  name               = "httpbin-load-balancer"
  security_groups    = [aws_security_group.httpbin-load-balancer.id]
  subnets            = aws_subnet.privates.*.id
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type         = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  depends_on = [aws_lb_target_group.this]
}

resource "aws_security_group" "httpbin-load-balancer" {
  name          = "httpbin-load-balancer"
  description   = "Opens only httpbin load balancer ports to whitelisted ranges."
  vpc_id        = aws_vpc.this.id
}

resource "aws_security_group" "httpbin-tasks" {
  name          = "httpbin-tasks"
  description   = "Opens only httpbin tasks ports to load balancer."
  vpc_id        = aws_vpc.this.id
}

# Provide it through command line:
# terraform plan -var="operator-ip=184.168.131.241/32"
variable "operator-ip" {
  type    = string
  # default = "184.168.131.241/32"
}

resource "aws_security_group_rule" "load-balancer-http-in" {
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 80
    to_port           = 80
    cidr_blocks       = [ var.operator-ip ]
    security_group_id = aws_security_group.httpbin-load-balancer.id
    description       = "http from operator"
}

/*
resource "aws_security_group_rule" "load-balancer-https-in" {
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 443
    to_port           = 443
    cidr_blocks       = [ var.operator-ip ]
    security_group_id = aws_security_group.httpbin-load-balancer.id
    description       = "https from operator"
}
*/

resource "aws_security_group_rule" "tasks-http-in" {
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 80
    to_port           = 80
    source_security_group_id = aws_security_group.httpbin-load-balancer.id
    security_group_id = aws_security_group.httpbin-tasks.id
    description       = "open http from load balancer"
}

/*
resource "aws_security_group_rule" "tasks-https-in" {
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 443
    to_port           = 443
    source_security_group_id = aws_security_group.httpbin-load-balancer.id
    security_group_id = aws_security_group.httpbin-tasks.id
    description       = "open https from load balancer"
}
*/

resource "aws_security_group_rule" "outbound-all" {
     type              = "egress"
     protocol          = "all"
     from_port         = 0
     to_port           = 65535
     cidr_blocks       = ["0.0.0.0/0"]
     security_group_id = aws_security_group.httpbin-tasks.id
     description       = "All outbound"
}
