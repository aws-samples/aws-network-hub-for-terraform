/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

output "org_ipam" {
  description = "Org IPAM ID"
  value       = aws_vpc_ipam.org_ipam.id
}

output "org_ipam_pool" {
  description = "Org IPAM pool ID"
  value       = aws_vpc_ipam_pool.private_org_ipam_pool.id
}
