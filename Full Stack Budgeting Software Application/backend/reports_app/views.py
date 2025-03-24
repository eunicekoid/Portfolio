from rest_framework.exceptions import NotFound
from transactions_app.models import Transaction
from budgets_app.models import Budget
from categories_app.models import Category
from subcategories_app.models import Subcategory
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)

class OverviewDataView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        transactions = Transaction.objects.filter(user=user)
        budgets = Budget.objects.filter(user=user)

        # Debug log all transactions
        logger.info(f"All transactions: {[f'{t.category.category}: {t.amount_usd} USD ({t.date})' for t in transactions]}")

        monthly_data = {}
        months = []

        # First, set up months and their budgets from the budgets table
        for budget in budgets:
            month_key = budget.start_date.strftime('%Y-%m')
            if month_key not in months:
                months.append(month_key)
            monthly_data[month_key] = {'budget': budget.total_limit}

        # Add any additional months from transactions
        for transaction in transactions:
            month_key = transaction.date.strftime('%Y-%m')
            if month_key not in months:
                months.append(month_key)
                monthly_data[month_key] = {}

        # Handle regular transactions
        for transaction in transactions:
            if transaction.category.category != 'Recurring':  # Skip recurring transactions for now
                month_key = transaction.date.strftime('%Y-%m')
                category_name = transaction.category.category
                logger.info(f"Processing transaction: {category_name} - {transaction.amount_usd} USD for {month_key}")
                
                if category_name in monthly_data[month_key]:
                    monthly_data[month_key][category_name] += transaction.amount_usd
                else:
                    monthly_data[month_key][category_name] = transaction.amount_usd
                logger.info(f"Monthly data after processing: {monthly_data[month_key]}")

        # Get available non-recurring categories
        available_categories = set()
        for transaction in transactions:
            if transaction.category.category != 'Recurring':
                available_categories.add(transaction.category.category)
        filtered_categories = list(available_categories)
        logger.info(f"Available categories: {filtered_categories}")

        # Handle Recurring transactions
        try:
            recurring_category = Category.objects.get(category='Recurring')
            recurring_transactions = Transaction.objects.filter(
                user=user,
                category=recurring_category
            )

            # Process recurring transactions
            for transaction in recurring_transactions:
                month_key = transaction.date.strftime('%Y-%m')
                
                # Initialize Recurring category if not exists
                if 'Recurring' not in monthly_data[month_key]:
                    monthly_data[month_key]['Recurring'] = {}

                subcategory_name = transaction.subcategory.subcategory_name
                if subcategory_name in monthly_data[month_key]['Recurring']:
                    monthly_data[month_key]['Recurring'][subcategory_name] += transaction.amount_usd
                else:
                    monthly_data[month_key]['Recurring'][subcategory_name] = transaction.amount_usd

        except Category.DoesNotExist:
            pass  # No recurring category exists

        months = sorted(list(set(months)))
        logger.info(f"Final monthly_data: {monthly_data}")
        
        return Response({
            'monthly_data': monthly_data,
            'months': months,
            'filtered_categories': filtered_categories
        })
