/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_ec2_transit_gateway" "org_tgw" {
  description                     = "Org TGW with auto accept shared for prod, dev and shared environments"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "Org_TGW_${var.environment}"
  }
}

resource "aws_ram_resource_share" "main" {
  name                      = "tgw-org-share"
  allow_external_principals = false

  tags = {
    Name = "org-tgw-ram-share"
  }
}

# Requires RAM enabled to share with AWS org:
# enable in org master account with 'aws ram enable-sharing-with-aws-organization'
resource "aws_ram_principal_association" "org" {
  principal          = var.org_arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

# Requires RAM enabled to share with AWS org
resource "aws_ram_resource_association" "tgw" {
  resource_arn       = aws_ec2_transit_gateway.org_tgw.arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

resource "aws_ec2_transit_gateway_route_table" "org_tgw" {
  for_each           = toset(var.tgw_route_tables)
  transit_gateway_id = aws_ec2_transit_gateway.org_tgw.id
  tags = {
    Name = each.value
  }
}

resource "aws_ec2_transit_gateway_route" "blackhole_route" {
  for_each                       = aws_ec2_transit_gateway_route_table.org_tgw
  destination_cidr_block         = var.cidr
  blackhole                      = true
  transit_gateway_route_table_id = each.value.id
}

resource "aws_ec2_transit_gateway_route" "default_route" {
  for_each                       = aws_ec2_transit_gateway_route_table.org_tgw
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_attachment
  blackhole                      = false
  transit_gateway_route_table_id = each.value.id
}

resource "aws_ec2_transit_gateway_route" "default_route_ipv6" {
  for_each                       = aws_ec2_transit_gateway_route_table.org_tgw
  destination_cidr_block         = "::/0"
  transit_gateway_attachment_id  = var.inspection_attachment
  blackhole                      = false
  transit_gateway_route_table_id = each.value.id
}
