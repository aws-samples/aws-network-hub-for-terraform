/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

output "tgw" {
  description = "tgw id for attachments"
  value       = aws_ec2_transit_gateway.org_tgw.id
}

output "tgw_route_table" {
  description = "map of route tables used for association and propagation"
  value = tomap({
    for k, rt in aws_ec2_transit_gateway_route_table.org_tgw : k => rt.id
  })
}
