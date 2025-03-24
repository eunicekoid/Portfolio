from django.urls import path
from .views import SignupView, PublicObtainAuthToken, LoginView

urlpatterns = [
    # path('get-token', PublicObtainAuthToken.as_view()),
    path('signup/', SignupView.as_view(), name='signup'),
    path('login/', LoginView.as_view(), name='login'),
]