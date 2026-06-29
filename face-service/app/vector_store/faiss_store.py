"""FAISS vector store for face embeddings.
Basic framework - ready for your GitHub code integration.
"""
import os
import pickle
import numpy as np
from app.core.config import settings


class FaissVectorStore:
    """
    FAISS-based vector store for face embeddings.
    
    TODO: When you paste your GitHub code, this may be replaced or extended.
    """

    def __init__(self, dim: int = None):
        self.dim = dim or settings.embedding_dim
        self.index = None
        self.id_map = {}  # face_id → user_id mapping
        self._load()

    def _load(self):
        """Load existing index from disk."""
        path = settings.vector_store_path
        if os.path.exists(path):
            try:
                import faiss
                self.index = faiss.read_index(path)
                map_path = path + ".map"
                if os.path.exists(map_path):
                    with open(map_path, "rb") as f:
                        self.id_map = pickle.load(f)
            except Exception as e:
                print(f"Failed to load index: {e}")
                self._create_index()

        if self.index is None:
            self._create_index()

    def _create_index(self):
        """Create a new FAISS index."""
        try:
            import faiss
            self.index = faiss.IndexFlatIP(self.dim)  # Inner product = cosine sim for normalized vectors
        except ImportError:
            print("FAISS not installed. Install with: pip install faiss-cpu")
            self.index = None

    def add(self, embedding: np.ndarray, face_id: str, user_id: int):
        """Add an embedding to the index."""
        if self.index is None:
            return False
        self.index.add(embedding.reshape(1, -1))
        idx = self.index.ntotal - 1
        self.id_map[str(idx)] = {"face_id": face_id, "user_id": user_id}
        self._save()
        return True

    def search(self, embedding: np.ndarray, top_k: int = 5):
        """Search for top-K similar embeddings."""
        if self.index is None or self.index.ntotal == 0:
            return []
        distances, indices = self.index.search(embedding.reshape(1, -1), top_k)
        results = []
        for dist, idx in zip(distances[0], indices[0]):
            if idx < 0:
                continue
            entry = self.id_map.get(str(idx), {})
            results.append({
                "face_id": entry.get("face_id", ""),
                "user_id": entry.get("user_id", -1),
                "distance": float(dist),
                "confidence": float(dist),  # For normalized vectors, inner product ≈ cosine similarity
            })
        return results

    def remove(self, face_id: str):
        """Remove an embedding by face_id.
        Note: FAISS doesn't support removal by ID natively with IndexFlatIP.
        A full rebuild is needed for production use.
        """
        # TODO: Implement removal (rebuild index without the target)
        pass

    def _save(self):
        """Save index to disk."""
        if self.index is None:
            return
        os.makedirs(os.path.dirname(settings.vector_store_path) or ".", exist_ok=True)
        import faiss
        faiss.write_index(self.index, settings.vector_store_path)
        map_path = settings.vector_store_path + ".map"
        with open(map_path, "wb") as f:
            pickle.dump(self.id_map, f)

    @property
    def size(self) -> int:
        return self.index.ntotal if self.index else 0
