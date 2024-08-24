data "aws_route53_zone" "parent" {
  name = var.domain
}

resource "aws_route53_zone" "this" {
  name = "${var.subdomain}.${var.domain}"
}

resource "aws_route53_record" "parent" {
  zone_id = data.aws_route53_zone.parent.zone_id
  name    = var.tag
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.this.name_servers
}
resource "aws_acm_certificate" "this" {
  domain_name = aws_route53_zone.this.name
  //additional domains wild
  subject_alternative_names = ["*.${aws_route53_zone.this.name}"]

  validation_method = "DNS"
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

