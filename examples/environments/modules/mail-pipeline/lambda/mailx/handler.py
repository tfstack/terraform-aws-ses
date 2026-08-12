"""scm memailplugin / mailx stand-in.

Today: mailx hands off to Postfix and returns.
Here: enqueue to SQS and return (same fire-and-forget moment).
"""

from __future__ import annotations

import json
import os

import boto3


def _enqueue(message: dict) -> str:
    client = boto3.client("sqs")
    response = client.send_message(
        QueueUrl=os.environ["QUEUE_URL"],
        MessageBody=json.dumps(message),
    )
    return response["MessageId"]


def handler(event, context):
    payload = event if isinstance(event, dict) else json.loads(event or "{}")

    message = {
        "mechanism": "mailx",
        "from": payload.get("from") or os.environ["DEFAULT_FROM"],
        "to": payload.get("to") or os.environ["DEFAULT_TO"],
        "subject": payload.get("subject", "scm health"),
        "body": payload.get("body", "hello from mailx / memailplugin stand-in"),
    }
    if isinstance(message["to"], str):
        message["to"] = [message["to"]]

    message_id = _enqueue(message)
    return {"mechanism": "mailx", "queueMessageId": message_id, "mail": message}
