from django.db import models
from django.conf import settings


class FaceImage(models.Model):
    """用户上传的人脸图片"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='face_images',
        verbose_name='用户',
    )
    image = models.ImageField(upload_to='face_images/', verbose_name='人脸图片')
    uploaded_at = models.DateTimeField(auto_now_add=True, verbose_name='上传时间')
    is_active = models.BooleanField(default=True, verbose_name='是否启用')

    class Meta:
        verbose_name = '人脸图片'
        verbose_name_plural = '人脸图片'
        ordering = ['-uploaded_at']

    def __str__(self):
        return f'{self.user.username} - {self.uploaded_at.strftime("%Y-%m-%d")}'


class FaceEmbedding(models.Model):
    """人脸特征向量（由推理服务生成）"""
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='face_embedding',
        verbose_name='用户',
    )
    face_image = models.ForeignKey(
        FaceImage,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name='来源图片',
    )
    embedding_id = models.CharField(max_length=64, verbose_name='推理服务中的向量ID')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='最后更新')

    class Meta:
        verbose_name = '人脸特征'
        verbose_name_plural = '人脸特征'

    def __str__(self):
        return f'{self.user.username} 人脸特征'
