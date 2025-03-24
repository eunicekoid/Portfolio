from django.urls import path
from categories_app.views import Categories

urlpatterns = [
    path('', Categories.as_view(), name='category-list'),  
    path('<str:category_name>/', Categories.as_view(), name='single-category'), 

]
