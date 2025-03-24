from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from .models import Budget
from decimal import Decimal
from django.contrib.auth.models import User
from django.contrib.auth import get_user_model
from dotenv import load_dotenv
import os 
import json 

load_dotenv()

# SUPERUSER_USERNAME = os.getenv('SUPERUSER_USERNAME', 'admin')
# SUPERUSER_PASSWORD = os.getenv('SUPERUSER_PASSWORD', 'adminpassword')
# SUPERUSER_EMAIL = os.getenv('SUPERUSER_EMAIL', 'admin@gmail.com')

TEST_USERNAME = "testuser"
TEST_PASSWORD = "testpassword"

User = get_user_model()

def get_or_create_test_user():
    try:
        user = User.objects.get(username=TEST_USERNAME)
        print(f"Using existing test user: {user.username}")
    except User.DoesNotExist:
        user = User.objects.create_user(username=TEST_USERNAME, email="testuser@example.com", password=TEST_PASSWORD)
        print(f"Created test user: {user.username} with password set.")
    return user

class BudgetTests(TestCase):

    def setUp(self):
        self.user = get_or_create_test_user()

        # Create an authentication token for the user
        self.token, created = Token.objects.get_or_create(user=self.user)

        # Set up the API client with token authentication
        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

        # self.superuser, _ = User.objects.get_or_create(
        #     username=SUPERUSER_USERNAME,
        #     email=SUPERUSER_EMAIL,
        #     defaults={'is_superuser': True, 'is_staff': True, 'password': SUPERUSER_PASSWORD}
        # )
        
        # self.superuser.set_password(SUPERUSER_PASSWORD)
        # self.superuser.save()

        # self.token, created = Token.objects.get_or_create(user=self.superuser)

        # self.client = APIClient()
        # self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

        # print(f"Authorization header: Token {self.token.key}")

        super().setUp()
        from setup_data import populate
        populate()

        self.test_budget = Budget.objects.create(
            name="Test March 2025 Budget",
            total_limit=Decimal('1000.00'),
            start_date="2025-03-01",
            end_date="2025-03-31",
            user=self.user
        )
    
    def test_get_all_budgets(self):
        url = reverse('budget-list')
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3) # 2 budgets set up in setup.sh file plus self.test_budget  
        self.assertEqual(response.data[2]['name'], 'Test March 2025 Budget')
        self.assertEqual(str(response.data[2]['total_limit']), '1000.00')
    
    def test_get_budget_by_category(self):
        # Test for getting a specific budget by category name
        url = reverse('budget-by-category', kwargs={'category': 'Test March 2025 Budget'})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Test March 2025 Budget')
        self.assertEqual(str(response.data['total_limit']), '1000.00')

    def test_get_budget_not_found(self):
        # Test for getting a budget that does not exist
        url = reverse('budget-by-category', kwargs={'category': 'Nonexistent Budget'})
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data['detail'], 'Budget not found')

    def test_create_budget(self):
        # Test for creating a new budget
        url = reverse('budget-list')
        data = {
            'name': 'Test April 2025 Budget',
            'total_limit': '5000.00',
            'start_date': '2025-04-01',
            'end_date': '2025-04-30',
            'user': self.user.id
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'Test April 2025 Budget')
        self.assertEqual(str(response.data['total_limit']), '5000.00')

    def test_update_budget(self):
        # Test for updating a budget by category
        url = reverse('budget-by-category', kwargs={'category': 'Test March 2025 Budget'})
        updated_data = {
            'name': 'Updated March 2025 Budget',
            'total_limit': '1500.00',
            'start_date': '2025-03-01',
            'end_date': '2025-03-31'
        }
        response = self.client.put(url, updated_data, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Updated March 2025 Budget')
        self.assertEqual(str(response.data['total_limit']), '1500.00')

    def test_delete_budget(self):
        # Test for deleting a budget by category
        url = reverse('budget-by-category', kwargs={'category': 'Test April 2025 Budget'})
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        with self.assertRaises(Budget.DoesNotExist):
            Budget.objects.get(name='Test April 2025 Budget')

    def test_delete_budget_not_found(self):
        # Test for deleting a budget that does not exist
        url = reverse('budget-by-category', kwargs={'category': 'Nonexistent Budget'})
        response = self.client.delete(url)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data['detail'], 'Budget not found')
