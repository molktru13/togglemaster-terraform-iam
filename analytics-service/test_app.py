import os
import unittest

os.environ["TESTING"] = "true"
os.environ["AWS_REGION"] = "us-east-1"
os.environ["AWS_SQS_URL"] = "https://sqs.us-east-1.amazonaws.com/290528720221/toggle-master-events"
os.environ["AWS_DYNAMODB_TABLE"] = "ToggleMasterAnalytics"

from app import app  # noqa: E402


class AnalyticsServiceTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_health_endpoint(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "ok"})


if __name__ == "__main__":
    unittest.main()
