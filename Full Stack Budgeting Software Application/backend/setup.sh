#!/bin/bash

pip install -r requirements.txt
pip install djangorestframework-simplejwt

apt-get update && apt-get install -y postgresql-client

if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y jq # postgresql-client
else
    yes | brew install jq
fi

echo "Waiting for PostgreSQL to be available..."
until pg_isready -U postgresuser -h db -p 5432; do
  echo "PostgreSQL is unavailable - retrying in 2 seconds..."
  sleep 2
done

python manage.py makemigrations

python manage.py migrate || { 
  python manage.py migrate --noinput; 
}

python setup_data.py

# python test_setup_data.py

# if ! python manage.py db_check_data_exists; then
#   echo "Running data setup..."
#   python setup_data.py
# else
#   echo "Data already exists, skipping setup."
# fi

# python manage.py createsuperuser --noinput --username admin --email admin@gmail.com

# python manage.py shell -c "
# from django.contrib.auth.models import User
# from rest_framework.authtoken.models import Token

# user, created = User.objects.get_or_create(username='admin', email='admin@gmail.com')
# user.set_password('adminpassword')
# user.save()

# token, _ = Token.objects.get_or_create(user=user)
# print(f'Admin Token: {token.key}')
# "

python manage.py runserver 0.0.0.0:8000

