# terraform-aws-ses

Terraform module for Amazon SES outbound mail identities, configuration sets, and SNS delivery events.

See [examples/environments](examples/environments) for sandbox and production roots with a SeisComP mail-pipeline stand-in (mailx, scalert, TOAST/GDS → SQS → SES).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.58.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.sender](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.sender](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.domain_spf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mail_from_mx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mail_from_spf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_sesv2_configuration_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set) | resource |
| [aws_sesv2_configuration_set_event_destination.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set_event_destination) | resource |
| [aws_sesv2_email_identity.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity) | resource |
| [aws_sesv2_email_identity.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity) | resource |
| [aws_sesv2_email_identity_mail_from_attributes.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity_mail_from_attributes) | resource |
| [aws_sns_topic.events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.ses_publish](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.sender](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_ses_publish](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_from_addresses"></a> [allowed\_from\_addresses](#input\_allowed\_from\_addresses) | Optional From addresses enforced by IAM condition. Empty allows any From on the verified identities. | `list(string)` | `[]` | no |
| <a name="input_assign_configuration_set"></a> [assign\_configuration\_set](#input\_assign\_configuration\_set) | Attach the configuration set as the default on created identities. | `bool` | `true` | no |
| <a name="input_configuration_set_name"></a> [configuration\_set\_name](#input\_configuration\_set\_name) | Name of the SES configuration set. | `string` | n/a | yes |
| <a name="input_create_configuration_set"></a> [create\_configuration\_set](#input\_create\_configuration\_set) | Whether to create a configuration set. | `bool` | `true` | no |
| <a name="input_create_domain_spf_record"></a> [create\_domain\_spf\_record](#input\_create\_domain\_spf\_record) | Create an SPF TXT record on the sending domain. | `bool` | `false` | no |
| <a name="input_create_event_destination"></a> [create\_event\_destination](#input\_create\_event\_destination) | Whether to create an SNS event destination on the configuration set. | `bool` | `true` | no |
| <a name="input_create_mail_from_spf_record"></a> [create\_mail\_from\_spf\_record](#input\_create\_mail\_from\_spf\_record) | Create an SPF TXT record on the custom MAIL FROM subdomain. | `bool` | `true` | no |
| <a name="input_create_route53_records"></a> [create\_route53\_records](#input\_create\_route53\_records) | Create Route 53 records when route53\_zone\_id is set. | `bool` | `false` | no |
| <a name="input_create_sender_policy"></a> [create\_sender\_policy](#input\_create\_sender\_policy) | Whether to create and attach an IAM policy that allows SendEmail / SendRawEmail. | `bool` | `true` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | Whether to create an SNS topic for SES events. | `bool` | `true` | no |
| <a name="input_domain_identity"></a> [domain\_identity](#input\_domain\_identity) | Production pattern: one verified domain. Mutually exclusive with email\_identities.<br/>Email addresses on the domain (noreply@mail.example.com) do not need separate identities. | <pre>object({<br/>    domain                           = string<br/>    enable_easy_dkim                 = optional(bool, true)<br/>    dkim_signing_key_length          = optional(string, "RSA_2048_BIT")<br/>    mail_from_domain                 = optional(string)<br/>    mail_from_behavior_on_mx_failure = optional(string, "USE_DEFAULT_VALUE")<br/>  })</pre> | `null` | no |
| <a name="input_email_identities"></a> [email\_identities](#input\_email\_identities) | Sandbox / dev pattern: verified email addresses. Mutually exclusive with domain\_identity. | `list(string)` | `[]` | no |
| <a name="input_event_destination_name"></a> [event\_destination\_name](#input\_event\_destination\_name) | Name of the configuration set event destination. | `string` | `"sns"` | no |
| <a name="input_event_types"></a> [event\_types](#input\_event\_types) | SES event types published to SNS. | `list(string)` | <pre>[<br/>  "SEND",<br/>  "DELIVERY",<br/>  "BOUNCE",<br/>  "COMPLAINT"<br/>]</pre> | no |
| <a name="input_reputation_metrics_enabled"></a> [reputation\_metrics\_enabled](#input\_reputation\_metrics\_enabled) | Enable reputation metrics on the configuration set. | `bool` | `true` | no |
| <a name="input_route53_record_ttl"></a> [route53\_record\_ttl](#input\_route53\_record\_ttl) | TTL for created Route 53 records. | `number` | `600` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route 53 hosted zone ID for automatic DKIM / MAIL FROM records. Leave null to manage DNS elsewhere. | `string` | `null` | no |
| <a name="input_sender_policy_name"></a> [sender\_policy\_name](#input\_sender\_policy\_name) | Optional override for the sender IAM policy name. | `string` | `null` | no |
| <a name="input_sender_role_names"></a> [sender\_role\_names](#input\_sender\_role\_names) | IAM role names (not ARNs) that may send through the created identities. | `list(string)` | `[]` | no |
| <a name="input_sending_enabled"></a> [sending\_enabled](#input\_sending\_enabled) | Whether sending is enabled on the configuration set. | `bool` | `true` | no |
| <a name="input_sns_email_subscriptions"></a> [sns\_email\_subscriptions](#input\_sns\_email\_subscriptions) | Optional email endpoints subscribed to the events topic. Demo only; each inbox must confirm the SNS subscription. | `list(string)` | `[]` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | Existing SNS topic ARN when create\_sns\_topic is false. | `string` | `null` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name of the SNS topic when create\_sns\_topic is true. Defaults to "{configuration\_set\_name}-events". | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to supported resources. | `map(string)` | `{}` | no |
| <a name="input_tls_policy"></a> [tls\_policy](#input\_tls\_policy) | TLS policy for the configuration set. Valid values: REQUIRE, OPTIONAL. | `string` | `"REQUIRE"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configuration_set_arn"></a> [configuration\_set\_arn](#output\_configuration\_set\_arn) | ARN of the SES configuration set. |
| <a name="output_configuration_set_name"></a> [configuration\_set\_name](#output\_configuration\_set\_name) | Name of the SES configuration set. |
| <a name="output_dkim_tokens"></a> [dkim\_tokens](#output\_dkim\_tokens) | Easy DKIM tokens for the domain identity. Create CNAME records unless Route 53 is managing them. |
| <a name="output_domain_identity_arn"></a> [domain\_identity\_arn](#output\_domain\_identity\_arn) | ARN of the domain identity when domain\_identity is set. |
| <a name="output_domain_identity_verification_status"></a> [domain\_identity\_verification\_status](#output\_domain\_identity\_verification\_status) | Verification status of the domain identity. |
| <a name="output_email_identity_arns"></a> [email\_identity\_arns](#output\_email\_identity\_arns) | Map of email address to identity ARN. |
| <a name="output_email_identity_verification_status"></a> [email\_identity\_verification\_status](#output\_email\_identity\_verification\_status) | Map of email address to verification status. |
| <a name="output_identity_arns"></a> [identity\_arns](#output\_identity\_arns) | All created identity ARNs. |
| <a name="output_mail_from_domain"></a> [mail\_from\_domain](#output\_mail\_from\_domain) | Custom MAIL FROM domain when configured. |
| <a name="output_sender_policy_arn"></a> [sender\_policy\_arn](#output\_sender\_policy\_arn) | ARN of the IAM sender policy when created. |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic receiving SES events. |
| <a name="output_sns_topic_name"></a> [sns\_topic\_name](#output\_sns\_topic\_name) | Name of the created SNS topic. |
<!-- END_TF_DOCS -->
