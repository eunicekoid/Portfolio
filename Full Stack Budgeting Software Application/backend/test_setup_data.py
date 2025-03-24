import os
import django
import rest_framework_simplejwt

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "euniceproj.settings")
django.setup()

from django.contrib.auth import get_user_model
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


def test_data():
    user = get_or_create_test_user()

    categories = [
        "Car", "Clothing", "Education", "Financing", "Food", "Fun",
        "Health", "Hobbies", "Home", "Services", "Tech", "Toiletries", "Travel"
    ]
    
    for cat in categories:
        try:
            category, _ = Category.objects.get_or_create(category=cat)
            print(f"Passed - Category '{category.category}' exists for user '{user.username}'.")
        except Category.DoesNotExist:
            print(f"Error: Category '{cat}' does not exist for user '{user.username}'!")

    subcategories = {
        "Car": ["Gas", "Insurance", "Maintenance", "Parking", "Public", "Toll", "Uber"],
        "Clothing": ["Casual", "Gym", "Office"],
        "Education": ["Books", "Career", "Courses", "News Subs"],
        "Financing": ["Loans", "Fees", "Taxes"],
        "Food": ["Groceries", "Meal Delivery", "Restaurants"],
        "Fun": ["Tickets", "Gifts"],
        "Health": ["Dental", "Fitness", "Medical", "Vision"],
        "Hobbies": ["Voice", "Horse-back Riding", "Crochet"],
        "Home": ["Rent", "Rental Insurance", "Utilities", "Internet", "Furniture", "Decor"],
        "Services": ["Facial", "Hair", "Home", "Nails"],
        "Tech": ["Accessories", "Devices", "Phone", "Subscriptions"],
        "Toiletries": ["Bath", "Skincare", "Beauty"],
        "Travel": ["Flights", "Hotels", "Activities", "Food", "Car", "Taxi", "Visa"],
    }

    for category_name, subs in subcategories.items():
        category = Category.objects.filter(category=category_name).first()
        if category:
            for sub_name in subs:
                try:
                    subcategory = Subcategory.objects.filter(
                        subcategory_name=sub_name, 
                        category=category, 
                        user=user
                    ).first()

                    if not subcategory:
                        subcategory = Subcategory.objects.create(
                            subcategory_name=sub_name, 
                            category=category, 
                            user=user
                        )
                        print(f"Created subcategory '{sub_name}' under category '{category.category}' for user '{user.username}'.")
                    else:
                        print(f"Passed - Subcategory '{sub_name}' already exists under category '{category.category}' for user '{user.username}'.")
                    
                except Subcategory.DoesNotExist:
                    print(f"Error: Subcategory '{sub_name}' does not exist under category '{category.category}' for user '{user.username}'!")
        else:
            print(f"Error: Category '{category_name}' does not exist for user '{user.username}'!")

    budgets = ["January Budget", "February Budget"]
    for budget_name in budgets:
        try:
            budget, created = Budget.objects.get_or_create(
                name=budget_name, user=user,
                defaults={"total_limit": 5000.00 if budget_name == "January Budget" else 5500.00,
                          "start_date": "2025-01-01" if budget_name == "January Budget" else "2025-02-01",
                          "end_date": "2025-01-31" if budget_name == "January Budget" else "2025-02-28"}
            )
            print(f"Passed - Budget '{budget.name}' exists for user '{user.username}' with limit ${budget.total_limit:,}.")
        except Budget.DoesNotExist:
            print(f"Error: Budget '{budget_name}' does not exist for user '{user.username}'!")

    transactions = Transaction.objects.filter(user=user)
    if transactions.exists():
        print(f"Passed - Found {transactions.count()} transactions for user '{user.username}'.")
        for transaction in transactions[:10]:  
            currency_info = f"{transaction.currency} {transaction.amount_currency}"
            usd_info = f"USD: ${transaction.amount_usd:.2f}" if transaction.amount_usd else "Error: No USD amount"
            budget_info = f"Budget: {transaction.budget.name}" if transaction.budget else "Error: No associated budget."
            subcategory_info = f"Subcategory: {transaction.subcategory.subcategory_name}" if transaction.subcategory else "Error: No associated subcategory."

            print(f"Transaction: '{transaction.description}', Amount: {currency_info}, {usd_info}, {budget_info}, {subcategory_info}")
    else:
        print(f"Error: No transactions found for user '{user.username}'!")

if __name__ == "__main__":
    test_data()
