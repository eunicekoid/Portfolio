from rest_framework import serializers
from .models import Budget
from datetime import datetime

class BudgetSerializer(serializers.ModelSerializer):
    start_date = serializers.DateField()  
    end_date = serializers.DateField() 

    class Meta:
        model = Budget
        fields = ['id', 'name', 'total_limit', 'start_date', 'end_date']

    def validate_start_date(self, value):
        end_date_str = self.initial_data.get('end_date')
        if end_date_str:
            try:
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                raise serializers.ValidationError("Invalid date format for end_date. Use YYYY-MM-DD.")
            
            if value > end_date:
                raise serializers.ValidationError("Start date cannot be after end date.")
        
        return value

    def validate_end_date(self, value):
        start_date_str = self.initial_data.get('start_date')
        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
            except ValueError:
                raise serializers.ValidationError("Invalid date format for start_date. Use YYYY-MM-DD.")
            
            if value < start_date:
                raise serializers.ValidationError("End date cannot be before start date.")
        
        return value