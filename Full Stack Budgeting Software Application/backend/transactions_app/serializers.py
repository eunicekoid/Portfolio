from rest_framework import serializers
from .models import Transaction, RecurringTransaction
from categories_app.models import Category
from subcategories_app.models import Subcategory
from budgets_app.models import Budget
from budgets_app.serializers import BudgetSerializer
from dotenv import load_dotenv
import os
import requests

load_dotenv()

api_key = os.getenv("EXCHANGE_RATE_API_KEY")

class RecurringTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecurringTransaction
        fields = ['id', 'user', 'category', 'subcategory', 'amount_currency', 'currency', 
                 'description', 'start_date', 'end_date', 'frequency', 'day_of_month', 'is_active']
        read_only_fields = ['id', 'is_active']

    def validate(self, data):
        if data['start_date'] > data['end_date']:
            raise serializers.ValidationError("End date must be after start date")
        
        if data['day_of_month'] < 1 or data['day_of_month'] > 31:
            raise serializers.ValidationError("Day of month must be between 1 and 31")
        
        return data

class TransactionSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(queryset=Category.objects.all())
    subcategory = serializers.PrimaryKeyRelatedField(queryset=Subcategory.objects.all(), required=False, allow_null=True)
    budget = BudgetSerializer(required=False)
    recurring_transaction = RecurringTransactionSerializer(read_only=True)

    class Meta:
        model = Transaction
        fields = ['id', 'user', 'category', 'subcategory', 'amount_currency', 'currency', 
                 'description', 'date', 'budget', 'recurring_transaction']
        read_only_fields = ['id']

    def create(self, validated_data):
        budget_data = validated_data.pop('budget', None)
        
        if budget_data:
            budget = Budget.objects.create(**budget_data)
            validated_data['budget'] = budget
            
        return Transaction.objects.create(**validated_data)

    def update(self, instance, validated_data):
        budget_data = validated_data.pop('budget', None)
        
        if budget_data:
            budget_serializer = BudgetSerializer(instance.budget, data=budget_data)
            if budget_serializer.is_valid():
                budget = budget_serializer.save()
                validated_data['budget'] = budget
        
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance

    def to_representation(self, instance):
        from categories_app.serializers import CategorySerializer
        from subcategories_app.serializers import SubcategorySerializer
        from budgets_app.serializers import BudgetSerializer

        representation = super().to_representation(instance)
        representation['category'] = CategorySerializer(instance.category).data
        if instance.subcategory:
            representation['subcategory'] = SubcategorySerializer(instance.subcategory).data
        if instance.budget:
            representation['budget'] = BudgetSerializer(instance.budget).data
        return representation

    def validate(self, data):
        # Ensure that if a budget is provided, the transaction date is within the budget's timeframe
        if 'budget' in data and data['budget'] and 'date' in data:
            budget = data['budget']
            transaction_date = data['date']
            if transaction_date < budget.start_date or transaction_date > budget.end_date:
                raise serializers.ValidationError(
                    "Transaction date must be within the budget's timeframe."
                )

        # Validate that subcategory belongs to the selected category
        if 'category' in data and 'subcategory' in data and data['subcategory']:
            category = data['category']
            subcategory = data['subcategory']
            if subcategory.category.id != category.id:
                raise serializers.ValidationError(
                    f"Subcategory '{subcategory.subcategory_name}' does not belong to category '{category.category}'"
                )

        return data

    supported_currencies = None

    currency_codes = [ # Used in case API quota reached
        "AFN", "ALL", "DZD", "AOA", "ARS", "AMD", "AWG", "AUD", "AZN", "BAM", 
        "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", 
        "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHF", "CLP", "CNY", "COP", 
        "CRC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", 
        "ETB", "EUR", "FJD", "FKP", "FOK", "GBP", "GEL", "GHS", "GIP", "GMD", 
        "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", 
        "INR", "IQD", "IRR", "ISK", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", 
        "KMF", "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", 
        "LSL", "LTL", "LVL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", 
        "MOP", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", 
        "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", 
        "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", 
        "SEK", "SGD", "SHP", "SLL", "SOS", "SPL", "SRD", "SSP", "STN", "SYP", 
        "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", 
        "UAH", "UGX", "USD", "UYU", "UZS", "VEF", "VND", "VUV", "WST", "XAF", 
        "XCD", "XOF", "XPF", "YER", "ZAR", "ZMW", "ZWL"
    ]

    def validate_currency(self, value):
        if not self.supported_currencies:
            try:
                api_url = f"https://v6.exchangerate-api.com/v6/{api_key}/latest/USD"
                response = requests.get(api_url) 

                response.raise_for_status()  
                data = response.json()

                if data.get('result') == 'error' and data.get('error-type') == 'quota-reached':
                    self.supported_currencies = self.currency_codes
                else:
                    self.supported_currencies = data.get('conversion_rates', {}).keys()
            except requests.RequestException:
                self.supported_currencies = self.currency_codes

        if value not in self.supported_currencies:
            raise serializers.ValidationError(f"Currency '{value}' is not supported.")
        return value