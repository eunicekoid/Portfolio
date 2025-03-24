from django.urls import path
from .views import SubcategoryView

urlpatterns = [
    path('', SubcategoryView.as_view(), name='subcategory-list'),
    path('<int:pk>/', SubcategoryView.as_view(), name='subcategory-by-id'),
]
