from django.db import models
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

class Category(models.Model):
    category = models.CharField(max_length=100, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, default=get_default_user)

    class Meta:
        db_table = 'app_categories'

    def __str__(self):
        return self.category
