from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Category
from .serializers import CategorySerializer 
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication

class Categories(APIView):
    permission_classes = [IsAuthenticated]
    authentication_classes = [JWTAuthentication]


    def get(self, request, category_name=None):
        if category_name:
            # Single category fetch by name
            try:
                category = Category.objects.get(category=category_name)
                return Response({'category_id': category.id, 'category_name': category.category})
            except Category.DoesNotExist:
                return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            # Fetch all categories
            categories = Category.objects.all().order_by('category')
            serializer = CategorySerializer(categories, many=True)
            return Response(serializer.data)

    
    def post(self, request):
        # Create a new category
        serializer = CategorySerializer(data=request.data)
        
        if serializer.is_valid():
            category = serializer.save()
            return Response({
                "message": "Category created",
                "category_id": category.id,
                "category_name": category.category  
            }, status=status.HTTP_201_CREATED)
        
        return Response({"error": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, category_name):
        # Update a category
        try:
            category = Category.objects.get(category=category_name)
        except Category.DoesNotExist:
            return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)
        
        new_id = request.data.get('id')
        
        if new_id and new_id != category.id:
            if Category.objects.filter(id=new_id).exists():
                return Response({'error': 'Category ID already exists'}, status=status.HTTP_400_BAD_REQUEST)
            
            category.id = new_id  

        new_category_name = request.data.get('category')
        if new_category_name and new_category_name != category.category:
            category.category = new_category_name  

        serializer = CategorySerializer(category, data=request.data, partial=True)  
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Category updated successfully',
                'category_id': category.id,
                'category_name': category.category
            }, status=status.HTTP_200_OK)
        
        return Response({'error': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, category_name):
        # Delete a category
        try:
            category = Category.objects.get(category=category_name)
        except Category.DoesNotExist:
            return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)

        category.delete()
        return Response({
            'message': 'Category deleted successfully',
            'category_id': category.id,
            'category_name': category.category
        }, status=status.HTTP_200_OK)
