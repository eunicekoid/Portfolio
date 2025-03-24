from django.db import models
from categories_app.models import Category
from django.db.models.signals import pre_delete
from django.dispatch import receiver
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
    
class Subcategory(models.Model):
    subcategory_name = models.CharField(max_length=100)
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name="subcategories")
    user = models.ForeignKey(User, on_delete=models.CASCADE, default=get_default_user)
    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['subcategory_name', 'category', 'user'],
                name='unique_subcategory_per_category_and_user'
            )
        ]


    def __str__(self):
        return f"{self.subcategory_name}"

@receiver(pre_delete, sender=Category)
def handle_category_delete(sender, instance, **kwargs):
    uncategorized_category, created = Category.objects.get_or_create(category="Uncategorized")

    # Check if an "Uncategorized" subcategory already exists under the "Uncategorized" category
    existing_uncategorized_subcategory = Subcategory.objects.filter(
        category=uncategorized_category, 
        subcategory_name="Uncategorized"
    ).first()

    if not existing_uncategorized_subcategory:
        # Create a new "Uncategorized" subcategory if it doesn't exist
        existing_uncategorized_subcategory = Subcategory.objects.create(
            category=uncategorized_category,
            subcategory_name="Uncategorized"
        )

    reassigned_transaction_count = 0
    reassigned_transaction_ids = []

    subcategories = Subcategory.objects.filter(category=instance).exclude(subcategory_name="Uncategorized")
    for subcategory in subcategories:
        transactions = subcategory.transactions.all() 
        for transaction in transactions:
            transaction.subcategory = existing_uncategorized_subcategory
            transaction.save()
            reassigned_transaction_count += 1  
            reassigned_transaction_ids.append(transaction.id) 

        subcategory.delete()

    print(
        f"Reassigned {reassigned_transaction_count} transactions of subcategories in category '{instance.category}' "
        f"to 'Uncategorized'. \n Transaction IDs: {', '.join(map(str, reassigned_transaction_ids))}"
    )
