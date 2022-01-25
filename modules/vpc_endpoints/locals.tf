/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

locals {
  attachment_subnet = {
    "az2a" = { subnet = cidrsubnet(aws_vpc.endpoint_vpc.cidr_block, 5, 0), az = var.az_names[0] }
    "az2b" = { subnet = cidrsubnet(aws_vpc.endpoint_vpc.cidr_block, 5, 1), az = var.az_names[1] }
    "az2c" = { subnet = cidrsubnet(aws_vpc.endpoint_vpc.cidr_block, 5, 2), az = var.az_names[2] }
  }
  endpoint_subnet = {
    "az2a" = { subnet = cidrsubnet(aws_vpc.endpoint_vpc.cidr_block, 4, 2), az = var.az_names[0] }
    "az2b" = { subnet = cidrsubnet(aws_vpc.endpoint_vpc.cidr_block, 4, 3), az = var.az_names[1] }
    "az2c" = { subnet = cidrsubnet(aws_vpc.endpoint_vpc.cidr_block, 4, 4), az = var.az_names[2] }
  }
}
