from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.response import Response
from rest_framework import status
from .models import Transaction, RecurringTransaction
from budgets_app.models import Budget
from .serializers import TransactionSerializer, RecurringTransactionSerializer
from budgets_app.serializers import BudgetSerializer
from rest_framework.exceptions import NotFound
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.db import transaction

class RecurringTransactionView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        recurring_transactions = RecurringTransaction.objects.filter(
            user=request.user,
            is_active=True
        )
        serializer = RecurringTransactionSerializer(recurring_transactions, many=True)
        return Response(serializer.data)

    def post(self, request):
        # Add user to the data
        data = request.data.copy()
        data['user'] = request.user.id

        serializer = RecurringTransactionSerializer(data=data)
        if serializer.is_valid():
            with transaction.atomic():
                # Save the recurring transaction
                recurring_transaction = serializer.save()

                # Create all future transactions up to the end date
                current_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
                end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
                day_of_month = data['day_of_month']

                while current_date <= end_date:
                    # Adjust the day of month if it exceeds the month's last day
                    try:
                        transaction_date = current_date.replace(day=day_of_month)
                    except ValueError:
                        # If day is invalid (e.g., 31 in a 30-day month), use last day
                        next_month = current_date.replace(day=1) + relativedelta(months=1)
                        transaction_date = next_month - timedelta(days=1)

                    if transaction_date >= current_date and transaction_date <= end_date:
                        Transaction.objects.create(
                            user=request.user,
                            category=recurring_transaction.category,
                            subcategory=recurring_transaction.subcategory,
                            amount_currency=recurring_transaction.amount_currency,
                            currency=recurring_transaction.currency,
                            description=recurring_transaction.description,
                            date=transaction_date,
                            recurring_transaction=recurring_transaction
                        )

                    # Move to next occurrence based on frequency
                    if data['frequency'] == 'monthly':
                        current_date = current_date + relativedelta(months=1)
                    elif data['frequency'] == 'quarterly':
                        current_date = current_date + relativedelta(months=3)
                    else:  # yearly
                        current_date = current_date + relativedelta(years=1)

            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        try:
            recurring_transaction = RecurringTransaction.objects.get(pk=pk, user=request.user)
        except RecurringTransaction.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        with transaction.atomic():
            # Delete future transactions
            future_transactions = Transaction.objects.filter(
                recurring_transaction=recurring_transaction,
                date__gte=datetime.now().date()
            )
            future_transactions.delete()

            # Mark recurring transaction as inactive
            recurring_transaction.is_active = False
            recurring_transaction.save()

        return Response(status=status.HTTP_204_NO_CONTENT)

class TransactionView(APIView):
    authentication_classes = [JWTAuthentication] 
    permission_classes = [IsAuthenticated]

    def get(self, request, pk=None):
        # Handle transaction by primary key if ID (pk) is provided
        if pk:
            try:
                transaction = Transaction.objects.get(pk=pk)
                serializer = TransactionSerializer(transaction)
                return Response(serializer.data, status=status.HTTP_200_OK)
            except Transaction.DoesNotExist:
                return Response({"detail": "Transaction not found"}, status=status.HTTP_404_NOT_FOUND)

        # Handle transactions with optional date range filters
        start_date_str = request.query_params.get('start_date')
        end_date_str = request.query_params.get('end_date')

        if start_date_str and end_date_str:
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
            except ValueError:
                return Response(
                    {"detail": "Invalid date format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            transactions = Transaction.objects.filter(
                user=request.user,
                date__gte=start_date,
                date__lte=end_date
            ).order_by('-date')

            if not transactions.exists():
                return Response(
                    {"detail": "No transactions found within the given date range."},
                    status=status.HTTP_404_NOT_FOUND
                )

            serializer = TransactionSerializer(transactions, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        # If no date filters are applied, get all transactions
        transactions = Transaction.objects.filter(user=request.user).order_by('-date')
        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        # Add user to the data
        data = request.data.copy()
        data['user'] = request.user.id

        serializer = TransactionSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, request, pk):
        try:
            transaction = Transaction.objects.get(pk=pk, user=request.user)
        except Transaction.DoesNotExist:
            return Response({"detail": "Transaction not found."}, status=status.HTTP_404_NOT_FOUND)

        if 'budget' in request.data:
            budget_data = request.data['budget']
            if isinstance(budget_data, dict):
                budget_id = budget_data.get('id')
                if budget_id:
                    try:
                        budget = Budget.objects.get(id=budget_id)
                        request.data['budget'] = budget.id  
                    except Budget.DoesNotExist:
                        return Response({"detail": "Budget not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = TransactionSerializer(transaction, data=request.data, partial=False)

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, pk):
        try:
            transaction = Transaction.objects.get(pk=pk, user=request.user)
        except Transaction.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
        
        transaction.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)