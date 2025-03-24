import os
from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from unittest.mock import patch
import json

SUPERUSER_USERNAME = os.getenv('SUPERUSER_USERNAME', 'admin')
SUPERUSER_PASSWORD = os.getenv('SUPERUSER_PASSWORD', 'adminpassword')
SUPERUSER_EMAIL = os.getenv('SUPERUSER_EMAIL', 'admin@gmail.com')

User = get_user_model()

class WolframAlphaAPITest(TestCase):
    def setUp(self):
        self.superuser, _ = User.objects.get_or_create(
            username=SUPERUSER_USERNAME,
            email=SUPERUSER_EMAIL,
            defaults={'is_superuser': True, 'is_staff': True}
        )
        self.superuser.set_password(SUPERUSER_PASSWORD)
        self.superuser.save()

        self.token, _ = Token.objects.get_or_create(user=self.superuser)

        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

    def test_auth(self):
        response = self.client.get("/wolfram/convert-currency/", {
            "amount": "100",
            "from_currency": "USD",
            "to_currency": "EUR"
        })
        response_json = json.loads(response.content)  
        self.assertIn('conversion_result', response_json)
    
    def test_query1(self):
        response = self.client.get("/wolfram/query/", {"query": "What is 2+2?"})
        # print("RESPONSE:", response.content.decode())
        response_data = response.json()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response_data.get('answer'), '4')

    def test_query2(self):
        response = self.client.get("/wolfram/query/", {"query": "What is the area of a circle with radius 5?"})
        response_data = response.json()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response_data.get('answer'), '25 \u03c0\u224878.5398')

    @patch("wolfram.services.WolframAlphaAPI.get_currency_conversion")
    def test_currency_conversion(self, mock_conversion):
        mock_conversion.return_value = "100 USD = 97 EUR"

        response = self.client.get("/wolfram/convert-currency/", {
            "amount": "100",
            "from_currency": "USD",
            "to_currency": "EUR"
        })

        self.assertEqual(response.status_code, 200)
        self.assertIn('conversion_result', json.loads(response.content))
        self.assertEqual(response.json(), {"conversion_result": "100 USD = 97 EUR"})


    @patch("wolfram.services.WolframAlphaAPI.get_currency_conversion")
    def test_currency_conversion_missing_params(self, mock_conversion):
        response = self.client.get("/wolfram/convert-currency/", {
            "amount": "100",
            "from_currency": "USD"
        }) 

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {"error": "Missing required parameters"})

    @patch("wolfram.services.WolframAlphaAPI.get_budget_analysis")
    def test_budget_analysis_success(self, mock_analysis):
        mock_analysis.return_value = "A $5000 budget is enough for monthly living expenses."

        response = self.client.get("/wolfram/analyze-budget/", {
            "amount": "5000"
        })

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"budget_analysis": "A $5000 budget is enough for monthly living expenses."})

    @patch("wolfram.services.WolframAlphaAPI.get_budget_analysis")
    def test_budget_analysis_missing_param(self, mock_analysis):
        """Test missing amount in budget analysis request"""
        response = self.client.get("/wolfram/analyze-budget/")  

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {"error": "Missing budget amount"})
