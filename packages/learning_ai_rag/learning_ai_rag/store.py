"""A tiny in-memory vector store designed for inspection in a notebook."""

import numpy as np

from .models import Chunk, Embedder, SearchResult


class InMemoryVectorStore:
    """Keep chunks and normalized embeddings together for cosine retrieval."""

    def __init__(self, chunks: list[Chunk], embeddings: np.ndarray) -> None:
        if not chunks:
            raise ValueError("At least one chunk is required")
        if embeddings.ndim != 2 or len(chunks) != embeddings.shape[0]:
            raise ValueError("The number of embeddings must match the number of chunks")
        self.chunks = chunks
        self.embeddings = _normalize_rows(embeddings)

    @classmethod
    def from_chunks(cls, chunks: list[Chunk], embedder: Embedder) -> "InMemoryVectorStore":
        return cls(chunks, embedder.encode([chunk.text for chunk in chunks]))

    def search(self, query: str, embedder: Embedder, top_k: int = 3) -> list[SearchResult]:
        """Return the highest cosine scores, with the score exposed to the learner."""
        return self.search_by_embedding(embedder.encode([query])[0], top_k=top_k)

    def search_by_embedding(
        self, query_embedding: np.ndarray, top_k: int = 3
    ) -> list[SearchResult]:
        """Return the highest cosine scores for a precomputed query embedding."""
        if top_k <= 0:
            raise ValueError("top_k must be greater than zero")
        query_vector = _normalize_rows(np.asarray([query_embedding]))[0]
        if query_vector.shape[0] != self.embeddings.shape[1]:
            raise ValueError("The query embedding dimension must match the stored embeddings")
        scores = self.embeddings @ query_vector
        positions = np.argsort(-scores)[:top_k]
        return [SearchResult(self.chunks[int(index)], float(scores[index])) for index in positions]


def _normalize_rows(vectors: np.ndarray) -> np.ndarray:
    array = np.asarray(vectors, dtype=np.float64)
    if not np.all(np.isfinite(array)):
        raise ValueError("Embeddings must contain only finite values")
    norms = np.linalg.norm(array, axis=1, keepdims=True)
    if not np.all(np.isfinite(norms)) or np.any(norms == 0):
        raise ValueError("Embeddings must not contain a zero vector")
    return array / norms
