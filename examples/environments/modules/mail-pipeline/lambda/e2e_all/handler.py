"""Run all SeisComP mail mechanism stand-ins in one invoke."""

from __future__ import annotations

import json
import os
import time
import uuid

import boto3


def _invoke(function_name: str, payload: dict) -> dict:
    client = boto3.client("lambda")
    response = client.invoke(
        FunctionName=function_name,
        InvocationType="RequestResponse",
        Payload=json.dumps(payload).encode("utf-8"),
    )
    body = response["Payload"].read().decode("utf-8")
    return json.loads(body) if body else {}


def handler(event, context):
    payload = event if isinstance(event, dict) else json.loads(event or "{}")
    from_address = payload.get("from") or os.environ["DEFAULT_FROM"]
    to_address = payload.get("to") or os.environ["DEFAULT_TO"]

    mailx = _invoke(
        os.environ["MAILX_FUNCTION"],
        {
            "from": from_address,
            "to": to_address,
            "subject": "mailx / scm health",
            "body": "hello from mailx stand-in",
        },
    )

    scalert = _invoke(
        os.environ["SCALERT_FUNCTION"],
        {
            "from": from_address,
            "to": to_address,
            "type": "event",
            "publicID": "demo-origin-1",
            "message": "hello from scalert stand-in",
        },
    )

    job_id = str(uuid.uuid4())
    toast = _invoke(
        os.environ["TOAST_FUNCTION"],
        {
            "jobId": job_id,
            "from": from_address,
            "to": to_address,
            "subject": "TOAST → GDS bulletin",
            "body": "hello from TOAST/GDS stand-in",
        },
    )

    # GDS spooler is async via S3; wait briefly then list whether spool cleared.
    time.sleep(3)
    s3 = boto3.client("s3")
    listed = s3.list_objects_v2(
        Bucket=os.environ["SPOOL_BUCKET"],
        Prefix=f"spool/{job_id}/",
    )
    gds_pending = [obj["Key"] for obj in listed.get("Contents", [])]

    return {
        "mailx": mailx,
        "scalert": scalert,
        "toast": toast,
        "gdsSpoolRemaining": gds_pending,
        "note": "gdsSpoolRemaining empty means gds_spooler enqueued and deleted spool files",
    }
