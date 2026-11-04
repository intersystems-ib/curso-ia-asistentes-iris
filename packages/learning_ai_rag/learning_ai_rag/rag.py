"""Retrieval and answer composition for the course's first RAG example."""

from dataclasses import replace
import re
from typing import Protocol, Sequence
import unicodedata

import numpy as np

from .models import Chunk, Embedder, RAGAnswer, SearchResult


class EmbeddingSearchStore(Protocol):
    """Search a vector store using an embedding prepared by the pipeline."""

    def search_by_embedding(
        self, query_embedding: np.ndarray, top_k: int = 3
    ) -> list[SearchResult]:
        """Return the most similar, citeable chunks."""


class AnswerGenerator(Protocol):
    """Generate an answer from a question and explicitly supplied context."""

    def generate(self, question: str, context: str) -> str:
        """Return a concise answer grounded in ``context``."""


class RAGPipeline:
    """Retrieve evidence, expose it, and optionally give it to a generator."""

    def __init__(
        self,
        store: EmbeddingSearchStore,
        embedder: Embedder,
        min_score: float = 0.35,
        *,
        context_chunks: Sequence[Chunk] | None = None,
    ) -> None:
        self.store = store
        self.embedder = embedder
        self.min_score = min_score
        self.context_chunks = (
            {chunk.chunk_id: chunk for chunk in context_chunks}
            if context_chunks is not None
            else None
        )

    def retrieve(self, question: str, top_k: int = 3) -> tuple[SearchResult, ...]:
        """Search fragments, then expose distinct complete sections above the threshold."""
        if top_k <= 0:
            raise ValueError("top_k must be greater than zero")
        query_embedding = self.embedder.encode([question])[0]
        # Several windows may belong to one section; collect candidates before deduplicating.
        results = self.store.search_by_embedding(query_embedding, top_k=top_k * 3)
        candidates: list[SearchResult] = []
        for result in results:
            if result.score < self.min_score:
                continue
            chunk = result.chunk
            if self.context_chunks is not None:
                indexed = self.context_chunks.get(chunk.chunk_id)
                if (
                    indexed is None
                    or indexed.source != chunk.source
                    or indexed.text != chunk.text
                ):
                    raise RuntimeError(
                        "El corpus de IRIS no coincide con los documentos actuales. "
                        "Recarga el Lab 02 con --load antes de continuar."
                    )
                chunk = indexed
            text = chunk.section_text or chunk.text
            candidates.append(SearchResult(replace(chunk, text=text), result.score))
        # Close semantic matches are reranked using document/section headings.
        # Scores exposed to learners remain the original cosine similarities.
        query_terms = _terms(question)

        def ranking(result: SearchResult) -> float:
            headings = re.findall(r"^#{1,6}\s+(.+)$", result.chunk.text, re.MULTILINE)
            matches = query_terms & _terms(" ".join(headings))
            return result.score + 0.05 * len(matches)

        candidates.sort(key=ranking, reverse=True)
        evidence: list[SearchResult] = []
        seen: set[tuple[str, str]] = set()
        for result in candidates:
            chunk = result.chunk
            text = chunk.text
            key = (chunk.source, text)
            if key in seen:
                continue
            seen.add(key)
            evidence.append(result)
            if len(evidence) == top_k:
                break
        return tuple(evidence)

    @staticmethod
    def build_context(evidence: tuple[SearchResult, ...]) -> str:
        """Format retrieved chunks with stable identifiers for a generator."""
        return "\n\n".join(
            f"[{result.chunk.chunk_id}] Fuente: {result.chunk.source}\n{result.chunk.text}"
            for result in evidence
        )

    def answer(self, question: str, top_k: int = 3) -> RAGAnswer:
        """Return the retrieved evidence without calling a language model."""
        evidence = self.retrieve(question, top_k=top_k)
        if not evidence:
            return self._abstention()
        return RAGAnswer(self.build_context(evidence), evidence, abstained=False)

    def answer_with_generator(
        self, question: str, generator: AnswerGenerator, top_k: int = 3
    ) -> RAGAnswer:
        """Generate a grounded answer only after successful retrieval."""
        evidence = self.retrieve(question, top_k=top_k)
        if not evidence:
            return self._abstention()
        answer = generator.generate(question, self.build_context(evidence)).strip()
        if not answer:
            raise RuntimeError("The answer generator returned an empty response")
        return RAGAnswer(answer, evidence, abstained=False)

    @staticmethod
    def _abstention() -> RAGAnswer:
        return RAGAnswer(
            answer=(
                "No encuentro evidencia suficiente en las políticas disponibles. "
                "Prefiero no inventar una respuesta."
            ),
            citations=(),
            abstained=True,
        )


def _terms(text: str) -> set[str]:
    """Small, inspectable lexical signal: accent-insensitive word prefixes, no extra model."""
    plain = "".join(
        char
        for char in unicodedata.normalize("NFD", text.casefold())
        if not unicodedata.combining(char)
    )
    return {word[:5] for word in re.findall(r"[a-z]+", plain) if len(word) >= 4}
