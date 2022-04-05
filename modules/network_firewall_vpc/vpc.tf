/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_vpc" "inspection_vpc" {
  ipv4_ipam_pool_id                = var.org_ipam_pool
  ipv4_netmask_length              = 22
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "inspection_vpc"
  }
}

resource "aws_vpc_dhcp_options" "inspection_vpc" {
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["169.254.169.123", "fd00:ec2::123"]

  tags = {
    Name = "inspection_dhcp_options"
  }
}

resource "aws_vpc_dhcp_options_association" "inspection_vpc" {
  vpc_id          = aws_vpc.inspection_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.inspection_vpc.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.inspection_vpc.id
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = var.iam_role_arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.inspection_vpc.id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "inspection_vpc"
  kms_key_id        = var.kms_key_id
  retention_in_days = 7
}

# Attachment subnets

resource "aws_route_table" "attachment" {
  for_each = local.attachment_subnet
  vpc_id   = aws_vpc.inspection_vpc.id
  tags = {
    Name    = format("inspection_attachment_%s", each.value.az)
    Network = "private"
    Type    = "attachment"
  }
}

resource "aws_route" "default_route" {
  for_each               = local.attachment_subnet
  route_table_id         = local.attachment_rt_lookup[each.key]
  destination_cidr_block = "0.0.0.0/0"
  # https://github.com/hashicorp/terraform-provider-aws/issues/16759
  vpc_endpoint_id = local.eni_lookup[each.key]
}

resource "aws_route" "default_route_ipv6" {
  for_each                    = local.attachment_subnet
  route_table_id              = local.attachment_rt_lookup[each.key]
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw.id
}

resource "aws_subnet" "attachment_subnet" {
  for_each = local.attachment_subnet

  vpc_id                                         = aws_vpc.inspection_vpc.id
  cidr_block                                     = each.value.subnet
  ipv6_cidr_block                                = each.value.subnet_ipv6
  availability_zone                              = each.value.az
  assign_ipv6_address_on_creation                = true
  enable_dns64                                   = true
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  tags = {
    Name    = format("inspection_attachment_%s", each.value.az)
    Network = "private"
    Type    = "attachment"
  }

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "attachment_subnet_rt_association" {
  for_each       = local.attachment_subnet
  subnet_id      = aws_subnet.attachment_subnet[each.key].id
  route_table_id = aws_route_table.attachment[each.key].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_inspection" {
  subnet_ids                                      = [for s in aws_subnet.attachment_subnet : s.id]
  transit_gateway_id                              = var.tgw
  vpc_id                                          = aws_vpc.inspection_vpc.id
  dns_support                                     = "enable"
  appliance_mode_support                          = "enable"
  ipv6_support                                    = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

# TGW association

resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_inspection.id
  transit_gateway_route_table_id = var.tgw_route_tables["shared"]

  depends_on = [
    var.tgw,
    var.tgw_route_tables
  ]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "org" {
  for_each                       = var.tgw_route_tables
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_inspection.id
  transit_gateway_route_table_id = each.value
}

# Inspection subnets for network firewall ENI

resource "aws_route_table" "inspection" {
  for_each = local.inspection_subnet
  vpc_id   = aws_vpc.inspection_vpc.id
  tags = {
    Name    = format("inspection_inspection_%s", each.value.az)
    Network = "private"
    Type    = "inspection"
  }
}

resource "aws_subnet" "inspection_subnet" {
  for_each = local.inspection_subnet

  vpc_id                                         = aws_vpc.inspection_vpc.id
  cidr_block                                     = each.value.subnet
  ipv6_cidr_block                                = each.value.subnet_ipv6
  availability_zone                              = each.value.az
  assign_ipv6_address_on_creation                = true
  enable_dns64                                   = true
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  tags = {
    Name    = format("inspection_inspection_%s", each.value.az)
    Network = "private"
    Type    = "inspection"
  }

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "inspection_subnet" {
  for_each       = local.inspection_subnet
  subnet_id      = aws_subnet.inspection_subnet[each.key].id
  route_table_id = aws_route_table.inspection[each.key].id
}

resource "aws_route" "internal_route" {
  for_each               = aws_route_table.inspection
  route_table_id         = each.value.id
  destination_cidr_block = var.cidr
  transit_gateway_id     = var.tgw
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.vpc_inspection
  ]
}

resource "aws_route" "inspection_route" {
  for_each               = local.inspection_subnet
  route_table_id         = aws_route_table.inspection[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.internet[each.key].id
}

resource "aws_route" "inspection_route_natgw_ipv6" {
  for_each                    = local.inspection_subnet
  route_table_id              = aws_route_table.inspection[each.key].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.internet[each.key].id
}

resource "aws_route" "inspection_route_ipv6" {
  for_each                    = local.inspection_subnet
  route_table_id              = aws_route_table.inspection[each.key].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw.id
}

# Ingress + Egress subnets

resource "aws_route_table" "internet" {
  for_each = local.internet_subnet
  vpc_id   = aws_vpc.inspection_vpc.id
  tags = {
    Name    = format("inspection_internet_%s", each.value.az)
    Network = "public"
    Type    = "internet"
  }
}

resource "aws_subnet" "internet_subnet" {
  #checkov:skip=CKV_AWS_130: Public subnets used for NFW Ingress + Egress
  for_each = local.internet_subnet

  vpc_id                                         = aws_vpc.inspection_vpc.id
  cidr_block                                     = each.value.subnet
  ipv6_cidr_block                                = each.value.subnet_ipv6
  availability_zone                              = each.value.az
  enable_dns64                                   = true
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  map_public_ip_on_launch                        = true
  tags = {
    Name    = format("inspection_internet_%s", each.value.az)
    Network = "public"
    Type    = "internet"
  }

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "aws_route_table_association" "internet_subnet" {
  for_each       = local.internet_subnet
  subnet_id      = aws_subnet.internet_subnet[each.key].id
  route_table_id = aws_route_table.internet[each.key].id
}

resource "aws_route" "ingress_route" {
  for_each               = local.internet_subnet
  route_table_id         = local.internet_rt_lookup[each.key]
  destination_cidr_block = var.cidr
  vpc_endpoint_id        = local.eni_lookup[each.key]
}

resource "aws_route" "egress_route" {
  for_each               = aws_route_table.internet
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.vpc_inspection
  ]
}

resource "aws_route" "egress_route_ipv6" {
  for_each                    = aws_route_table.internet
  route_table_id              = each.value.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw.id
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.vpc_inspection
  ]
}

resource "aws_eip" "internet_vpc_nat" {
  for_each = local.inspection_subnet
  #checkov:skip=CKV2_AWS_19: EIP Used to for NAT Gateway
}

resource "aws_nat_gateway" "internet" {
  for_each = local.internet_subnet

  allocation_id = aws_eip.internet_vpc_nat[each.key].id
  subnet_id     = aws_subnet.internet_subnet[each.key].id

  tags = {
    Name    = format("inspection_natgw_%s", each.value.az)
    Network = "public"
    Type    = "internet"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.inspection_vpc.id
  tags = {
    Name = "inspection_igw"
  }
}

resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.inspection_vpc.id
  tags = {
    Name = "inspection_eigw"
  }
}
