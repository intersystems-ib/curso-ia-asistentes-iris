"""Tests for the persistent RAG terminal walkthrough without IRIS or OpenRouter."""

import importlib.util
from pathlib import Path
import sys

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "labs" / "02-sql-vector-search" / "vector_search.py"
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag.models import Chunk, RAGAnswer, SearchResult  # noqa: E402


def _load_script() -> object:
    spec = importlib.util.spec_from_file_location("vector_search_for_test", SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _prepare_script(module: object, monkeypatch: object) -> None:
    chunk = Chunk("returns#1", "returns-policy.md", "Devoluciones", "Puedes devolver el producto.")
    evidence = (SearchResult(chunk, 0.91),)

    class FakeEmbedder:
        dimension = 384

        def encode(self, texts: list[str]) -> np.ndarray:
            return np.ones((len(texts), 384))

    class FakeSettings:
        @classmethod
        def from_environment(cls) -> object:
            return object()

    class FakeStore:
        def initialize(self) -> None:
            pass

        def replace_chunks(self, chunks: list[Chunk], embeddings: np.ndarray) -> None:
            pass

    class FakeIrisVectorStore:
        @staticmethod
        def connect(settings: object) -> FakeStore:
            return FakeStore()

    class FakePipeline:
        def __init__(self, store: object, embedder: object, **kwargs: object) -> None:
            pass

        def answer(self, question: str) -> RAGAnswer:
            return RAGAnswer("[returns#1] Fuente: returns-policy.md\nPuedes devolver el producto.", evidence, False)

        def answer_with_generator(self, question: str, generator: object) -> RAGAnswer:
            return RAGAnswer("Respuesta generada con evidencia. [returns#1]", evidence, False)

    monkeypatch.setattr(module, "load_dotenv", lambda path: False)
    monkeypatch.setattr(module, "load_markdown_documents", lambda path: [])
    monkeypatch.setattr(module, "chunk_documents", lambda documents: [chunk])
    monkeypatch.setattr(module, "SentenceTransformerEmbedder", FakeEmbedder)
    monkeypatch.setattr(module, "IrisConnectionSettings", FakeSettings)
    monkeypatch.setattr(module, "IrisVectorStore", FakeIrisVectorStore)
    monkeypatch.setattr(module, "RAGPipeline", FakePipeline)


def test_script_runs_the_iris_retrieval_walkthrough(monkeypatch: object, capsys: object) -> None:
    module = _load_script()
    _prepare_script(module, monkeypatch)
    monkeypatch.setattr(sys, "argv", [str(SCRIPT), "--initialize", "--load"])

    module.main()

    output = capsys.readouterr().out
    assert "Tabla e índice HNSW creados" in output
    assert "Evidencia recuperada desde IRIS" in output
    assert "Para convertir esta evidencia" in output


def test_script_generates_from_iris_evidence_when_requested(monkeypatch: object, capsys: object) -> None:
    module = _load_script()
    _prepare_script(module, monkeypatch)
    monkeypatch.setattr(module, "OpenRouterAnswerGenerator", lambda: object())
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    monkeypatch.setattr(sys, "argv", [str(SCRIPT), "--generate"])

    module.main()

    output = capsys.readouterr().out
    assert "Evidencia recuperada desde IRIS" in output
    assert "Respuesta RAG" in output
