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

##################################################################################################
### For AWS ######################################################################################
##################################################################################################
# #!/bin/bash

# # Enable command printing and exit on error
# set -ex

# echo "Starting setup script..."
# echo "Environment variables check:"
# echo "POSTGRES_HOST: ${POSTGRES_HOST}"
# echo "POSTGRES_USER: ${POSTGRES_USER}"
# echo "POSTGRES_DB: ${POSTGRES_DB}"
# echo "DJANGO_SETTINGS_MODULE: ${DJANGO_SETTINGS_MODULE}"

# echo "Installing requirements..."
# pip install -r requirements.txt
# pip install djangorestframework-simplejwt

# echo "Installing PostgreSQL client..."
# apt-get update && apt-get install -y postgresql-client

# echo "Checking PostgreSQL connection..."
# export PGPASSWORD=${POSTGRES_PASSWORD}
# max_retries=30
# retry_count=0

# until pg_isready -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB}; do
#     retry_count=$((retry_count+1))
#     if [ $retry_count -eq $max_retries ]; then
#         echo "Failed to connect to PostgreSQL after $max_retries attempts"
#         exit 1
#     fi
#     echo "PostgreSQL is unavailable - sleeping (attempt $retry_count/$max_retries)"
#     sleep 5
# done

# echo "PostgreSQL connection successful!"

# echo "Running migrations..."
# python manage.py makemigrations
# python manage.py migrate

# echo "Setting up initial data..."
# if [ -f setup_data.py ]; then
#     python setup_data.py
# else
#     echo "setup_data.py not found, skipping initial data setup"
# fi

# echo "Starting Django server..."
# exec python manage.py runserver 0.0.0.0:8000

