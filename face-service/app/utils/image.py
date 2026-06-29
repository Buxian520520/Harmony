"""Image processing utilities."""
import io
from typing import Tuple, Optional

import numpy as np
from PIL import Image


def load_image_from_bytes(image_bytes: bytes) -> np.ndarray:
    """Load image bytes into numpy array (RGB)."""
    img = Image.open(io.BytesIO(image_bytes))
    img = img.convert("RGB")
    return np.array(img)


def resize_image(image: np.ndarray, target_size: Tuple[int, int] = (640, 640)) -> np.ndarray:
    """Resize image while maintaining aspect ratio."""
    from PIL import Image
    pil_img = Image.fromarray(image)
    pil_img.thumbnail(target_size, Image.Resampling.LANCZOS)
    return np.array(pil_img)


def normalize_embedding(embedding: np.ndarray) -> np.ndarray:
    """L2 normalize embedding vector."""
    norm = np.linalg.norm(embedding)
    if norm > 0:
        return embedding / norm
    return embedding
