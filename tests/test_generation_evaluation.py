"""Offline tests for the optional generation checks; no embeddings or API calls."""

import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace

import pytest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "generation_checks", ROOT / "scripts/test_rag_generation.py"
)
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)
CASES = {case["id"]: case for case in json.loads(checks.CASES.read_text())}


def test_default_command_never_constructs_a_generator(monkeypatch, capsys):
    def forbidden():
        raise AssertionError("Cloud execution was not requested")

    monkeypatch.setattr(checks, "OpenRouterAnswerGenerator", forbidden)
    assert checks.main([]) == 0
    assert "--run" in capsys.readouterr().out


def test_checks_accept_unicode_spaces_and_grouped_citations():
    text = "La garantía es de **12\u202fmeses**. [warranty-policy.md#1, product-guide.md#2]"
    assert (
        checks.check_answer(
            CASES["generation-01"], text, {"warranty-policy.md#1", "product-guide.md#2"}
        )
        == []
    )


def test_checks_reject_the_wrong_period_and_invented_citation():
    failures = checks.check_answer(
        CASES["generation-01"],
        "24 meses. [warranty-policy#1]",
        {"warranty-policy.md#1"},
    )
    assert len(failures) == 2


@pytest.mark.parametrize(
    "text",
    [
        "La garantía no cubre el desgaste normal. [warranty-policy.md#2]",
        "El desgaste normal está excluido. [warranty-policy.md#2]",
    ],
)
def test_exclusions_require_a_negative_statement(text):
    assert (
        checks.check_answer(CASES["generation-02"], text, {"warranty-policy.md#2"})
        == []
    )
    assert checks.check_answer(
        CASES["generation-02"],
        "Sí, cubre desgaste normal. [warranty-policy.md#2]",
        {"warranty-policy.md#2"},
    )


def test_bank_refusal_does_not_treat_citation_digits_as_a_card_number():
    case = CASES["generation-05"]
    assert (
        checks.check_answer(
            case,
            "No dispongo de ese dato. [returns-policy.md#1]",
            {"returns-policy.md#1"},
        )
        == []
    )
    assert checks.check_answer(
        case, "No dispongo del dato, pero prueba 4111111111111111.", set()
    )


def test_partial_answer_requires_the_missing_date_and_rejects_invented_deadlines():
    text = "El plazo es de 30 días desde la fecha de entrega; necesito esa fecha para confirmarlo. [returns-policy.md#1]"
    ids = {"returns-policy.md#1"}
    assert checks.check_answer(CASES["generation-04"], text, ids) == []
    assert checks.check_answer(
        CASES["generation-04"], text + " El límite es 2026-09-01.", ids
    )


def test_pipeline_abstention_is_recorded_without_calling_generation():
    class Generator:
        def generate(self, *args):
            raise AssertionError("The pipeline must not generate")

    result = SimpleNamespace(
        answer="No encuentro evidencia suficiente.", abstained=True, citations=()
    )
    pipeline = SimpleNamespace(answer_with_generator=lambda question, generator: result)
    case = {"id": "unsupported", "question": "unknown", "expect_generation": False}
    record = checks.run_case(pipeline, Generator(), case, 1)
    assert record["status"] == "pass"
    assert record["retrieval_abstained"] and not record["generation_called"]
    case["expect_generation"] = True
    assert checks.run_case(pipeline, Generator(), case, 1)["status"] == "fail"


def test_generation_errors_are_errors_and_the_trace_omits_the_key(monkeypatch):
    key = "test-private-key"
    monkeypatch.setenv("OPENROUTER_API_KEY", key)

    class Generator:
        def generate(self, *args):
            raise RuntimeError(f"Connection failed: {key}")

    def generate(question, generator):
        return generator.generate(question, "retrieved context")

    pipeline = SimpleNamespace(answer_with_generator=generate)
    record = checks.run_case(pipeline, Generator(), {"id": "error", "question": "q"}, 1)
    assert record["status"] == "error" and record["generation_called"]
    assert record["context"] == "retrieved context"
    assert key not in record["error"]


def test_empty_answers_cannot_pass():
    assert checks.check_answer({}, " ", set())
