/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_vpc" "spoke_vpc" {
  ipv4_ipam_pool_id                = data.aws_ssm_parameter.ipam_pool.value
  ipv4_netmask_length              = 22
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${var.vpc_name}_vpc"
  }
}

resource "aws_vpc_dhcp_options" "spoke_vpc" {
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["169.254.169.123", "fd00:ec2::123"]

  tags = {
    Name = "${var.vpc_name}_dhcp_options"
  }
}

resource "aws_vpc_dhcp_options_association" "spoke_vpc" {
  vpc_id          = aws_vpc.spoke_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.spoke_vpc.id
}

resource "aws_egress_only_internet_gateway" "spoke_vpc" {
  vpc_id = aws_vpc.spoke_vpc.id
  tags = {
    Name = "${var.vpc_name}_eigw"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.spoke_vpc.id
}

resource "aws_route_table" "spoke_vpc" {
  vpc_id = aws_vpc.spoke_vpc.id
  tags = {
    Name = "${var.vpc_name}_rtb"
  }
}

resource "aws_subnet" "endpoint_subnet" {
  for_each = local.endpoint_subnet

  vpc_id                                         = aws_vpc.spoke_vpc.id
  cidr_block                                     = each.value.subnet
  ipv6_cidr_block                                = each.value.subnet_ipv6
  availability_zone                              = each.value.az
  assign_ipv6_address_on_creation                = true
  enable_dns64                                   = true
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  tags = {
    Name    = format("%s_endpoint_%s", var.vpc_name, each.value.az)
    Network = "private"
    Type    = "endpoint"
  }

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "endpoint_subnet" {
  for_each       = aws_subnet.endpoint_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.spoke_vpc.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_endpoint" {
  subnet_ids         = [for s in aws_subnet.endpoint_subnet : s.id]
  transit_gateway_id = var.tgw
  vpc_id             = aws_vpc.spoke_vpc.id
  dns_support        = "enable"
  ipv6_support       = "enable"
  # transit_gateway_default_route_table_association = false
  # transit_gateway_default_route_table_propagation = false
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.spoke_vpc.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw
}

resource "aws_route" "default_route_ipv6" {
  route_table_id              = aws_route_table.spoke_vpc.id
  destination_ipv6_cidr_block = "::/0"
  transit_gateway_id          = var.tgw
}

resource "aws_ec2_transit_gateway_route_table_association" "env" {
  provider                       = aws.network_hub
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_endpoint.id
  transit_gateway_route_table_id = var.tgw_association
}

resource "aws_ec2_transit_gateway_route_table_propagation" "org" {
  provider                       = aws.network_hub
  for_each                       = var.tgw_route_table
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_endpoint.id
  transit_gateway_route_table_id = each.value
}

resource "aws_subnet" "app_subnet" {
  for_each = local.app_subnet

  vpc_id                                         = aws_vpc.spoke_vpc.id
  cidr_block                                     = each.value.subnet
  ipv6_cidr_block                                = each.value.subnet_ipv6
  availability_zone                              = each.value.az
  assign_ipv6_address_on_creation                = true
  enable_dns64                                   = true
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  tags = {
    Name    = format("%s_app_%s", var.vpc_name, each.value.az)
    Network = "private"
    Type    = "app"
  }

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "app_subnet" {
  for_each       = aws_subnet.app_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.spoke_vpc.id
}
