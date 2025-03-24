import os
import django
import random
from datetime import timedelta, datetime
from django.contrib.auth import get_user_model

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "euniceproj.settings")
django.setup()

from transactions_app.models import Transaction
from categories_app.models import Category
from subcategories_app.models import Subcategory
from budgets_app.models import Budget

User = get_user_model()

TEST_USERNAME = "testuser"
TEST_PASSWORD = "testpassword"

def get_or_create_test_user():
    try:
        user = User.objects.get(username=TEST_USERNAME)
        print(f"Using existing test user: {user.username}")
    except User.DoesNotExist:
        user = User.objects.create_user(username=TEST_USERNAME, email="testuser@example.com", password=TEST_PASSWORD)
        print(f"Created test user: {user.username} with password set.")
    return user

def populate():
    user = get_or_create_test_user()

    categories = [
        "Car", "Clothing", "Education", "Financing", "Food", "Fun",
        "Health", "Hobbies", "Home", "Services", "Tech", "Toiletries", "Travel", "Recurring"
    ]

    category_instances = [Category.objects.get_or_create(category=cat)[0] for cat in categories[:-1]]

    subcategories = {
        "Car": ["Gas", "Insurance", "Maintenance", "Parking", "Public", "Toll", "Uber"],
        "Clothing": ["Casual", "Gym", "Office"],
        "Education": ["Books", "Career", "Courses", "News Subs"],
        "Financing": ["Loans", "Fees", "Taxes"],
        "Food": ["Groceries", "Meal Delivery", "Restaurants"],
        "Fun": ["Tickets", "Gifts"],
        "Health": ["Dental", "Fitness", "Medical", "Vision"],
        "Hobbies": ["Voice", "Horse-back Riding", "Crochet"],
        "Home": ["Rental Insurance", "Utilities", "Internet", "Furniture", "Decor"],
        "Services": ["Facial", "Hair", "Home", "Nails"],
        "Tech": ["Accessories", "Devices", "Phone", "Subscriptions"],
        "Toiletries": ["Bath", "Skincare", "Beauty"],
        "Travel": ["Flights", "Hotels", "Activities", "Food", "Car", "Taxi", "Visa"],
        "Recurring": ["Rent"]
    }

    subcategory_instances = []
    for category in category_instances:
        subcategory_names = subcategories.get(category.category, [])
        for sub in subcategory_names:
            subcategory, _ = Subcategory.objects.get_or_create(
                subcategory_name=sub,
                category=category,
                user=user
            )
            subcategory_instances.append(subcategory)

    budgets = [
        Budget.objects.get_or_create(
            name="January Budget",
            user=user,
            defaults={"total_limit": 5000.00, "start_date": datetime(2025, 1, 1), "end_date": datetime(2025, 1, 31)}
        )[0],
        Budget.objects.get_or_create(
            name="February Budget",
            user=user,
            defaults={"total_limit": 5000.00, "start_date": datetime(2025, 2, 1), "end_date": datetime(2025, 2, 28)}
        )[0],
    ]

    # Create rent transactions for January to March 2025
    for month in ["January", "February", "March"]:
        rent_category = Category.objects.get_or_create(category="Recurring")[0]
        rent_subcategory = Subcategory.objects.get_or_create(subcategory_name="Rent", category=rent_category, user=user)[0]
        
        # Rent transactions are valued at 2000
        rent_transaction_date = datetime(2025, ["January", "February", "March"].index(month) + 1, 1)
        Transaction.objects.get_or_create(
            user=user,
            category=rent_category,
            subcategory=rent_subcategory,
            currency="USD",
            amount_currency=2000,
            description=f"{month} Rent",
            date=rent_transaction_date
        )

    for i in range(10):
        category_instance = random.choice(category_instances)
        subcategories_for_category = [sub for sub in subcategory_instances if sub.category == category_instance]
        subcategory_instance = random.choice(subcategories_for_category)

        start_date = datetime(2025, 1, 1)
        end_date = datetime(2025, 2, 28)
        transaction_date = start_date + timedelta(days=random.randint(0, (end_date - start_date).days))

        amount = round(random.uniform(10, 250), 2)

        Transaction.objects.get_or_create(
            user=user,
            category=category_instance,
            subcategory=subcategory_instance,
            currency=random.choice(['USD', 'EUR', 'GBP', 'JPY', 'MYR']),
            amount_currency=amount,
            description=f"Dummy Transaction {i+1}",
            date=transaction_date
        )
    
    # Create additional transactions for March to exceed the budget of 5000
    march_total_expenses = 0
    while march_total_expenses <= 5000:
        category_instance = random.choice(category_instances)
        subcategories_for_category = [sub for sub in subcategory_instances if sub.category == category_instance]
        subcategory_instance = random.choice(subcategories_for_category)

        transaction_date = datetime(2025, 3, 1) + timedelta(days=random.randint(0, 30))
        amount = round(random.uniform(50, 1000), 2)

        # Add transaction and update the total expenses for March
        transaction = Transaction.objects.get_or_create(
            user=user,
            category=category_instance,
            subcategory=subcategory_instance,
            currency=random.choice(['USD', 'EUR', 'GBP', 'JPY', 'MYR']),
            amount_currency=amount,
            description=f"Dummy Transaction for March",
            date=transaction_date
        )[0]
        march_total_expenses += amount

    print("Set up data complete.")

# def clear_existing_data():
#     Transaction.objects.all().delete()
#     Subcategory.objects.all().delete()
#     Category.objects.all().delete()
#     Budget.objects.all().delete()
#     print("Existing data cleared.")


if __name__ == "__main__":
    # clear_existing_data()
    populate()
