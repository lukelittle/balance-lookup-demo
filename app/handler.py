"""Niner National Bank - balance-lookup API (ITCS 5010, week 1).

GET <function-url>/?account_id=1001  ->  {"account_id": "1001", "balance": 2512.75, ...}

Failure injection is controlled by environment variables that Terraform sets:
  FAILURE_RATE      0.0-1.0  fraction of requests that raise an error
  ADDED_LATENCY_MS  int      sleep added to every request
"""

import json
import logging
import os
import random
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Fake core-banking data. In later weeks this moves to DynamoDB / RDS.
ACCOUNTS = {
    "1001": {"owner": "A. Mason", "type": "checking", "balance": 2512.75},
    "1002": {"owner": "R. Patel", "type": "savings", "balance": 18040.10},
    "1003": {"owner": "J. Okafor", "type": "checking", "balance": 77.42},
    "1004": {"owner": "L. Nguyen", "type": "money-market", "balance": 50250.00},
}


class InjectedFailure(Exception):
    """Raised on purpose by the failure-injection knob."""


def log(level, msg, **fields):
    """Structured (JSON) logging so CloudWatch Logs Insights can query fields."""
    logger.log(getattr(logging, level), json.dumps({"level": level, "msg": msg, **fields}))


def response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", "Cache-Control": "no-store"},
        "body": json.dumps(body),
    }


def maybe_inject_failure(rng=random.random, sleep=time.sleep):
    latency_ms = int(float(os.environ.get("ADDED_LATENCY_MS", "0")))
    if latency_ms > 0:
        sleep(latency_ms / 1000)
    if rng() < float(os.environ.get("FAILURE_RATE", "0")):
        raise InjectedFailure("core banking backend unavailable (injected)")


def lambda_handler(event, context):
    params = (event or {}).get("queryStringParameters") or {}
    account_id = params.get("account_id")

    if account_id is None:
        return response(200, {"service": "nnb-balance-lookup", "status": "ok",
                              "usage": "?account_id=1001"})

    # Raising (instead of returning 500) is deliberate: it makes the Lambda
    # "Errors" metric count the failure, which is what our alarm watches.
    try:
        maybe_inject_failure()
    except InjectedFailure:
        log("ERROR", "balance lookup failed", account_id=account_id)
        raise

    account = ACCOUNTS.get(account_id)
    if account is None:
        log("WARNING", "unknown account", account_id=account_id)
        return response(404, {"error": "account not found", "account_id": account_id})

    log("INFO", "balance lookup ok", account_id=account_id)
    return response(200, {
        "account_id": account_id,
        "type": account["type"],
        "balance": account["balance"],
        "currency": "USD",
        "team": os.environ.get("TEAM_NAME", "unknown"),
    })
