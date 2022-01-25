/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_vpc" "endpoint_vpc" {
  ipv4_ipam_pool_id    = var.org_ipam_pool
  ipv4_netmask_length  = 22
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "endpoint_vpc"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.endpoint_vpc.id
}

resource "aws_route_table" "endpoint_vpc" {
  vpc_id = aws_vpc.endpoint_vpc.id
  tags = {
    Name = "vpce_route_table"
  }
}

resource "aws_subnet" "attachment_subnet" {
  for_each          = local.attachment_subnet
  vpc_id            = aws_vpc.endpoint_vpc.id
  cidr_block        = each.value.subnet
  availability_zone = each.value.az
  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "attachment_subnet" {
  for_each       = aws_subnet.attachment_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.endpoint_vpc.id
}

resource "aws_subnet" "endpoint_subnet" {
  for_each          = local.endpoint_subnet
  vpc_id            = aws_vpc.endpoint_vpc.id
  cidr_block        = each.value.subnet
  availability_zone = each.value.az
  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "endpoint_subnet" {
  for_each       = aws_subnet.endpoint_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.endpoint_vpc.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_endpoint" {
  subnet_ids                                      = [for s in aws_subnet.attachment_subnet : s.id]
  transit_gateway_id                              = var.tgw
  vpc_id                                          = aws_vpc.endpoint_vpc.id
  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  depends_on = [
    aws_subnet.attachment_subnet
  ]
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.endpoint_vpc.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw
}

resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_endpoint.id
  transit_gateway_route_table_id = var.tgw_route_tables["shared"]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "org" {
  for_each                       = var.tgw_route_tables
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_endpoint.id
  transit_gateway_route_table_id = each.value
}
