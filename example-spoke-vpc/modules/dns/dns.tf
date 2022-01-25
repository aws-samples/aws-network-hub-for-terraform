/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_route53_zone" "delegated_private" {
  name = "${data.aws_caller_identity.current.account_id}.${var.root_domain}"

  vpc {
    vpc_id = var.vpc_id
  }
  lifecycle {
    ignore_changes = [
      vpc,
    ]
  }
}

resource "aws_route53_record" "ns_record" {
  provider = aws.network_hub
  type     = "NS"
  zone_id  = data.aws_route53_zone.selected.id
  name     = data.aws_caller_identity.current.account_id
  ttl      = "86400"
  records  = aws_route53_zone.delegated_private.name_servers
}

resource "aws_route53_resolver_rule_association" "root_domain" {
  resolver_rule_id = data.aws_route53_resolver_rule.root_domain.id
  vpc_id           = var.vpc_id
}

resource "aws_route53_vpc_association_authorization" "delegated_private" {
  vpc_id  = data.aws_vpc.selected.id
  zone_id = aws_route53_zone.delegated_private.id
}

resource "aws_route53_zone_association" "delegated_private" {
  provider = aws.network_hub
  vpc_id   = data.aws_vpc.selected.id
  zone_id  = aws_route53_vpc_association_authorization.delegated_private.zone_id
}

resource "aws_route53_vpc_association_authorization" "endpoint_phz" {
  for_each = data.aws_route53_zone.centralised_endpoints
  provider = aws.network_hub
  vpc_id   = var.vpc_id
  zone_id  = each.value.id
}

resource "aws_route53_zone_association" "endpoint_phz" {
  for_each = aws_route53_vpc_association_authorization.endpoint_phz
  vpc_id   = each.value.vpc_id
  zone_id  = each.value.zone_id
}