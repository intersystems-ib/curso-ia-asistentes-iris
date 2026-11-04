"""Explainable, local-first RAG components for the course labs."""

from .embeddings import SentenceTransformerEmbedder
from .evaluation import evaluate_cases, load_rag_cases
from .ingest import load_markdown_documents
from .openrouter_generator import DEFAULT_MODEL, OPENROUTER_BASE_URL, OpenRouterAnswerGenerator
from .rag import RAGPipeline
from .store import InMemoryVectorStore

__all__ = [
    "DEFAULT_MODEL",
    "OPENROUTER_BASE_URL",
    "InMemoryVectorStore",
    "OpenRouterAnswerGenerator",
    "RAGPipeline",
    "SentenceTransformerEmbedder",
    "evaluate_cases",
    "load_markdown_documents",
    "load_rag_cases",
]
