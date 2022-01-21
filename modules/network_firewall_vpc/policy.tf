/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_networkfirewall_firewall_policy" "anfw_policy" {
  name = "firewall-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    # stateless_rule_group_reference {
    #   priority     = 20
    #   resource_arn = aws_networkfirewall_rule_group.drop_icmp.arn
    # }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.block_domains.arn
    }
    # stateful_rule_group_reference {
    #   resource_arn = aws_networkfirewall_rule_group.drop_ssh_between_vpcs.arn
    # }
  }
}

# resource "aws_networkfirewall_rule_group" "drop_icmp" {
#   capacity = 1
#   name     = "drop-icmp"
#   type     = "STATELESS"
#   rule_group {
#     rules_source {
#       stateless_rules_and_custom_actions {
#         stateless_rule {
#           priority = 1
#           rule_definition {
#             actions = ["aws:drop"]
#             match_attributes {
#               protocols = [1]
#               source {
#                 address_definition = "0.0.0.0/0"
#               }
#               destination {
#                 address_definition = "0.0.0.0/0"
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

resource "aws_networkfirewall_rule_group" "block_domains" {
  capacity = 100
  name     = "block-domains"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.cidr]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".facebook.com", ".twitter.com"]
      }
    }
  }
}



# resource "aws_networkfirewall_rule_group" "drop_ssh_between_vpcs" {
#   capacity = 100
#   name     = "drop-ssh-between-spokes"
#   type     = "STATEFUL"
#   rule_group {
#     rule_variables {
#       ip_sets {
#         key = "SPOKE_VPCS"
#         ip_set {
#           definition = [for i in var.spoke_cidr_blocks : i]
#         }
#       }
#     }
#     rules_source {
#       rules_string = <<EOF
#       drop tcp $SPOKE_VPCS any <> $SPOKE_VPCS 22 (msg:"Blocked SSH attempt"; sid:100; rev:1;)
#       EOF
#     }
#   }
# }
