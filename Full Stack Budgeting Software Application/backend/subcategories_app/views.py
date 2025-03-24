from rest_framework import status, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import NotFound
from .models import Subcategory
from categories_app.models import Category
from .serializers import SubcategorySerializer
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication

class SubcategoryView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_object(self, pk):
        try:
            return Subcategory.objects.get(pk=pk)
        except Subcategory.DoesNotExist:
            raise NotFound(detail="Subcategory not found", code=404)

    def get(self, request, pk=None):
        category_id = request.query_params.get('category_id')

        if pk:
            # Retrieve a subcategory by ID
            subcategory = self.get_object(pk)
            serializer = SubcategorySerializer(subcategory)
            return Response(serializer.data)
        
        # List all subcategories, filtered by category_id if provided
        if category_id:
            try:
                category = Category.objects.get(pk=category_id)
                subcategories = Subcategory.objects.filter(category=category)
            except Category.DoesNotExist:
                return Response([], status=status.HTTP_200_OK) # Return empty list if category does not exist.
        else:
            subcategories = Subcategory.objects.all()

        serializer = SubcategorySerializer(subcategories, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = SubcategorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, pk):
        subcategory = self.get_object(pk)
        serializer = SubcategorySerializer(subcategory, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        subcategory = self.get_object(pk)
        subcategory.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
