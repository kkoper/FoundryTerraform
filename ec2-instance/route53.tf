# data "aws_route53_zone" "foundry" {
#   name         = "${var.SUBDOMAIN}.${var.DNS_ZONE}"
#   private_zone = false
# }


data "aws_route53_zone" "domain" {
  name         = "${var.DNS_ZONE}"
  private_zone = false
}

resource "aws_route53_record" "cert_validation_record" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.foundry_cert.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.foundry_cert.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.foundry_cert.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.domain.id
  ttl      = 60
  # provider = aws.account_route53

}

resource "aws_acm_certificate" "foundry_cert" {
  domain_name       = aws_route53_record.foundry_a_record.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }


  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.foundry_cert.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation_record.fqdn ]
}


resource "aws_route53_record" "foundry_a_record" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "${var.SUBDOMAIN}.${data.aws_route53_zone.domain.name}"
  type    = "A"

  alias {
    name                   = aws_lb.foundry_alb.dns_name
    zone_id                = aws_lb.foundry_alb.zone_id
    evaluate_target_health = false
  }
  # provider = aws.account_route53
}

resource "aws_lb" "foundry_alb" {
  name               = "foundry-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.foundry_allow_tls.id]
  subnets            = [aws_subnet.foundry_subnet.id, aws_subnet.foundry_subnetb.id]
  # vpc_id             = aws_vpc.foundry_vpc.id
  
  enable_deletion_protection = false

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = "${aws_lb.foundry_alb.arn}"  
  port              = 443
  protocol          = "HTTPS"
  certificate_arn = aws_acm_certificate.foundry_cert.arn
  
  default_action {    
    target_group_arn = "${aws_alb_target_group.alb_foundry_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "http_redirect_alb_listener" {  
  load_balancer_arn = "${aws_lb.foundry_alb.arn}"  
  port              = 80
  protocol          = "HTTP"
  
 default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_target_group" "alb_foundry_target_group" {  
  name     = "alb-foundry-target-group"  
  port     = 80
  protocol = "HTTP"  
  vpc_id  = aws_vpc.foundry_vpc.id
  # target_type = "ip"

  health_check {
    port = 30000
    path = "/"
    enabled = true
  }

  tags = {
    application = "FoundryVTT"
  }
}

resource "aws_alb_target_group_attachment" "foundry_server_physical_external" {
  # type
  target_group_arn = "${aws_alb_target_group.alb_foundry_target_group.arn}"
  target_id        = "${aws_instance.foundry_server.id}"  
  port             = 30000
}

