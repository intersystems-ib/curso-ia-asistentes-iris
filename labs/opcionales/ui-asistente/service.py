"""Shared, read-only RAG service for the optional web interfaces."""

from dataclasses import dataclass
from functools import lru_cache
import os
from pathlib import Path
import sys

from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag import (  # noqa: E402
    OpenRouterAnswerGenerator,
    RAGPipeline,
    SentenceTransformerEmbedder,
)
from learning_ai_rag.ingest import chunk_documents, load_markdown_documents  # noqa: E402
from learning_ai_rag.iris_vector import IrisConnectionSettings, IrisVectorStore  # noqa: E402
from learning_ai_rag.models import RAGAnswer  # noqa: E402


@dataclass(frozen=True)
class ChatResult:
    """A UI-friendly RAG result with answer text and traceable citations."""

    answer: str
    citations: tuple[dict[str, object], ...]
    abstained: bool
    generated: bool


def _citations(answer: RAGAnswer) -> tuple[dict[str, object], ...]:
    # Convert course models into plain JSON-friendly data for both UI and API.
    return tuple(
        {
            "source": result.chunk.source,
            "chunk_id": result.chunk.chunk_id,
            "score": round(result.score, 3),
            "text": result.chunk.text,
        }
        for result in answer.citations
    )


@lru_cache(maxsize=1)
def get_pipeline() -> RAGPipeline:
    """Connect to the Lab 02 corpus once per web-process lifetime."""
    # Use the same local connection settings as the terminal RAG labs.
    load_dotenv(ROOT / ".env")
    embedder = SentenceTransformerEmbedder()
    if embedder.dimension != 384:
        raise RuntimeError("La UI necesita embeddings de 384 dimensiones.")
    store = IrisVectorStore.connect(IrisConnectionSettings.from_environment())
    # The UI is read-only: Lab 02 must have created the table, index, and corpus.
    store.check_ready()
    chunks = chunk_documents(load_markdown_documents(ROOT / "datos-demo" / "knowledge"))
    return RAGPipeline(store, embedder, context_chunks=chunks)


def ask(question: str, generate: bool = False) -> ChatResult:
    """Retrieve policy evidence and optionally generate a grounded answer."""
    question = question.strip()
    if not question:
        raise ValueError("Escribe una pregunta antes de enviarla.")

    # get_pipeline() is cached, so model loading and the IRIS preflight happen once.
    pipeline = get_pipeline()
    evidence = pipeline.answer(question)
    if evidence.abstained:
        # Do not call a model when retrieval could not support an answer.
        return ChatResult(evidence.answer, (), abstained=True, generated=False)

    if not generate:
        # Keep retrieval inspectable before introducing a cloud-generated answer.
        return ChatResult(
            "He recuperado evidencia relevante. Ábrela debajo para revisarla. "
            "Si quieres una respuesta redactada, activa «Generar con OpenRouter».",
            _citations(evidence),
            abstained=False,
            generated=False,
        )

    if not os.environ.get("OPENROUTER_API_KEY"):
        raise RuntimeError(
            "Para generar la respuesta define OPENROUTER_API_KEY en .env y reinicia la aplicación. "
            "La evidencia local ya está disponible."
        )
    # The generator receives only the context assembled from retrieved chunks.
    generated = pipeline.answer_with_generator(
        question,
        OpenRouterAnswerGenerator(),
    )
    return ChatResult(generated.answer, _citations(generated), abstained=False, generated=True)
