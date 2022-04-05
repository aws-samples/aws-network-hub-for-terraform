/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_route53_zone" "root_private" {
  name = var.root_domain

  vpc {
    vpc_id = aws_vpc.dns_vpc.id
  }
}

resource "aws_security_group" "allow_dns" {
  # Creates security group for use with dns endpoints.
  #checkov:skip=CKV2_AWS_5: Security group attached to DNS R53R Endpoints
  name        = "Network-DNS-Traffic-SG"
  description = "Allow traffic across org to dns endpoints"
  vpc_id      = aws_vpc.dns_vpc.id
  tags = {
    Name = "Network-DNS-Traffic-SG"
  }
}

resource "aws_security_group_rule" "dns_tcp" {
  # Creates Security group rule to allow dns endpoint traffic, attaches to security group created above.
  for_each          = toset(local.dns_proto)
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = each.value
  cidr_blocks       = ["${var.cidr}"]
  security_group_id = aws_security_group.allow_dns.id
  description       = "Allow 53 traffic across org to dns endpoints"
}

resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "Org-Inbound-Resolver-Endpoint"
  direction = "INBOUND"

  security_group_ids = [
    aws_security_group.allow_dns.id
  ]

  dynamic "ip_address" {
    for_each = aws_subnet.endpoint_subnet

    content {
      subnet_id = ip_address.value.id
    }
  }

  tags = {
    Environment = var.environment
  }
}
resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "Org-Inbound-Resolver-Endpoint"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.allow_dns.id
  ]

  dynamic "ip_address" {
    for_each = aws_subnet.endpoint_subnet

    content {
      subnet_id = ip_address.value.id
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_resolver_rule" "fwd" {
  domain_name          = var.root_domain
  name                 = "root-env"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  dynamic "target_ip" {
    for_each = aws_route53_resolver_endpoint.outbound.ip_address

    content {
      ip = target_ip.value.ip
    }
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_resolver_rule_association" "org_dns" {
  resolver_rule_id = aws_route53_resolver_rule.fwd.id
  vpc_id           = aws_vpc.dns_vpc.id
}

resource "aws_ram_resource_share" "main" {
  name                      = "r53r-org-share"
  allow_external_principals = false

  tags = {
    Name = "org-r53r-ram-share"
  }
}

# Requires RAM enabled to share with AWS org:
# enable in org master account with 'aws ram enable-sharing-with-aws-organization'
resource "aws_ram_principal_association" "org" {
  principal          = var.org_arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

# Requires RAM enabled to share with AWS org
resource "aws_ram_resource_association" "r53r" {
  resource_arn       = aws_route53_resolver_rule.fwd.arn
  resource_share_arn = aws_ram_resource_share.main.arn
}
