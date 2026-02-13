import json
import os
from http.server import BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

import boto3
from botocore.exceptions import ClientError

BUCKET = "df-2021"
REGION = "us-east-1"
KEY_PREFIX = "Data/DanReps/exers"

_s3 = None


def _get_s3():
    global _s3
    if _s3 is None:
        _s3 = boto3.client("s3")
    return _s3


class handler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, body):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(body).encode("utf-8"))

    def _check_auth(self):
        api_key = self.headers.get("X-API-Key", "")
        expected_key = os.environ.get("DANREPS_API_KEY", "")
        if not expected_key or api_key != expected_key:
            self._send_json(401, {"error": "Unauthorized Bozo " + expected_key})
            return False
        return True

    def _get_user_id(self):
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        user_id = qs.get("userId", [None])[0]
        if not user_id:
            self._send_json(400, {"error": "userId required Bozo"})
            return None
        return user_id

    def do_GET(self):
        if not self._check_auth():
            return
        print("Auth successful")
        user_id = self._get_user_id()
        if not user_id:
            return
        print("user_id successful")
     
        s3_key = f"{KEY_PREFIX}{user_id}.json"
        print("S3 key " + s3_key)
        try:
            s3 = _get_s3()
            print("S3 client created " + str(s3))
            obj = s3.get_object(Bucket=BUCKET, Key=s3_key)
            print("Got obj " + str(obj["ContentLength"]))
            
            body = obj["Body"].read().decode("utf-8")
            print("Got body")
            self._send_json(200, json.loads(body))
            print("Send json")
        except ClientError as e:
            if e.response["Error"]["Code"] == "NoSuchKey":
                self._send_json(404, {"error": "Not found Bozo"})
            else:
                raise

    def do_PUT(self):
        if not self._check_auth():
            return
        user_id = self._get_user_id()
        if not user_id:
            return

        s3_key = f"{KEY_PREFIX}{user_id}.json"
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        data = json.loads(body)
        _get_s3().put_object(
            Bucket=BUCKET,
            Key=s3_key,
            Body=json.dumps(data),
            ContentType="application/json",
        )
        self._send_json(200, {"success": True})
