# /terraform/aws/modules/certificate-tls-public
# ------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.4"
}

# ------------------------------------------------------------------------------------------------
# CERTIFICATE (ACM)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate
# ------------------------------------------------------------------------------------------------
resource "aws_acm_certificate" "this" {
  domain_name               = var.cert_cn
  validation_method         = "DNS"
  subject_alternative_names = var.cert_san_list
  # Why not just concat() CN to SAN?
  # Fail in expected ways: If you add the CN implicitely, someone may not want/expect it
  # but have it show up, that they now have to find out why its "magically" showing up,
  # only to find its hard coded. Leave it as an explicit definition.
  tags = {
    Name        = var.cert_cn
    Description = var.cert_cn
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      domain_validation_options,
      subject_alternative_names,
      id
    ]
  }
}

# ------------------------------------------------------------------------------------------------
# DNS (Route53)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
# ------------------------------------------------------------------------------------------------
# Ingest data about the Zone ID provided
data "aws_route53_zone" "this" {
  zone_id = var.r53_zone_id
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = "60"
  records = [each.value.record]
}
