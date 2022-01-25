/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_flow_log" "vpc" {
  iam_role_arn    = var.iam_role_arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.dns_vpc.id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "dns_vpc"
  retention_in_days = 7
  kms_key_id        = var.kms_key_id
}