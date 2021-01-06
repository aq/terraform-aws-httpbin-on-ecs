
resource "aws_lb" "this" {
  name               = "httpbin-load-balancer"
  security_groups    = [aws_security_group.httpbin-load-balancer.id]
  subnets            = aws_subnet.publics.*.id
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

resource "aws_lb_target_group" "this" {
  name     = "httpbin"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
  target_type = "ip"

  health_check {
    enabled = true
    # In httpbin, this path only purpose is to return a 200.
    path = "/status/200"
    port = "80"
    matcher = "200"
  }

  #depends_on = [aws_lb.this]
}

resource "aws_security_group" "httpbin-load-balancer" {
  name          = "httpbin-load-balancer"
  vpc_id        = aws_vpc.this.id
}

resource "aws_security_group_rule" "load-balancer-http-in" {
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 80
    to_port           = 80
    cidr_blocks       = [ var.operator-ip ]
    security_group_id = aws_security_group.httpbin-load-balancer.id
    description       = "Allows http from operator only."
}

resource "aws_security_group_rule" "tasks-http-in" {
    type              = "ingress"
    protocol          = "tcp"
    from_port         = 80
    to_port           = 80
    source_security_group_id = aws_security_group.httpbin-load-balancer.id
    security_group_id = aws_security_group.httpbin-tasks.id
    description       = "Open http from load balancer only."
}

resource "aws_security_group_rule" "httpbin-load-balancer-outbound-all" {
     type              = "egress"
     protocol          = "all"
     from_port         = 0
     to_port           = 65535
     cidr_blocks       = [var.cidr_blocks["global"]]
     security_group_id = aws_security_group.httpbin-load-balancer.id
  description       = "Open all to outbound."
}
