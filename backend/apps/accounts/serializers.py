from rest_framework import serializers
from .models import User, RoleType


class UserSerializer(serializers.ModelSerializer):
    """用户基本信息序列化器"""
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'username', 'role', 'role_display', 'phone',
            'avatar', 'face_registered', 'student_id', 'email',
            'date_joined', 'last_login',
        ]
        read_only_fields = ['date_joined', 'last_login', 'face_registered']


class UserCreateSerializer(serializers.ModelSerializer):
    """管理员创建用户序列化器"""
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['username', 'password', 'role', 'phone', 'email', 'student_id']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class RegisterSerializer(serializers.ModelSerializer):
    """学生/教师自助注册序列化器"""
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['username', 'password', 'password_confirm', 'phone', 'email', 'student_id']

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password_confirm'):
            raise serializers.ValidationError('两次密码不一致')
        return attrs

    def create(self, validated_data):
        user = User(
            username=validated_data['username'],
            phone=validated_data.get('phone', ''),
            email=validated_data.get('email', ''),
            student_id=validated_data.get('student_id', ''),
            role=RoleType.STUDENT,  # 默认注册为学生
        )
        user.set_password(validated_data['password'])
        user.save()
        return user
