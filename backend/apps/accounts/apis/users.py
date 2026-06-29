from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from ..models import User, RoleType
from ..serializers import UserSerializer, UserCreateSerializer
from ..permissions import IsAdmin, IsAdminOrTeacher


class UserViewSet(viewsets.ModelViewSet):
    """用户管理 API（管理员管理所有用户，教师查看学生）"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    filterset_fields = ['role', 'is_active']

    def get_serializer_class(self):
        if self.action == 'create':
            return UserCreateSerializer
        return UserSerializer

    def get_permissions(self):
        if self.action in ('create', 'destroy', 'update', 'partial_update'):
            return [IsAdmin()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        qs = User.objects.all()
        if user.role == RoleType.TEACHER:
            # 教师只能查看学生列表
            qs = qs.filter(role=RoleType.STUDENT)
        return qs

    @action(detail=False, methods=['get'])
    def me(self, request):
        """获取当前用户信息"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    @action(detail=False, methods=['patch'])
    def update_me(self, request):
        """更新当前用户信息"""
        serializer = self.get_serializer(
            request.user,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def bind_device(self, request, pk=None):
        """绑定设备标识"""
        user = self.get_object()
        device_id = request.data.get('device_id')
        if not device_id:
            return Response({'error': 'device_id required'}, status=status.HTTP_400_BAD_REQUEST)
        user.device_id = device_id
        user.save()
        return Response({'detail': '设备绑定成功'})
