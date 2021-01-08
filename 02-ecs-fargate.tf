resource "aws_ecs_task_definition" "this" {
  family                   = "httpbin-service"
  container_definitions    = file("httpbin-service.json")
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.httpbin_execution_role.arn
  network_mode             = "awsvpc"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "awslogs-httpbin"
  retention_in_days = 1
}

resource "aws_iam_role" "httpbin_execution_role" {
  name = "httpbin-execution-role"

  assume_role_policy = <<-EOF
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

resource "aws_ecs_service" "this" {
  name            = "httpbin"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1

  launch_type         = "FARGATE"
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

  # Ignore the auto-scaling modifications of the setting: desired_count.
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_security_group" "httpbin-tasks" {
  name   = "httpbin-tasks"
  vpc_id = aws_vpc.this.id
}

# The task needs to pull the image from Docker Hub
resource "aws_security_group_rule" "httpbin-task-outbound-all" {
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = [var.cidr_blocks["global"]]
  security_group_id = aws_security_group.httpbin-tasks.id
  description       = "Open all to outbound."
}
