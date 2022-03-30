/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

output "vpc_id" {
  value       = module.network.vpc_id
  description = "vpc id used for other modules"
}
