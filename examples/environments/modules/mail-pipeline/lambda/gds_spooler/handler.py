"""GDS send_email.py / spooler stand-in.

Today: GDS backend writes spool files; send_email.py polls and sends via local MTA.

Here: S3 ObjectCreated on *.body → read address.json + body → enqueue SQS → delete spool.
"""

from __future__ import annotations

import json
import os
import urllib.parse

import boto3


def _process_spool(bucket: str, body_key: str) -> dict:
    if not body_key.endswith("bulletin.body"):
        return {"skipped": True, "key": body_key}

    prefix = body_key.rsplit("/", 1)[0]
    address_key = f"{prefix}/address.json"

    s3 = boto3.client("s3")
    address = json.loads(s3.get_object(Bucket=bucket, Key=address_key)["Body"].read())
    body = s3.get_object(Bucket=bucket, Key=body_key)["Body"].read().decode("utf-8")

    message = {
        "mechanism": "gds",
        "from": address["from"],
        "to": address["to"] if isinstance(address["to"], list) else [address["to"]],
        "subject": address.get("subject", "GDS bulletin"),
        "body": body,
        "spool": {"bucket": bucket, "prefix": prefix},
    }

    sqs = boto3.client("sqs")
    response = sqs.send_message(
        QueueUrl=os.environ["QUEUE_URL"],
        MessageBody=json.dumps(message),
    )

    # Spool accepted into queue — remove files (GDS deletes after successful handoff).
    s3.delete_object(Bucket=bucket, Key=address_key)
    s3.delete_object(Bucket=bucket, Key=body_key)

    return {
        "mechanism": "gds",
        "queueMessageId": response["MessageId"],
        "spoolPrefix": prefix,
    }


def handler(event, context):
    results = []
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        results.append(_process_spool(bucket, key))
    return {"results": results}
