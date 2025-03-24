from django.db import models
from django.conf import settings
from django.dispatch import receiver
from django.db.models.signals import pre_delete
from django.db import transaction
from categories_app.models import Category
from subcategories_app.models import Subcategory
from budgets_app.models import Budget
import requests
from decimal import Decimal, InvalidOperation
from dotenv import load_dotenv
from datetime import date, timedelta
from django.utils import timezone
import os
import re
from django.contrib.auth.models import User 
from django.contrib.auth import get_user_model

def get_default_user():
    User = get_user_model()
    try:
        user = User.objects.get(username="testuser")
    except User.DoesNotExist:
        user = User.objects.create_user(
            username="testuser", password="testpassword", email="testuser@example.com"
        )
    return user.id
load_dotenv()

WOLFRAM_APP_ID = os.getenv("WOLFRAM_APP_ID")

currency_to_usd = { # Used in case Exchange Rate API limit is reached
    "USD": 1.00,  # US Dollar
    "EUR": 1.03,  # Euro
    "JPY": 0.0063,  # Japanese Yen
    "GBP": 1.22,  # British Pound
    "AUD": 0.61,  # Australian Dollar
    "CAD": 0.71,  # Canadian Dollar
    "CHF": 1.09,  # Swiss Franc
    "CNY": 0.14,  # Chinese Yuan
    "INR": 0.012,  # Indian Rupee
    "MXN": 0.048,  # Mexican Peso
    "MYR": 0.222292,  # Malaysian Ringgit
}

class RecurringTransaction(models.Model):
    FREQUENCY_CHOICES = [
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, default=get_default_user)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    subcategory = models.ForeignKey(Subcategory, on_delete=models.CASCADE)
    amount_currency = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    description = models.CharField(max_length=200)
    start_date = models.DateField()
    end_date = models.DateField()
    frequency = models.CharField(max_length=10, choices=FREQUENCY_CHOICES, default='monthly')
    day_of_month = models.IntegerField()  # Day of the month when transaction should occur
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'app_recurring_transactions'

    def __str__(self):
        return f"{self.description} - {self.amount_currency} {self.currency} ({self.frequency})"

class Transaction(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, default=get_default_user)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    subcategory = models.ForeignKey(Subcategory, on_delete=models.CASCADE)
    amount_currency = models.DecimalField(max_digits=10, decimal_places=2)
    amount_usd = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    description = models.CharField(max_length=200)
    date = models.DateField()
    budget = models.ForeignKey(Budget, on_delete=models.SET_NULL, null=True, blank=True)
    recurring_transaction = models.ForeignKey(RecurringTransaction, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'app_transactions'

    def __str__(self):
        return f"{self.description} - {self.amount_currency} {self.currency}"

    def save(self, *args, **kwargs):
        if self.currency == 'USD':
            self.amount_usd = self.amount_currency
        else:
            # Convert to USD using exchange rate API
            api_key = os.getenv('EXCHANGE_RATE_API_KEY')
            url = f'https://v6.exchangerate-api.com/v6/{api_key}/pair/{self.currency}/USD/{self.amount_currency}'
            
            try:
                response = requests.get(url)
                data = response.json()
                self.amount_usd = Decimal(str(data['conversion_result']))
            except Exception as e:
                print(f"Error converting currency: {e}")
                self.amount_usd = self.amount_currency  # Fallback to original amount
                
        super().save(*args, **kwargs)

@receiver(pre_delete, sender=Category)
def handle_category_delete(sender, instance, **kwargs):
    uncategorized_category, created = Category.objects.get_or_create(category="Uncategorized")

    # Reassign all transactions associated with this category to the "Uncategorized" category
    with transaction.atomic():
        Transaction.objects.filter(category=instance).update(category=uncategorized_category)
