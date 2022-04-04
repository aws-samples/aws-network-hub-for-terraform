/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

locals {
  dns_proto = ["tcp", "udp"]
  attachment_subnet = {
    "az2a" = {
      subnet      = cidrsubnet(aws_vpc.dns_vpc.cidr_block, 5, 0),     # /27
      subnet_ipv6 = cidrsubnet(aws_vpc.dns_vpc.ipv6_cidr_block, 8, 0) # /64
      az          = var.az_names[0]
    }
    "az2b" = {
      subnet      = cidrsubnet(aws_vpc.dns_vpc.cidr_block, 5, 1),     # /27
      subnet_ipv6 = cidrsubnet(aws_vpc.dns_vpc.ipv6_cidr_block, 8, 1) # /64
      az          = var.az_names[1]
    }
    "az2c" = {
      subnet      = cidrsubnet(aws_vpc.dns_vpc.cidr_block, 5, 2),     # /27
      subnet_ipv6 = cidrsubnet(aws_vpc.dns_vpc.ipv6_cidr_block, 8, 2) # /64
      az          = var.az_names[2]
    }
  }
  endpoint_subnet = {
    "az2a" = {
      subnet      = cidrsubnet(aws_vpc.dns_vpc.cidr_block, 4, 2),     # /26
      subnet_ipv6 = cidrsubnet(aws_vpc.dns_vpc.ipv6_cidr_block, 8, 3) # /64
      az          = var.az_names[0]
    }
    "az2b" = {
      subnet      = cidrsubnet(aws_vpc.dns_vpc.cidr_block, 4, 3),     # /26
      subnet_ipv6 = cidrsubnet(aws_vpc.dns_vpc.ipv6_cidr_block, 8, 4) # /64
      az          = var.az_names[1]
    }
    "az2c" = {
      subnet      = cidrsubnet(aws_vpc.dns_vpc.cidr_block, 4, 4),     # /26
      subnet_ipv6 = cidrsubnet(aws_vpc.dns_vpc.ipv6_cidr_block, 8, 5) # /64
      az          = var.az_names[2]
    }
  }
}
