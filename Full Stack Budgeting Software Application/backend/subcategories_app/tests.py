from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework.authtoken.models import Token
from .models import Subcategory
from categories_app.models import Category
from decimal import Decimal
from django.urls import reverse
from django.contrib.auth.models import User
from dotenv import load_dotenv
import os 
import json 

load_dotenv()

SUPERUSER_USERNAME = os.getenv('SUPERUSER_USERNAME', 'admin')
SUPERUSER_PASSWORD = os.getenv('SUPERUSER_PASSWORD', 'adminpassword')
SUPERUSER_EMAIL = os.getenv('SUPERUSER_EMAIL', 'admin@gmail.com')

class SubcategoryTests(APITestCase):
    
    def setUp(self):
        self.superuser, _ = User.objects.get_or_create(
            username=SUPERUSER_USERNAME,
            email=SUPERUSER_EMAIL,
            defaults={'is_superuser': True, 'is_staff': True, 'password': SUPERUSER_PASSWORD}
        )
        
        self.superuser.set_password(SUPERUSER_PASSWORD)
        self.superuser.save()

        self.token, created = Token.objects.get_or_create(user=self.superuser)

        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

        self.category = Category.objects.create(category="Test Category")
        self.subcategory = Subcategory.objects.create(
            subcategory_name="Test Subcategory",
            category=self.category
        )
        self.url = '/subcategories/'

    def test_create_subcategory(self):
        data = {
            "subcategory_name": "New Subcategory",
            "category": self.category.id
        }
        response = self.client.post(
            reverse('subcategory-list'), 
            data=json.dumps(data), 
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['subcategory_name'], "New Subcategory")

    def test_list_subcategories(self):
        response = self.client.get(reverse('subcategory-list')) 
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  

    def test_retrieve_subcategory(self):
        response = self.client.get(reverse('subcategory-by-id', kwargs={'pk': self.subcategory.id})) 
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['subcategory_name'], self.subcategory.subcategory_name)

    def test_update_subcategory(self):
        update_data = {
            "subcategory_name": "Updated Subcategory",
            "category": self.category.id
        }
        response = self.client.put(
            reverse('subcategory-by-id', kwargs={'pk': self.subcategory.id}), 
            data=json.dumps(update_data), 
            content_type='application/json'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['subcategory_name'], "Updated Subcategory")

    def test_delete_subcategory(self):
        response = self.client.delete(reverse('subcategory-by-id', kwargs={'pk': self.subcategory.id})) 
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        with self.assertRaises(Subcategory.DoesNotExist):
            Subcategory.objects.get(id=self.subcategory.id)

    def test_delete_non_existent_subcategory(self):
        response = self.client.delete(reverse('subcategory-by-id', kwargs={'pk': 99999})) 
        self.assertIn(response.status_code, [status.HTTP_404_NOT_FOUND, status.HTTP_204_NO_CONTENT])