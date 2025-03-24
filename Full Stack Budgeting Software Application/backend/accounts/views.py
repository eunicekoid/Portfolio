from rest_framework.generics import CreateAPIView
from .serializers import SignupSerializer
from django.contrib.auth import authenticate
from rest_framework.views import APIView
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User
from rest_framework_simplejwt.tokens import RefreshToken
from django.middleware.csrf import get_token

class PublicObtainAuthToken(ObtainAuthToken):
    permission_classes = [AllowAny] 
    authentication_classes = []   

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return Response({'error': 'Username and password are required'}, status=status.HTTP_400_BAD_REQUEST)

        user = authenticate(username=username, password=password)

        if user:
            # Generate JWT token
            refresh = RefreshToken.for_user(user)

            response = Response(
                {
                    "message": "Login successful",
                    "access_token": str(refresh.access_token),
                    "refresh_token": str(refresh),
                    "user_id": user.id,
                },
                status=status.HTTP_200_OK,
            )

            # Set CSRF token in cookies
            response.set_cookie("csrftoken", get_token(request), httponly=False)
            return response
        else:
            return Response({"error": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)

        # if user is not None:
        #     # Create or retrieve token for the user
        #     token, created = Token.objects.get_or_create(user=user)
        #     return Response({'message': 'Login successful', 'token': token.key, 'user_id': user.id}, status=status.HTTP_200_OK)
        # else:
        #     return Response({'error': 'Invalid credentials'}, status=status.HTTP_400_BAD_REQUEST)

class SignupView(CreateAPIView):
    queryset = User.objects.all()
    serializer_class = SignupSerializer
    permission_classes = [AllowAny]  

    def perform_create(self, serializer):
        serializer.save()
