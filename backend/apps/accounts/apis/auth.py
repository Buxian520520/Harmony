from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken

from ..serializers import UserSerializer, RegisterSerializer
from ..models import User


class LoginView(TokenObtainPairView):
    """登录：返回 access_token + refresh_token + 用户信息"""
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            # 附加用户信息
            from django.contrib.auth import authenticate
            username = request.data.get('username')
            password = request.data.get('password')
            user = authenticate(username=username, password=password)
            if user:
                response.data['user'] = UserSerializer(user).data
        return response


class RegisterViewSet(GenericViewSet):
    """注册"""
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            UserSerializer(user).data,
            status=status.HTTP_201_CREATED,
        )


class LogoutView(GenericViewSet):
    """登出（黑名单 refresh token）"""
    permission_classes = [IsAuthenticated]

    def create(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
            return Response({'detail': '已登出'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'detail': '登出失败'}, status=status.HTTP_400_BAD_REQUEST)
