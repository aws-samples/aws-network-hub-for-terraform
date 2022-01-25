/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

data "aws_caller_identity" "current" {}

data "aws_route53_resolver_rule" "root_domain" {
  domain_name = var.root_domain
}

data "aws_route53_zone" "selected" {
  provider     = aws.network_hub
  name         = var.root_domain
  private_zone = true
}

data "aws_vpc" "selected" {
  provider = aws.network_hub
  filter {
    name   = "tag:Name"
    values = ["dns_vpc"]
  }
}

data "aws_vpc" "endpoint" {
  provider = aws.network_hub
  filter {
    name   = "tag:Name"
    values = ["endpoint_vpc"]
  }
}

data "aws_route53_zone" "centralised_endpoints" {
  provider = aws.network_hub
  for_each = var.centralised_vpc_endpoints
  name     = each.value
  vpc_id   = data.aws_vpc.endpoint.id
}