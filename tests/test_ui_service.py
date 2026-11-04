"""Tests for the optional UI's shared RAG contract without IRIS or OpenRouter."""

import importlib.util
from pathlib import Path
import sys

import pytest


ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "labs" / "opcionales" / "ui-asistente"
sys.path.insert(0, str(UI_DIR))


def _load_module(name: str, path: Path) -> object:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_ask_returns_evidence_without_calling_a_generator(monkeypatch: pytest.MonkeyPatch) -> None:
    service = _load_module("ui_service_for_test", UI_DIR / "service.py")

    class FakePipeline:
        def answer(self, question: str) -> object:
            citation = type(
                "Citation",
                (),
                {"chunk": type("Chunk", (), {"source": "returns-policy.md", "chunk_id": "returns#1", "text": "30 días."})(), "score": 0.91},
            )()
            return type("Answer", (), {"abstained": False, "citations": (citation,)})()

    monkeypatch.setattr(service, "get_pipeline", lambda: FakePipeline())
    result = service.ask("¿Puedo devolverlo?")

    assert result.generated is False
    assert result.abstained is False
    assert result.citations[0]["source"] == "returns-policy.md"


def test_ask_preserves_abstention(monkeypatch: pytest.MonkeyPatch) -> None:
    service = _load_module("ui_service_abstention_for_test", UI_DIR / "service.py")

    class FakePipeline:
        def answer(self, question: str) -> object:
            return type("Answer", (), {"answer": "No hay evidencia.", "abstained": True, "citations": ()})()

    monkeypatch.setattr(service, "get_pipeline", lambda: FakePipeline())
    result = service.ask("¿Qué tiempo hará mañana?")

    assert result.abstained is True
    assert result.citations == ()


def test_post_chat_exposes_the_shared_contract(monkeypatch: pytest.MonkeyPatch) -> None:
    pytest.importorskip("fastapi")
    pytest.importorskip("httpx")
    api = _load_module("ui_api_for_test", UI_DIR / "api.py")
    result = api.ChatResult(
        answer="Puedes devolverlo. [returns#1]",
        citations=(
            {"source": "returns-policy.md", "chunk_id": "returns#1", "score": 0.91, "text": "30 días."},
        ),
        abstained=False,
        generated=False,
    )
    monkeypatch.setattr(api, "ask", lambda question, generate: result)
    from fastapi.testclient import TestClient

    response = TestClient(api.app).post("/chat", json={"question": "¿Puedo devolverlo?"})

    assert response.status_code == 200
    body = response.json()
    assert body["answer"] == result.answer
    assert body["citations"][0]["chunk_id"] == "returns#1"


def test_docs_use_local_swagger_assets() -> None:
    pytest.importorskip("swagger_ui")
    api = _load_module("ui_api_docs_for_test", UI_DIR / "api.py")
    from fastapi.testclient import TestClient

    client = TestClient(api.app)
    docs = client.get("/docs")

    assert docs.status_code == 200
    assert "cdn.jsdelivr.net" not in docs.text
    assert "/docs/static/swagger-ui-bundle.js" in docs.text
    assert client.get("/docs/static/swagger-ui-bundle.js").status_code == 200
    specification = client.get("/docs/swagger.json")
    assert specification.status_code == 200
    assert specification.json()["openapi"] == "3.1.0"


def test_gradio_interface_can_be_constructed() -> None:
    pytest.importorskip("gradio")
    app = _load_module("ui_gradio_for_test", UI_DIR / "app.py")

    assert app.demo is not None
