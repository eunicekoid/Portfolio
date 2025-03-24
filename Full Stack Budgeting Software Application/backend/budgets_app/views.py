from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import NotFound
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from .models import Budget
from .serializers import BudgetSerializer
from rest_framework_simplejwt.authentication import JWTAuthentication

class BudgetView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_object(self, category):
        try:
            return Budget.objects.get(name=category)
        except Budget.DoesNotExist:
            raise NotFound(detail="Budget not found", code=404)

    def get(self, request, category=None):
        if category:
            budget = self.get_object(category)
            serializer = BudgetSerializer(budget)
            return Response(serializer.data)
        
        budgets = Budget.objects.all()
        serializer = BudgetSerializer(budgets, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = BudgetSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, category):
        budget = self.get_object(category)
        serializer = BudgetSerializer(budget, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, category):
        budget = self.get_object(category)
        budget.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
