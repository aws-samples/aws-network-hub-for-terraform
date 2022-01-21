/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

locals {

  # We use both the ordering (alphabetical) of this map and the value of it's keys to match created AWS resources
  attachment_subnet = {
    "${var.aws_region}a" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 0), az = var.az_names[0] }
    "${var.aws_region}b" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 1), az = var.az_names[1] }
    "${var.aws_region}c" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 2), az = var.az_names[2] }
  }
  inspection_subnet = {
    "${var.aws_region}a" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 4), az = var.az_names[0] }
    "${var.aws_region}b" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 5), az = var.az_names[1] }
    "${var.aws_region}c" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 6), az = var.az_names[2] }
  }
  internet_subnet = {
    "${var.aws_region}a" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 7), az = var.az_names[0] }
    "${var.aws_region}b" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 8), az = var.az_names[1] }
    "${var.aws_region}c" = { subnet = cidrsubnet(aws_vpc.inspection_vpc.cidr_block, 5, 9), az = var.az_names[2] }
  }

  # Create lookup maps so we can route AZ traffic to it's appropriate NWFW endpoint

  # NWFW declares where it's ENIs are per-AZ, so we need a lookup map against appropriate keys from attachment_subnet map
  eni_lookup = { for state in aws_networkfirewall_firewall.inspection_vpc_network_firewall.firewall_status[0].sync_states : state.availability_zone => state.attachment[0].endpoint_id }
  # We create route tables iterating through attachment_subnet, so iterating through again to map the output IDs should maintain order
  attachment_rt_lookup = zipmap([for k, v in local.attachment_subnet : k], [for s in aws_route_table.attachment : s.id])

  internet_rt_lookup = zipmap([for k, v in local.internet_subnet : k], [for s in aws_route_table.internet : s.id])

}
