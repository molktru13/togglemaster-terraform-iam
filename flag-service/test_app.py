import os
import unittest

os.environ["TESTING"] = "true"
os.environ["DATABASE_URL"] = "postgres://postgres:postgres@localhost:5432/flags_db"
os.environ["AUTH_SERVICE_URL"] = "http://localhost:8001"

from app import app  # noqa: E402


class FlagServiceTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_health_endpoint(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "ok"})

    def test_create_flag_requires_auth(self):
        response = self.client.post("/flags", json={"name": "test-flag"})
        self.assertEqual(response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
