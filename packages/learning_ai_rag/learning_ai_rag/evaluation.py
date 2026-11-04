"""Deterministic evaluation helpers for the RAG cases shipped with the course."""

from dataclasses import dataclass
import json
from pathlib import Path
import re

from .rag import RAGPipeline


@dataclass(frozen=True)
class EvaluationResult:
    case_id: str
    passed: bool
    expected_source: str | None
    retrieved_source: str | None
    abstained: bool
    missing_terms: tuple[str, ...] = ()
    retrieved_sources: tuple[str, ...] = ()


def load_rag_cases(path: Path) -> list[dict[str, object]]:
    """Load the versioned RAG evaluation cases."""
    return json.loads(path.read_text(encoding="utf-8"))


def evaluate_cases(
    pipeline: RAGPipeline, cases: list[dict[str, object]]
) -> list[EvaluationResult]:
    """Check the expected source and its required rules within the delivered context."""
    results: list[EvaluationResult] = []
    for case in cases:
        answer = pipeline.answer(str(case["question"]))
        expected_source = case.get("expected_source")
        retrieved_source = (
            answer.citations[0].chunk.source if answer.citations else None
        )
        should_abstain = case.get("expected_behavior") == "abstain"
        matching = [
            hit.chunk.text
            for hit in answer.citations
            if hit.chunk.source == expected_source
        ]
        context = _normalize("\n".join(matching))
        missing_terms = tuple(
            term
            for term in case.get("required_terms", [])
            if _normalize(term) not in context
        )
        passed = (
            (answer.abstained and not answer.citations)
            if should_abstain
            else bool(matching) and not missing_terms
        )
        results.append(
            EvaluationResult(
                case_id=str(case["id"]),
                passed=passed,
                expected_source=str(expected_source) if expected_source else None,
                retrieved_source=retrieved_source,
                abstained=answer.abstained,
                missing_terms=missing_terms,
                retrieved_sources=tuple(
                    dict.fromkeys(hit.chunk.source for hit in answer.citations)
                ),
            )
        )
    return results


def _normalize(text: str) -> str:
    return " ".join(re.sub(r"[*_`#]", "", text.casefold()).split())


def pass_rate(results: list[EvaluationResult]) -> float:
    """Return zero for an empty suite instead of raising a division error."""
    return sum(result.passed for result in results) / len(results) if results else 0.0
