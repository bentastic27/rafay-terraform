resource "aws_lb" "kube_api_nlb" {
  name               = "${var.resource_name_prefix}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.subnet.id]
}

resource "aws_lb_target_group" "kube_api_nlb_tg" {
  name     = "${var.resource_name_prefix}-lb-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    protocol = "HTTPS"
    path = "/healthz"
  }
}

resource "aws_lb_target_group_attachment" "kube_api_nlb_tga" {
  count = var.master_count
  target_group_arn = aws_lb_target_group.kube_api_nlb_tg.arn
  target_id        = aws_instance.kubeadm_master[count.index].id
  port             = 6443
}

resource "aws_lb_listener" "kube_api_nlb_listener" {
  load_balancer_arn = aws_lb.kube_api_nlb.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.kube_api_nlb_tg.arn
  }
}