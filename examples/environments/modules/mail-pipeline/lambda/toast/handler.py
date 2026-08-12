"""TOAST stand-in.

Today: TOAST has no SMTP. Disseminate = template + addScript (often → GDS).

Here: write a GDS-style spool pair to S3 (bulletin body + recipients).
The gds_spooler Lambda picks that up like send_email.py.
"""

from __future__ import annotations

import json
import os
import time
import uuid

import boto3


def handler(event, context):
    payload = event if isinstance(event, dict) else json.loads(event or "{}")

    bucket = os.environ["SPOOL_BUCKET"]
    job_id = payload.get("jobId") or str(uuid.uuid4())
    prefix = f"spool/{job_id}"

    from_address = payload.get("from") or os.environ["DEFAULT_FROM"]
    to_raw = payload.get("to") or os.environ["DEFAULT_TO"]
    to_addresses = to_raw if isinstance(to_raw, list) else [to_raw]
    subject = payload.get("subject", "TOAST bulletin")
    body = payload.get("body", "hello from TOAST → GDS spool stand-in")

    # GDS-like: address file + content file in a spool directory.
    address = {
        "from": from_address,
        "to": to_addresses,
        "subject": subject,
    }
    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=bucket,
        Key=f"{prefix}/address.json",
        Body=json.dumps(address).encode("utf-8"),
        ContentType="application/json",
    )
    # Content object last — spooler triggers on *.body so address exists first.
    s3.put_object(
        Bucket=bucket,
        Key=f"{prefix}/bulletin.body",
        Body=body.encode("utf-8"),
        ContentType="text/plain",
    )

    return {
        "mechanism": "toast",
        "jobId": job_id,
        "spoolPrefix": f"s3://{bucket}/{prefix}/",
        "note": "gds_spooler will enqueue when bulletin.body lands",
        "writtenAt": time.time(),
    }
