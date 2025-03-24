from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from .models import Category
from transactions_app.models import Transaction
from subcategories_app.models import Subcategory 
from budgets_app.models import Budget
from datetime import datetime
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User
from django.urls import reverse
import os
from dotenv import load_dotenv
import json

load_dotenv()

SUPERUSER_USERNAME = os.getenv('SUPERUSER_USERNAME', 'admin')
SUPERUSER_PASSWORD = os.getenv('SUPERUSER_PASSWORD', 'adminpassword')
SUPERUSER_EMAIL = os.getenv('SUPERUSER_EMAIL', 'admin@gmail.com')

class CategoriesAPITests(TestCase):

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

        super().setUp()
        from setup_data import populate
        populate()

        self.uncat = Category.objects.get(category="Uncategorized")
        self.cat_food = Category.objects.get(category="Food") 
        self.cat_home = Category.objects.get(category="Home")  
        
        self.subcat_uncat = Subcategory.objects.get(subcategory_name="Uncategorized", category=self.uncat)
        self.subcat_groceries = Subcategory.objects.get(subcategory_name="Groceries", category=self.cat_food)
        self.subcat_restaurants = Subcategory.objects.get(subcategory_name="Restaurants", category=self.cat_food)
        self.subcat_rent = Subcategory.objects.get(subcategory_name="Rent", category=self.cat_home)

        self.budget_jan = Budget.objects.get(name="January Budget")
        self.budget_feb = Budget.objects.get(name="February Budget")
        
        self.transaction1 = Transaction.objects.create(
            description="Whole Food Groceries",
            amount_currency=100,
            currency="USD",
            date='2025-01-07',
            category=self.cat_food,
            subcategory=self.subcat_groceries
        )
        self.transaction2 = Transaction.objects.create(
            description="January Rent",
            amount_currency=2000,
            currency="USD",
            date='2025-01-01',
            category=self.cat_home,
            subcategory=self.subcat_rent
        )

        self.transaction3 = Transaction.objects.create(
            description="February Rent",
            amount_currency=2000,
            currency="USD",
            date='2025-02-01',
            category=self.cat_home,
            subcategory=self.subcat_rent
        )

        self.transaction4 = Transaction.objects.create(
            description="Dinner",
            amount_currency=150.99,
            currency="EUR",
            date='2025-01-03',
            category=self.cat_food,
            subcategory=self.subcat_restaurants
        )
    
    def test_get_all_categories(self):
        # Test fetching all categories
        url = reverse('category-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 14)  # 14 categories

    def test_get_single_category(self):
        # Test fetching a single category by name
        url = reverse('single-category', kwargs={'category_name': self.cat_food.category})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()['category_name'], self.cat_food.category)
        self.assertEqual(response.json()['category_id'], self.cat_food.id)

    def test_get_single_category_not_found(self):
        # Test fetching a category that does not exist
        url = reverse('single-category', kwargs={'category_name': 'NonExistentCategory'})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.json()['error'], 'Category not found')

    def test_create_category(self):
        # Test creating a new category
        url = reverse('category-list')
        data = {'category': 'Miscellaneous'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()['message'], 'Category created')

        category = Category.objects.get(category="Miscellaneous")
        self.assertEqual(category.category, "Miscellaneous")

    def test_create_category_invalid_data(self):
        # Test creating a category that already exists
        url = reverse('category-list')
        existing_category_name = "Uncategorized"
        data = {'category': existing_category_name}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('category', response.json()['error'])

    def test_update_category(self):
        # Test updating a category name
        new_name = 'Food & Drink'
        url = reverse('single-category', kwargs={'category_name': self.cat_food.category})
        data = {'category': new_name}
        response = self.client.put(url, data=json.dumps(data), content_type='application/json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()['message'], 'Category updated successfully')

        self.cat_food.refresh_from_db()
        self.assertEqual(self.cat_food.category, new_name)

    def test_update_category_id_conflict(self):
        # Test updating category ID conflict
        cat = self.cat_home.category
        new_id = self.cat_home.id + 1
        url = reverse('single-category', kwargs={'category_name': cat})
        data = {'id': new_id, 'category': cat}
        response = self.client.put(url, data=json.dumps(data), content_type='application/json')
        self.assertEqual(response.json()['error'], 'Category ID already exists')

    def test_delete_category_and_reassign_transactions(self):
        # Ensure transactions linked to a deleted category are reassigned to "Uncategorized" category
        category_to_delete = self.transaction1.category
        self.assertEqual(self.transaction1.category, category_to_delete)

        url = reverse('single-category', kwargs={'category_name': category_to_delete.category})
        response = self.client.delete(url, content_type='application/json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.transaction1.refresh_from_db()
        self.transaction4.refresh_from_db()

        self.assertEqual(self.transaction1.category.category, "Uncategorized")
        self.assertEqual(self.transaction4.category.category, "Uncategorized")

        with self.assertRaises(Category.DoesNotExist):
            category_to_delete.refresh_from_db()