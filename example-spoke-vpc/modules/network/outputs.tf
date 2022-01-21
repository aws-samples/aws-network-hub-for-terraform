/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

output "vpc_id" {
  value       = aws_vpc.spoke_vpc.id
  description = "vpc id used for other modules"
}