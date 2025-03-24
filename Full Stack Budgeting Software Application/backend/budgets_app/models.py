from django.db import models
from django.utils import timezone
from datetime import date, timedelta 
from django.contrib.auth.models import User 
from django.contrib.auth import get_user_model

User = get_user_model()

def get_default_user():
    User = get_user_model()
    try:
        user = User.objects.get(username="testuser")
    except User.DoesNotExist:
        user = User.objects.create_user(
            username="testuser", password="testpassword", email="testuser@example.com"
        )
    return user.id

def default_end_date():
    return timezone.now() + timedelta(days=30)

class Budget(models.Model):
    name = models.CharField(max_length=100, default="No Budget Assigned")
    total_limit = models.DecimalField(max_digits=10, decimal_places=2, default=5000)
    start_date = models.DateField(default=timezone.now)  
    end_date = models.DateField(default=default_end_date) 
    user = models.ForeignKey(User, on_delete=models.CASCADE, default=get_default_user) 

    class Meta:
        db_table = 'app_budgets'

    def __str__(self):
        return f"{self.name}"
