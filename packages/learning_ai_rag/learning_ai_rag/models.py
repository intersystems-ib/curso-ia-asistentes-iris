"""Small immutable data structures used by the RAG labs."""

from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class Document:
    """A source document before splitting it into chunks."""

    source: str
    title: str
    text: str


@dataclass(frozen=True)
class Chunk:
    """An indexed passage, optionally retaining its complete source section for context."""

    chunk_id: str
    source: str
    title: str
    text: str
    section_text: str = ""


@dataclass(frozen=True)
class SearchResult:
    """A chunk returned by similarity search."""

    chunk: Chunk
    score: float


@dataclass(frozen=True)
class RAGAnswer:
    """An answer with its supporting passages, or an explicit abstention."""

    answer: str
    citations: tuple[SearchResult, ...]
    abstained: bool


class Embedder:
    """Protocol-like base class kept dependency-free for lab tests."""

    dimension: int

    def encode(self, texts: list[str]) -> np.ndarray:
        """Return one normalized embedding per input text."""
        raise NotImplementedError
