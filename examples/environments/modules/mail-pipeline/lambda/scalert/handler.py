"""scalert stand-in.

Today: scalert execs an external script (scripts.event, …); the script usually
calls mail/mailx. Next alert is skipped while that script still runs.

Here: receive an alert-shaped event, run the "script" (enqueue to SQS), return.
"""

from __future__ import annotations

import json
import os

import boto3


def _run_mail_script(alert: dict) -> str:
    """Replacement for the operator script that used to call mailx."""
    subject = alert.get("subject") or f"scalert {alert.get('type', 'event')} {alert.get('publicID', '')}".strip()
    body = alert.get("body") or (
        f"type={alert.get('type', 'event')}\n"
        f"publicID={alert.get('publicID', 'demo-origin')}\n"
        f"message={alert.get('message', 'hello from scalert stand-in')}\n"
    )

    message = {
        "mechanism": "scalert",
        "from": alert.get("from") or os.environ["DEFAULT_FROM"],
        "to": alert.get("to") or os.environ["DEFAULT_TO"],
        "subject": subject,
        "body": body,
        "alert": {
            "type": alert.get("type", "event"),
            "publicID": alert.get("publicID", "demo-origin"),
        },
    }
    if isinstance(message["to"], str):
        message["to"] = [message["to"]]

    client = boto3.client("sqs")
    response = client.send_message(
        QueueUrl=os.environ["QUEUE_URL"],
        MessageBody=json.dumps(message),
    )
    return response["MessageId"]


def handler(event, context):
    payload = event if isinstance(event, dict) else json.loads(event or "{}")
    message_id = _run_mail_script(payload)
    return {"mechanism": "scalert", "queueMessageId": message_id}
