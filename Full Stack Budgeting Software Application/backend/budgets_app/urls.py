from django.urls import path
from .views import BudgetView

urlpatterns = [
    path('', BudgetView.as_view(), name='budget-list'),
    path('<str:category>/', BudgetView.as_view(), name='budget-by-category'),
]
