"""Tests for the terminal walkthrough without downloading models or calling OpenRouter."""

import importlib.util
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "labs" / "01-python-rag-basico" / "rag_basico.py"
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag.models import Chunk, RAGAnswer, SearchResult  # noqa: E402


def _load_script() -> object:
    spec = importlib.util.spec_from_file_location("rag_basico_for_test", SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _prepare_script(module: object, monkeypatch: object) -> None:
    chunk = Chunk("cancel#1", "cancellation-policy.md", "Cancelación", "El pedido puede cancelarse.")
    evidence = (SearchResult(chunk, 0.91),)

    class FakeStore:
        @classmethod
        def from_chunks(cls, chunks: list[Chunk], embedder: object) -> object:
            return object()

    class FakePipeline:
        def __init__(self, store: object, embedder: object) -> None:
            pass

        def answer(self, question: str) -> RAGAnswer:
            return RAGAnswer("[cancel#1] Fuente: cancellation-policy.md\nEl pedido puede cancelarse.", evidence, False)

        def answer_with_generator(self, question: str, generator: object) -> RAGAnswer:
            return RAGAnswer("Respuesta generada con evidencia. [cancel#1]", evidence, False)

    monkeypatch.setattr(module, "load_dotenv", lambda path: False)
    monkeypatch.setattr(module, "load_markdown_documents", lambda path: [])
    monkeypatch.setattr(module, "chunk_documents", lambda documents: [chunk])
    monkeypatch.setattr(module, "SentenceTransformerEmbedder", lambda: object())
    monkeypatch.setattr(module, "InMemoryVectorStore", FakeStore)
    monkeypatch.setattr(module, "RAGPipeline", FakePipeline)


def test_script_runs_the_local_retrieval_walkthrough(monkeypatch: object, capsys: object) -> None:
    module = _load_script()
    _prepare_script(module, monkeypatch)
    monkeypatch.setattr(sys, "argv", [str(SCRIPT)])

    module.main()

    output = capsys.readouterr().out
    assert "Evidencia recuperada" in output
    assert "Para convertir esta evidencia" in output
    assert "Respuesta RAG" not in output


def test_script_generates_when_explicitly_requested(monkeypatch: object, capsys: object) -> None:
    module = _load_script()
    _prepare_script(module, monkeypatch)
    monkeypatch.setattr(module, "OpenRouterAnswerGenerator", lambda: object())
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    monkeypatch.setattr(sys, "argv", [str(SCRIPT), "--generate"])

    module.main()

    output = capsys.readouterr().out
    assert "Evidencia recuperada" in output
    assert "Respuesta RAG" in output
