from rest_framework import serializers
from .models import Subcategory
from categories_app.models import Category

class SubcategorySerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(queryset=Category.objects.all())

    class Meta:
        model = Subcategory
        fields = ['id', 'subcategory_name', 'category']
