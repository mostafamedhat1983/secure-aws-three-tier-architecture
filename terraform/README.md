# My Terraform Project

My handwritten project overview and deployment instructions.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.71.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.9.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.71.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alb_internal"></a> [alb\_internal](#module\_alb\_internal) | ./modules/alb | n/a |
| <a name="module_alb_public"></a> [alb\_public](#module\_alb\_public) | ./modules/alb | n/a |
| <a name="module_asg_backend"></a> [asg\_backend](#module\_asg\_backend) | ./modules/asg | n/a |
| <a name="module_asg_frontend"></a> [asg\_frontend](#module\_asg\_frontend) | ./modules/asg | n/a |
| <a name="module_iam_backend"></a> [iam\_backend](#module\_iam\_backend) | ./modules/iam | n/a |
| <a name="module_iam_frontend"></a> [iam\_frontend](#module\_iam\_frontend) | ./modules/iam | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ./modules/rds | n/a |
| <a name="module_route53_private_zone"></a> [route53\_private\_zone](#module\_route53\_private\_zone) | ./modules/route53-private-zone | n/a |
| <a name="module_secrets_manager"></a> [secrets\_manager](#module\_secrets\_manager) | ./modules/secrets-manager | n/a |
| <a name="module_sg_alb"></a> [sg\_alb](#module\_sg\_alb) | ./modules/security-groups | n/a |
| <a name="module_sg_backend"></a> [sg\_backend](#module\_sg\_backend) | ./modules/security-groups | n/a |
| <a name="module_sg_db"></a> [sg\_db](#module\_sg\_db) | ./modules/security-groups | n/a |
| <a name="module_sg_frontend"></a> [sg\_frontend](#module\_sg\_frontend) | ./modules/security-groups | n/a |
| <a name="module_sg_internal_alb"></a> [sg\_internal\_alb](#module\_sg\_internal\_alb) | ./modules/security-groups | n/a |
| <a name="module_waf"></a> [waf](#module\_waf) | ./modules/waf | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudtrail.main](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_metric_alarm.internal_alb_unhealthy_targets](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.public_alb_5xx_errors](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.public_alb_unhealthy_targets](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_free_storage](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_guardduty_detector.main](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/resources/guardduty_detector) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/data-sources/availability_zones) | data source |
| [aws_ecr_repository.backend](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/data-sources/ecr_repository) | data source |
| [aws_ecr_repository.frontend](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/data-sources/ecr_repository) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/6.71.0/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_app_secret_arn"></a> [app\_secret\_arn](#output\_app\_secret\_arn) | ARN of the application encryption/session keys secret. |
| <a name="output_application_url"></a> [application\_url](#output\_application\_url) | Public application URL (create the Namecheap CNAME after apply). |
| <a name="output_asg_names"></a> [asg\_names](#output\_asg\_names) | Auto Scaling Group names for the frontend and backend tiers. |
| <a name="output_backend_dns_name"></a> [backend\_dns\_name](#output\_backend\_dns\_name) | Private DNS name pointing to the internal ALB. |
| <a name="output_backend_image"></a> [backend\_image](#output\_backend\_image) | Backend image reference used by the backend Auto Scaling Group. |
| <a name="output_frontend_image"></a> [frontend\_image](#output\_frontend\_image) | Frontend image reference used by the frontend Auto Scaling Group. |
| <a name="output_frontend_image_build_command"></a> [frontend\_image\_build\_command](#output\_frontend\_image\_build\_command) | Build the frontend using the private backend DNS name. |
| <a name="output_internal_alb_dns_name"></a> [internal\_alb\_dns\_name](#output\_internal\_alb\_dns\_name) | Private AWS-generated DNS name used by the frontend container. |
| <a name="output_public_alb_dns_name"></a> [public\_alb\_dns\_name](#output\_public\_alb\_dns\_name) | Create a CNAME for vault.mostafa-medhat.online pointing to this DNS name. |
| <a name="output_rds_address"></a> [rds\_address](#output\_rds\_address) | Private RDS endpoint hostname. |
| <a name="output_rds_master_secret_arn"></a> [rds\_master\_secret\_arn](#output\_rds\_master\_secret\_arn) | ARN of the RDS-managed master credentials secret. |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Security group IDs for each application tier. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Subnet IDs indexed by the keys defined in the networking module call. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the project VPC. |
| <a name="output_waf_web_acl_arn"></a> [waf\_web\_acl\_arn](#output\_waf\_web\_acl\_arn) | ARN of the Web ACL associated with the public ALB. |
<!-- END_TF_DOCS -->
