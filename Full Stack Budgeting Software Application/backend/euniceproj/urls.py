from django.contrib import admin
from django.urls import path, include
from dj_rest_auth.views import LoginView, LogoutView
from dj_rest_auth.registration.views import SocialLoginView
from rest_framework.authtoken.views import obtain_auth_token

urlpatterns = [
    path("admin/", admin.site.urls),
    path('accounts/', include("accounts.urls")),
    path('categories/', include('categories_app.urls')), 
    path('transactions/', include('transactions_app.urls')),
    path('budgets/', include('budgets_app.urls')),
    path('subcategories/', include('subcategories_app.urls')), 
    path('reports/', include('reports_app.urls')),
    path('wolfram/', include('wolfram.urls')),

]