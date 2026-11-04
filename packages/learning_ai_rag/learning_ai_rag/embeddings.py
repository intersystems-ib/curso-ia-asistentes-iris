"""Embedding adapter used by the local-first labs."""

import numpy as np

from .models import Embedder


DEFAULT_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"


class SentenceTransformerEmbedder(Embedder):
    """Load a multilingual model only when the lab actually needs embeddings."""

    def __init__(self, model_name: str = DEFAULT_MODEL) -> None:
        from sentence_transformers import SentenceTransformer

        self.model_name = model_name
        self._model = SentenceTransformer(model_name)
        self.dimension = int(self._model.get_sentence_embedding_dimension())

    def encode(self, texts: list[str]) -> np.ndarray:
        """Return unit-length vectors so dot product equals cosine similarity."""
        vectors = self._model.encode(texts, convert_to_numpy=True, normalize_embeddings=True)
        array = np.asarray(vectors, dtype=np.float64)
        if not np.all(np.isfinite(array)):
            raise RuntimeError("The embedding model returned non-finite values")
        return array
