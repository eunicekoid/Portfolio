from django.urls import path
from transactions_app.views import TransactionView, RecurringTransactionView

urlpatterns = [
    path('', TransactionView.as_view(), name='transactions-list'),
    path('<int:pk>/', TransactionView.as_view(), name='transaction-by-id'),
    path('date-range/', TransactionView.as_view(), name='transactions-by-date-range'),
    path('transactions/', TransactionView.as_view(), name='transactions'),
    path('transactions/<int:pk>/', TransactionView.as_view(), name='transaction-detail'),
    path('recurring-transactions/', RecurringTransactionView.as_view(), name='recurring-transactions'),
    path('recurring-transactions/<int:pk>/', RecurringTransactionView.as_view(), name='recurring-transaction-detail'),
]

