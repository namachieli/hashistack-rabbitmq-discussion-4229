# /terraform/aws
# ------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.4"
}

# ------------------------------------------------------------------------------------------------
# AUTO SCALING GROUPS
# ------------------------------------------------------------------------------------------------

module "runtime-server-asg" {
  source = "./modules/auto-scaling-group"

  # Module Input Variables
  asg_name                 = var.runtime_server_asg_name
  environment              = var.environment
  ami_id                   = var.runtime_server_ami_id
  instance_type            = var.runtime_server_instance_type
  vpc_id                   = local.vpc_id
  vpc_subnet_ids           = local.vpc_subnet_ids
  iam_instance_profile_arn = aws_iam_instance_profile.asg_nodes.arn
  vpc_sg_ids = [
    module.sg-default.default_id,
    #
    module.sg-runtime-nomad-consul.sg_id
  ]
  ssh_key_name = var.ssh_key_name
  extra_tags = [
    { # depended on by provisioning for packer ami
      key                 = "consul_server"
      value               = true
      propagate_at_launch = true
    }
  ]
}

module "runtime-client-asg" {
  source = "./modules/auto-scaling-group"

  # Module Input Variables
  asg_name                 = var.runtime_client_asg_name
  environment              = var.environment
  ami_id                   = var.runtime_client_ami_id
  instance_type            = var.runtime_client_instance_type
  vpc_id                   = local.vpc_id
  vpc_subnet_ids           = local.vpc_subnet_ids
  iam_instance_profile_arn = aws_iam_instance_profile.asg_nodes.arn
  vpc_sg_ids = [
    module.sg-default.default_id,
    module.region_alb.member_sg_id,
    module.nomad_ui_alb.member_sg_id,
    module.consul_ui_alb.member_sg_id,
    module.sg-runtime-nomad-consul.sg_id
  ]
  ssh_key_name = var.ssh_key_name
  extra_tags = [
    { # depended on by provisioning for packer ami
      key                 = "consul_server"
      value               = false
      propagate_at_launch = true
    }
  ]
  depends_on = [module.runtime-server-asg]
}

# ------------------------------------------------------------------------------------------------
# LOAD BALANCERS AND CERTS
# ------------------------------------------------------------------------------------------------

module "region_cert" {
  source = "./modules/certificate-tls-public"

  # Module Input Variables
  r53_zone_id   = data.aws_route53_zone.selected.zone_id
  cert_cn       = local.region_cert_name
  cert_san_list = local.region_cert_san_list
}

# This is for fabiolb services, easier to not remove... (lukebakken you can ignore this ALB)
module "region_alb" {
  source = "./modules/https-alb"

  # Module Input Variables
  vpc_id          = local.vpc_id
  alb_name        = "region-${var.environment}"
  certificate_arn = module.region_cert.certificate_arn
  alb_subnet_ids  = data.aws_subnet_ids.selected.ids
  hc_path         = "/health/"
  alb_sg_ids = [
    module.sg-default.default_id,
    module.sg-http-https.access_id
  ]
}

module "nomad_ui_alb" {
  source = "./modules/https-alb"

  # Module Input Variables
  vpc_id                = local.vpc_id
  alb_name              = "nomad-${var.environment}"
  certificate_arn       = module.region_cert.certificate_arn # Same cert as module.region_alb
  alb_subnet_ids        = data.aws_subnet_ids.selected.ids
  target_group_port     = 4646
  target_group_protocol = "HTTP"
  hc_port               = 4646
  hc_protocol           = "HTTP"
  hc_matcher            = "200-299,300-399" # "/" returns a HTTP307 to /ui/jobs.
  alb_sg_ids = [
    module.sg-default.default_id,
    module.sg-http-https.access_id,
  ]
}

module "consul_ui_alb" {
  source = "./modules/https-alb"

  # Module Input Variables
  vpc_id                = local.vpc_id
  alb_name              = "consul-${var.environment}"
  certificate_arn       = module.region_cert.certificate_arn # Same cert as module.region_alb
  alb_subnet_ids        = data.aws_subnet_ids.selected.ids
  target_group_port     = 8500
  target_group_protocol = "HTTP"
  hc_port               = 8500
  hc_protocol           = "HTTP"
  hc_matcher            = "200-299,300-399" # "/" returns a HTTP307 to /ui/.
  alb_sg_ids = [
    module.sg-default.default_id,
    module.sg-http-https.access_id,
  ]
}

# ------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ------------------------------------------------------------------------------------------------

module "sg-default" {
  source = "./modules/sg-default"

  # Module Input Variables
  environment = var.environment
  vpc_id      = local.vpc_id
}

module "sg-http-https" {
  source = "./modules/sg-http-https"

  # Module Input Variables
  environment       = var.environment
  vpc_id            = local.vpc_id
  internal_v4_pl_id = module.sg-default.internal_v4_pl_id
}

module "sg-runtime-nomad-consul" {
  source = "./modules/sg-runtime-nomad-consul"

  # Module Input Variables
  environment = var.environment
  vpc_id      = local.vpc_id
}

# ------------------------------------------------------------------------------------------------
# ASG ATTACHMENT
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment
# ------------------------------------------------------------------------------------------------

resource "aws_autoscaling_attachment" "asg_attachment_region" {
  autoscaling_group_name = module.runtime-client-asg.asg_id
  alb_target_group_arn   = module.region_alb.target_group_arn
}

resource "aws_autoscaling_attachment" "asg_attachment_nomad_ui" {
  autoscaling_group_name = module.runtime-client-asg.asg_id
  alb_target_group_arn   = module.nomad_ui_alb.target_group_arn
}

resource "aws_autoscaling_attachment" "asg_attachment_consul_ui" {
  autoscaling_group_name = module.runtime-client-asg.asg_id
  alb_target_group_arn   = module.consul_ui_alb.target_group_arn
}

# ------------------------------------------------------------------------------------------------
# IAM ROLES
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
# ------------------------------------------------------------------------------------------------

resource "aws_iam_role" "asg_nodes" {
  name               = "asg_nodes"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

resource "aws_iam_instance_profile" "asg_nodes" {
  name = "asg_nodes"
  role = aws_iam_role.asg_nodes.name
}

resource "aws_iam_role_policy_attachment" "asg_describe" {
  role       = aws_iam_role.asg_nodes.name
  policy_arn = aws_iam_policy.asg_describe.arn
}

# ------------------------------------------------------------------------------------------------
# IAM POLICIES
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
# ------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "asg_describe" {
  name        = "asg_describe"
  path        = "/"
  description = "Allow description of ASG related resources as required"
  policy      = data.aws_iam_policy_document.asg_describe.json
}

# ------------------------------------------------------------------------------------------------
# DNS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record
# ------------------------------------------------------------------------------------------------

resource "aws_route53_record" "region" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.region_dns_name
  type    = "CNAME"
  ttl     = "60"
  records = [module.region_alb.alb_dns_record]
}

resource "aws_route53_record" "nomad_ui" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.nomad_ui_dns_name
  type    = "CNAME"
  ttl     = "60"
  records = [module.nomad_ui_alb.alb_dns_record]
}

resource "aws_route53_record" "consul_ui" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.consul_ui_dns_name
  type    = "CNAME"
  ttl     = "60"
  records = [module.consul_ui_alb.alb_dns_record]
}
