from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from django.test import TestCase

class AuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.signup_url = reverse("signup")
        self.login_url = reverse("login")
        self.username = "test_user"
        self.password = "test_password"
        self.user_data = {"username": self.username, "password": self.password}

    def test_signup(self):
        response = self.client.post(self.signup_url, self.user_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        user_exists = User.objects.filter(username=self.username).exists()
        self.assertTrue(user_exists)


    def test_login_invalid(self):
        invalid_data = {"username": "wronguser", "password": "wrongpassword"}
        response = self.client.post(self.login_url, invalid_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        self.assertIn("error", response.data)
        self.assertEqual(response.data["error"], "Invalid credentials")

    def test_login_invalid(self):
        invalid_data = {"username": "wronguser", "password": "wrongpassword"}
        response = self.client.post(self.login_url, invalid_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("error", response.data)
