# Environments example

Separate Terraform states for **dev** (sandbox email identities) and **prod** (domain identity). Both use the same mail pipeline that stands in for SeisComP send paths.

```
examples/environments/
  modules/mail-pipeline/   # mailx, scalert, TOAST→GDS → SQS → worker → SES
  dev/
  prod/
```

## SeisComP mechanisms

| Stand-in | Mimics | Path |
|---|---|---|
| `mailx` Lambda | scm `memailplugin` / `mailx` | enqueue → SQS |
| `scalert` Lambda | scalert external mail script | enqueue → SQS |
| `toast` Lambda | TOAST `addScript` | write GDS spool (S3) |
| `gds_spooler` Lambda | GDS `send_email.py` | S3 create → enqueue → delete spool |
| `worker` Lambda | SES sender | SQS → `SendEmail` |
| `e2e_all` Lambda | runs mailx + scalert + toast | one invoke |

```text
mailx ────────────┐
scalert ──────────┼──► SQS ──► worker ──► SES
toast → S3 spool ─┘              │
         ▲                       └──► DLQ
   gds_spooler (ObjectCreated)
```

S3 is only a **demo** stand-in for the GDS disk spool. Real GDS should keep a local spool and enqueue to SQS from `spooler.cmd`.

## Dev (sandbox)

```bash
cd examples/environments/dev
cp terraform.tfvars.example terraform.tfvars
# set verified email identities, then:
terraform init
terraform apply
# confirm mailbox verification + SNS subscription, then:
terraform output -raw e2e_all_command | bash
```

Expect three SES sends (mailx, scalert, TOAST/GDS) and matching SNS Send/Delivery events.

## Prod

Same pipeline; SES uses `domain_identity`. Set `terraform.tfvars` from the example, publish DNS if Route 53 is not managing records, then apply. Leave `sns_email_subscriptions` empty in production.

```bash
cd examples/environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```
