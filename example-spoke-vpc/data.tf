/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ec2_transit_gateway" "org_env" {
  provider = aws.network_hub
  filter {
    name   = "tag:Name"
    values = ["Org_TGW_${var.environment}"]
  }
}

data "aws_ec2_transit_gateway_route_table" "org_env" {
  provider = aws.network_hub
  for_each = local.tgw_map
  filter {
    name   = "tag:Name"
    values = ["${each.value}"]
  }
}

data "aws_ec2_transit_gateway_route_table" "associate" {
  provider = aws.network_hub
  filter {
    name   = "tag:Name"
    values = ["${var.environment != "prod" ? "dev" : "prod"}"]
  }
}