/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

output "inspection_attachment" {
  value       = aws_ec2_transit_gateway_vpc_attachment.vpc_inspection.id
  description = "inspection tgw attachment id for default route in tgw"
}

output "firewall_info" {
  value       = aws_networkfirewall_firewall.inspection_vpc_network_firewall
  description = "Info of network fire for routing"
}

output "route_table" {
  value       = aws_route_table.inspection
  description = "output route tables used for NFW"
}

output "eni_map" {
  value = local.eni_lookup
}

output "rt_map" {
  value = local.attachment_rt_lookup
}
