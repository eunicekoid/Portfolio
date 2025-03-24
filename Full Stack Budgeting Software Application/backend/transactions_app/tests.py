from django.test import TestCase
from categories_app.models import Category
from budgets_app.models import Budget
from subcategories_app.models import Subcategory
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework.authtoken.models import Token
from .models import Transaction
from decimal import Decimal
from datetime import datetime
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from unittest.mock import patch, MagicMock
import os
from dotenv import load_dotenv
import json

load_dotenv()

SUPERUSER_USERNAME = os.getenv('SUPERUSER_USERNAME', 'admin')
SUPERUSER_PASSWORD = os.getenv('SUPERUSER_PASSWORD', 'adminpassword')
SUPERUSER_EMAIL = os.getenv('SUPERUSER_EMAIL', 'admin@gmail.com')

class TransactionTest(TestCase):
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

        self.category = Category.objects.create(category="Food")
        self.subcategory = Subcategory.objects.create(subcategory_name="Groceries", category=self.category)
        self.budget = Budget.objects.create(
            name="Test Budget", 
            total_limit=5000.00, 
            start_date="2025-01-01", 
            end_date="2025-12-31"
        )

    def test_get_transactions_sorted_by_date(self):
        transaction1 = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 1",
            date="2025-01-02",
            currency="USD"
        )
        
        transaction2 = Transaction.objects.create(
            amount_currency=Decimal('150.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 2",
            date="2025-02-01",
            currency="USD"
        )

        response = self.client.get('/transactions/')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        
        self.assertEqual(response.data[0]['id'], transaction2.id)  
        self.assertEqual(response.data[1]['id'], transaction1.id)

        all_transactions = Transaction.objects.all()
        self.assertEqual(all_transactions.count(), 2)

    def test_get_transactions_by_date_range(self):
        transaction1 = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 1",
            date="2025-01-02",
            currency="USD"
        )
        
        transaction2 = Transaction.objects.create(
            amount_currency=Decimal('150.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 2",
            date="2025-02-01",
            currency="USD"
        )
        
        transaction3 = Transaction.objects.create(
            amount_currency=Decimal('200.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 3",
            date="2025-03-01",
            currency="USD"
        )
        
        start_date = '2025-01-01'
        end_date = '2025-02-28'
        
        response = self.client.get(f'/transactions/date-range/?start_date={start_date}&end_date={end_date}')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)    
        self.assertTrue(all(start_date <= transaction['date'] <= end_date for transaction in response.data))

        self.assertEqual(response.data[0]['id'], transaction2.id)
        self.assertEqual(response.data[1]['id'], transaction1.id)

    def test_get_transactions_by_date_range_no_data(self):
        transaction1 = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 1",
            date="2025-04-01",
            currency="USD"
        )
        
        start_date = '2025-01-01'
        end_date = '2025-02-01'
        
        response = self.client.get(f'/transactions/date-range/?start_date={start_date}&end_date={end_date}')
              
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data, {'detail': 'No transactions found within the given date range.'})

    def test_create_transaction_with_different_currency(self):
        transaction = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction",
            date="2025-01-02",
            currency="EUR"
        )
        
        transaction.save()
        self.assertEqual(transaction.currency, "EUR")  
        self.assertTrue(transaction.amount_usd > Decimal('100.00'))  
        self.assertEqual(transaction.amount_currency, Decimal('100.00'))  

    def test_create_transaction_usd(self):
        transaction = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test successful transaction",
            date="2025-01-02",
            currency="USD"
        )
        
        transaction.save()

        self.assertEqual(transaction.currency, "USD")  
        self.assertEqual(transaction.amount_currency, Decimal('100.00'))  
        self.assertEqual(transaction.amount_usd, Decimal('100.00'))  
        self.assertEqual(Transaction.objects.count(), 1)
        self.assertEqual(Transaction.objects.first().description, "Test successful transaction")


    def test_create_transaction_invalid_data(self):
        invalid_data = {
            "amount_currency": "invalid_value",  
            "category": self.category.id,
            "subcategory": self.subcategory.id,
            "description": "Test invalid transaction",
            "date": "2025-01-01",
            "currency": "USD"
        }

        response = self.client.post('/transactions/', invalid_data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        self.assertIn('amount_currency', response.data)
        self.assertEqual(response.data['amount_currency'][0], 'A valid number is required.')

        self.assertEqual(Transaction.objects.count(), 0)
   
    
    def test_delete_transaction(self):
        test_transaction = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 1",
            date="2025-01-02",
            currency="USD"
        )

        response = self.client.delete(f'/transactions/{test_transaction.id}/')
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        
        with self.assertRaises(Transaction.DoesNotExist):
            Transaction.objects.get(pk=test_transaction.id)
    
    def test_delete_non_existent_transaction(self):
        response = self.client.delete('/transactions/99999/')  
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_edit_transaction_not_found(self):
        update_data = {
            "amount_currency": Decimal('200.00'),
            "category": self.category.id,
            "subcategory": self.subcategory.id,
            "description": "Non-existent transaction",
            "date": "2025-02-01",
            "currency": "USD"
        }

        response = self.client.put('/transactions/9999/', data=update_data)

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_edit_transaction_invalid_data(self):
        test_transaction = Transaction.objects.create(
            amount_currency=Decimal('100.00'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction 1",
            date="2025-01-02",
            currency="USD"
        )

        invalid_data = {
            "amount_currency": "", 
            "category": self.category.id,
            "subcategory": self.subcategory.id,
            "description": "Invalid transaction",
            "date": "2025-02-01",
            "currency": "USD"
        }

        response = self.client.put(f'/transactions/{test_transaction.id}/', data=invalid_data)
        self.assertIn(response.status_code, [status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, status.HTTP_404_NOT_FOUND, status.HTTP_400_BAD_REQUEST])


    def test_update_transaction(self):
        transaction1 = Transaction.objects.create(
            amount_currency=Decimal('153.88'),
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction",
            date="2025-02-04",
            currency="USD",
        )

        update_data = {
            "amount_currency": 194.92,
            "category": self.category.id,
            "subcategory": self.subcategory.id,
            "description": "Updated description",
            "date": "2025-02-04", 
            "currency": "USD",
            'budget': {"id": self.budget.id }
        }

        response = self.client.put(f'/transactions/{transaction1.id}/', data=update_data, format='json')

        self.assertEqual(response.status_code, 200)
        transaction1.refresh_from_db()  

        self.assertEqual(transaction1.amount_currency, Decimal('194.92'))
        self.assertEqual(transaction1.description, "Updated description")
        self.assertEqual(transaction1.budget.id, self.budget.id)

    @patch('transactions_app.models.Transaction.get_currency_conversion_rate')
    @patch('transactions_app.models.requests.get')
    def test_convert_to_usd_with_wolfram(self, mock_get, mock_conversion_rate):
        mock_conversion_rate.return_value = Decimal('0.0063')  

        mock_wolfram_response = MagicMock()
        mock_wolfram_response.json.return_value = {
            'queryresult': {
                'success': True,
                'pods': [
                    {
                        'title': 'Result',
                        'subpods': [
                            {'plaintext': 'JPY to USD exchange rate is 0.0063'}
                        ]
                    }
                ]
            }
        }
        
        mock_get.return_value = mock_wolfram_response
        
        transaction = Transaction(
            category=self.category,
            subcategory=self.subcategory,
            currency='JPY',
            amount_currency=Decimal('1000'),
            description='Test transaction for JPY to USD',
            date='2025-02-04',
        )
        
        transaction.convert_to_usd()

        mock_conversion_rate.assert_called_once_with('JPY')
        mock_get.assert_called_once()

        self.assertEqual(transaction.amount_usd, Decimal('6.30'))

    def test_evaluate_amount_currency(self):        
        transaction = Transaction.objects.create(
            amount_currency="10+20.10", 
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction",
            date="2025-02-02",
            currency="USD",  
        )

        transaction.save()

        self.assertEqual(transaction.amount_currency, Decimal("30.10"))  
        self.assertEqual(transaction.amount_usd, Decimal("30.10"))  

    def test_evaluate_amount_currency_with_myr(self):
        transaction = Transaction.objects.create(
            amount_currency="10+20.10", 
            category=self.category,
            subcategory=self.subcategory,
            description="Test transaction",
            date="2025-02-02",
            currency="MYR",  
        )

        transaction.save()

        self.assertEqual(transaction.amount_currency, Decimal("30.10"))  
        expected_amount_usd = round(30.10 * 0.2249, 2)
        self.assertEqual(transaction.amount_usd, Decimal(str(expected_amount_usd)).quantize(Decimal('0.01')))

    def test_invalid_expression_in_amount_currency(self):
        with self.assertRaises(ValidationError):
            transaction = Transaction.objects.create(
                amount_currency="invalid_expression",
                category=self.category,
                subcategory=self.subcategory,
                description="Test transaction",
                date="2025-02-02",
                currency="USD",  
            )
    
        # def test_invalid_expression_in_amount_currency(self):
        #     transaction = Transaction.objects.create(
        #         amount_currency="invalid_expression",
        #         category=self.category,
        #         subcategory=self.subcategory,
        #         description="Test transaction",
        #         date="2025-02-02",
        #         currency="USD",  
        #     )
            
        #     self.assertEqual(transaction.amount_currency, Decimal('0.00'))
        #     self.assertEqual(transaction.amount_usd, Decimal('0.00'))