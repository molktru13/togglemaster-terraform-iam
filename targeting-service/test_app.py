import os
import unittest

os.environ["TESTING"] = "true"
os.environ["DATABASE_URL"] = "postgres://postgres:postgres@localhost:5432/targeting_db"
os.environ["AUTH_SERVICE_URL"] = "http://localhost:8001"

from app import app  # noqa: E402


class TargetingServiceTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_health_endpoint(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "ok"})

    def test_create_rule_requires_auth(self):
        response = self.client.post(
            "/rules",
            json={"flag_name": "test-flag", "rules": {"type": "PERCENTAGE", "value": 50}}
        )
        self.assertEqual(response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
