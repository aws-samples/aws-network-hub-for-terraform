/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

output "inspection_attachment" {
  value       = aws_ec2_transit_gateway_vpc_attachment.vpc_inspection.id
  description = "Inspection TGW attachment ID for default route in TGW"
}

output "firewall_info" {
  value       = aws_networkfirewall_firewall.inspection_vpc_network_firewall
  description = "Info of network firewall for routing"
}

output "route_table" {
  value       = aws_route_table.inspection
  description = "Output route tables used for NFW"
}

output "eni_map" {
  value       = local.eni_lookup
  description = "Output ENI map"
}

output "rt_map" {
  value       = local.attachment_rt_lookup
  description = "Output RT map"
}
