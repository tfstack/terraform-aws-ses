import json
import os

import boto3


class RetryableSendError(Exception):
    pass


def _send_mail(body):
    client = boto3.client("ses", region_name=os.environ["AWS_REGION_NAME"])

    to_addresses = body["to"] if isinstance(body["to"], list) else [body["to"]]

    request = {
        "Source": body["from"],
        "Destination": {"ToAddresses": to_addresses},
        "Message": {
            "Subject": {"Data": body["subject"], "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body["body"], "Charset": "UTF-8"}},
        },
    }

    configuration_set = os.environ.get("CONFIGURATION_SET_NAME")
    if configuration_set:
        request["ConfigurationSetName"] = configuration_set

    try:
        response = client.send_email(**request)
    except client.exceptions.MessageRejected as exc:
        print(json.dumps({"status": "rejected", "error": str(exc), "mail": body}))
        return None
    except client.exceptions.TooManyRequestsException as exc:
        raise RetryableSendError(str(exc)) from exc
    except client.exceptions.ServiceUnavailableException as exc:
        raise RetryableSendError(str(exc)) from exc

    return response["MessageId"]


def handler(event, context):
    failures = []

    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            message_id = _send_mail(body)
            if message_id:
                print(json.dumps({"status": "sent", "messageId": message_id, "mail": body}))
        except RetryableSendError as exc:
            print(json.dumps({"status": "retry", "error": str(exc), "messageId": record["messageId"]}))
            failures.append({"itemIdentifier": record["messageId"]})
        except Exception as exc:
            print(json.dumps({"status": "failed", "error": str(exc), "messageId": record["messageId"]}))
            failures.append({"itemIdentifier": record["messageId"]})

    return {"batchItemFailures": failures}
