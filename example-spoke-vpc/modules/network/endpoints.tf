/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_security_group" "allow_vpc_endpoint" {
  # Creates security group for use with VPC endpoints.
  name        = "Local-VPC-Endpoints-Traffic-SG"
  description = "Allow local traffic vpc endpoints"
  vpc_id      = aws_vpc.spoke_vpc.id
  tags = {
    Name = "Local-VPC-Endpoints-Traffic-SG"
  }
}

resource "aws_security_group_rule" "local_cidr" {
  # Creates Security group rule to allow vpc endpoint traffic, attaches to security group created above.
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.spoke_vpc.cidr_block}"]
  security_group_id = aws_security_group.allow_vpc_endpoint.id
  description       = "Allow local 443 traffic to vpc endpoints"
}

resource "aws_vpc_endpoint" "interface" {
  # Creates VPC interface endpoints.
  for_each            = var.interface_endpoints
  service_name        = each.key
  vpc_id              = aws_vpc.spoke_vpc.id
  private_dns_enabled = false
  subnet_ids          = [for s in aws_subnet.endpoint_subnet : s.id]
  security_group_ids  = ["${aws_security_group.allow_vpc_endpoint.id}"]
  tags = {
    Name = each.key
    PHZ  = each.value
  }
  vpc_endpoint_type = "Interface"
}

resource "aws_route53_zone" "interface_phz" {
  # Private hosted zone created for each Interface endpoint. zone name taken as an input to the module.
  for_each = var.interface_endpoints
  name     = each.value
  vpc {
    vpc_id = aws_vpc.spoke_vpc.id
  }
}

resource "aws_route53_record" "dev-ns" {
  # DNS record created for each VPC interface endpoint in the corresponding private hosted zone.
  for_each = var.interface_endpoints
  zone_id  = aws_route53_zone.interface_phz[each.key].zone_id
  name     = each.value
  type     = "A"
  alias {
    name                   = aws_vpc_endpoint.interface[each.key].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.interface[each.key].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}
