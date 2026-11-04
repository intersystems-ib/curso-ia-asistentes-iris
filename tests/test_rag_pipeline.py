from pathlib import Path
import sys
from types import SimpleNamespace

import pytest

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag.ingest import chunk_documents  # noqa: E402
from learning_ai_rag.iris_vector import (  # noqa: E402
    CLASS_NAME,
    INDEX_NAME,
    TABLE_NAME,
    IrisVectorStore,
)
from learning_ai_rag.models import Chunk, Document, Embedder, SearchResult  # noqa: E402
from learning_ai_rag.openrouter_generator import OpenRouterAnswerGenerator  # noqa: E402
from learning_ai_rag.rag import RAGPipeline  # noqa: E402
from learning_ai_rag.store import InMemoryVectorStore  # noqa: E402


class FixedEmbedder(Embedder):
    dimension = 2

    def encode(self, texts: list[str]) -> np.ndarray:
        mapping = {
            "cancel": [1.0, 0.0],
            "garantia": [0.0, 1.0],
            "tarjeta": [-1.0, 0.0],
            "El pedido Processing puede cancelarse.": [1.0, 0.0],
            "La garantia cubre defectos de fabricacion.": [0.0, 1.0],
        }
        return np.asarray([mapping[text] for text in texts], dtype=np.float64)


class RecordingGenerator:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []

    def generate(self, question: str, context: str) -> str:
        self.calls.append((question, context))
        return "Puedes cancelar el pedido mientras esté en Processing. [cancel#1]"


class FakeCompletions:
    def __init__(self) -> None:
        self.request: dict[str, object] | None = None

    def create(self, **kwargs: object) -> object:
        self.request = kwargs
        return SimpleNamespace(
            choices=[
                SimpleNamespace(
                    message=SimpleNamespace(
                        content="Respuesta basada en evidencia. [cancel#1]"
                    )
                )
            ]
        )


class FakeOpenRouterClient:
    def __init__(self) -> None:
        self.chat = SimpleNamespace(completions=FakeCompletions())


class RecordingVectorStore:
    def __init__(self, result: SearchResult) -> None:
        self.result = result
        self.query_embedding: np.ndarray | None = None

    def search_by_embedding(
        self, query_embedding: np.ndarray, top_k: int = 3
    ) -> list[SearchResult]:
        self.query_embedding = query_embedding
        return [self.result]


class FakeCursor:
    def __init__(
        self, rows: list[tuple[int, ...]], first_execute_error: Exception | None = None
    ) -> None:
        self.rows = rows
        self.first_execute_error = first_execute_error
        self.executions: list[tuple[str, list[str] | None]] = []

    def execute(self, query: str, parameters: list[str] | None = None) -> None:
        self.executions.append((query, parameters))
        if self.first_execute_error is not None and len(self.executions) == 1:
            raise self.first_execute_error

    def fetchone(self) -> tuple[int, ...]:
        return self.rows.pop(0)

    def close(self) -> None:
        pass


class FakeConnection:
    def __init__(self, cursor: FakeCursor) -> None:
        self._cursor = cursor

    def cursor(self) -> FakeCursor:
        return self._cursor


def test_pipeline_returns_a_citation_for_supported_question() -> None:
    chunks = [
        Chunk(
            "cancel#1",
            "cancellation-policy.md",
            "Cancelación",
            "El pedido Processing puede cancelarse.",
        ),
        Chunk(
            "warranty#1",
            "warranty-policy.md",
            "Garantía",
            "La garantia cubre defectos de fabricacion.",
        ),
    ]
    pipeline = RAGPipeline(
        InMemoryVectorStore.from_chunks(chunks, FixedEmbedder()), FixedEmbedder()
    )

    answer = pipeline.answer("cancel")

    assert not answer.abstained
    assert answer.citations[0].chunk.source == "cancellation-policy.md"


def test_pipeline_abstains_without_positive_evidence() -> None:
    chunks = [
        Chunk(
            "cancel#1",
            "cancellation-policy.md",
            "Cancelación",
            "El pedido Processing puede cancelarse.",
        )
    ]
    pipeline = RAGPipeline(
        InMemoryVectorStore.from_chunks(chunks, FixedEmbedder()), FixedEmbedder()
    )

    answer = pipeline.answer("tarjeta")

    assert answer.abstained
    assert answer.citations == ()


def test_pipeline_generates_from_citeable_context() -> None:
    chunks = [
        Chunk(
            "cancel#1",
            "cancellation-policy.md",
            "Cancelación",
            "El pedido Processing puede cancelarse.",
        )
    ]
    generator = RecordingGenerator()
    pipeline = RAGPipeline(
        InMemoryVectorStore.from_chunks(chunks, FixedEmbedder()), FixedEmbedder()
    )

    answer = pipeline.answer_with_generator("cancel", generator)

    assert (
        answer.answer
        == "Puedes cancelar el pedido mientras esté en Processing. [cancel#1]"
    )
    assert answer.citations[0].chunk.source == "cancellation-policy.md"
    assert generator.calls == [
        (
            "cancel",
            "[cancel#1] Fuente: cancellation-policy.md\nEl pedido Processing puede cancelarse.",
        )
    ]


def test_pipeline_does_not_generate_when_it_abstains() -> None:
    chunks = [
        Chunk(
            "cancel#1",
            "cancellation-policy.md",
            "Cancelación",
            "El pedido Processing puede cancelarse.",
        )
    ]
    generator = RecordingGenerator()
    pipeline = RAGPipeline(
        InMemoryVectorStore.from_chunks(chunks, FixedEmbedder()), FixedEmbedder()
    )

    answer = pipeline.answer_with_generator("tarjeta", generator)

    assert answer.abstained
    assert generator.calls == []


def test_pipeline_uses_the_same_embedding_search_contract_for_any_store() -> None:
    chunk = Chunk(
        "cancel#1",
        "cancellation-policy.md",
        "Cancelación",
        "El pedido Processing puede cancelarse.",
    )
    store = RecordingVectorStore(SearchResult(chunk, 0.91))
    pipeline = RAGPipeline(store, FixedEmbedder())

    answer = pipeline.answer("cancel")

    assert not answer.abstained
    assert np.array_equal(store.query_embedding, np.asarray([1.0, 0.0]))


def test_iris_store_preflight_checks_table_index_and_corpus_without_writing() -> None:
    cursor = FakeCursor(rows=[(3,), (1,)])
    store = IrisVectorStore(FakeConnection(cursor))

    assert store.check_ready() == 3
    assert cursor.executions[0] == (f"SELECT COUNT(*) FROM {TABLE_NAME}", None)
    assert cursor.executions[1] == (
        "SELECT COUNT(*) FROM %Dictionary.CompiledIndex WHERE parent = ? AND Name = ?",
        [CLASS_NAME, INDEX_NAME],
    )


def test_iris_store_preflight_explains_when_the_table_is_missing() -> None:
    cursor = FakeCursor(rows=[], first_execute_error=RuntimeError("table missing"))
    store = IrisVectorStore(FakeConnection(cursor))

    try:
        store.check_ready()
    except RuntimeError as error:
        assert "Completa primero el Lab 02" in str(error)
    else:
        raise AssertionError("Expected the preflight to fail")


def test_iris_store_preflight_rejects_an_empty_corpus_or_missing_index() -> None:
    empty_store = IrisVectorStore(FakeConnection(FakeCursor(rows=[(0,)])))
    missing_index_store = IrisVectorStore(FakeConnection(FakeCursor(rows=[(3,), (0,)])))

    for store, expected_message in [
        (empty_store, "está vacía"),
        (missing_index_store, "índice HNSW"),
    ]:
        try:
            store.check_ready()
        except RuntimeError as error:
            assert expected_message in str(error)
        else:
            raise AssertionError("Expected the preflight to fail")


def test_openrouter_generator_sends_evidence_as_chat_messages() -> None:
    client = FakeOpenRouterClient()
    generator = OpenRouterAnswerGenerator(model="test-model", client=client)

    answer = generator.generate(
        "¿Puedo cancelar?", "[cancel#1] Fuente: cancellation-policy.md\nTexto"
    )

    assert answer == "Respuesta basada en evidencia. [cancel#1]"
    request = client.chat.completions.request
    assert request["model"] == "test-model"
    assert request["messages"][0]["role"] == "system"
    assert "No inventes condiciones" in request["messages"][0]["content"]
    assert request["messages"][1] == {
        "role": "user",
        "content": "Pregunta: ¿Puedo cancelar?\n\nContexto recuperado:\n[cancel#1] Fuente: cancellation-policy.md\nTexto",
    }


def test_generator_uses_only_the_openrouter_key_and_endpoint(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import openai

    calls = []
    monkeypatch.setenv("OPENROUTER_API_KEY", "router-test-key")
    monkeypatch.setenv("OPENAI_API_KEY", "unused-key")
    monkeypatch.setenv("OPENAI_BASE_URL", "https://unused.invalid")
    monkeypatch.setattr(openai, "OpenAI", lambda **kwargs: calls.append(kwargs))

    OpenRouterAnswerGenerator._create_client()

    assert calls == [
        {"api_key": "router-test-key", "base_url": "https://openrouter.ai/api/v1"}
    ]
    monkeypatch.delenv("OPENROUTER_API_KEY")
    with pytest.raises(RuntimeError, match="OPENROUTER_API_KEY"):
        OpenRouterAnswerGenerator._create_client()
    assert len(calls) == 1


def test_generator_selects_the_shared_course_model(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("OPENROUTER_MODEL", raising=False)
    assert OpenRouterAnswerGenerator().model == "openai/gpt-oss-20b"
    monkeypatch.setenv("OPENROUTER_MODEL", "alternative/model")
    assert OpenRouterAnswerGenerator().model == "alternative/model"
    assert OpenRouterAnswerGenerator(model="explicit/model").model == "explicit/model"
    monkeypatch.setenv("OPENROUTER_MODEL", "")
    assert OpenRouterAnswerGenerator().model == "openai/gpt-oss-20b"


def test_chunking_rejects_an_invalid_overlap() -> None:
    document = Document("policy.md", "Policy", "uno dos tres")

    try:
        chunk_documents([document], chunk_size_words=3, overlap_words=3)
    except ValueError as error:
        assert "overlap_words" in str(error)
    else:
        raise AssertionError("Expected invalid chunk overlap to raise ValueError")
