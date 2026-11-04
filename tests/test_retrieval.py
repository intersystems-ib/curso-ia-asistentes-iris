"""Regression checks for section context, policy evidence and safe corpus replacement."""

from pathlib import Path
import sys
from types import SimpleNamespace

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag.evaluation import evaluate_cases  # noqa: E402
from learning_ai_rag.ingest import chunk_documents, load_markdown_documents  # noqa: E402
from learning_ai_rag.iris_vector import IrisVectorStore  # noqa: E402
from learning_ai_rag.models import Chunk, Document, RAGAnswer, SearchResult  # noqa: E402
from learning_ai_rag.rag import RAGPipeline  # noqa: E402


class ConstantEmbedder:
    def encode(self, texts):
        return np.ones((len(texts), 2))


class RankedStore:
    def __init__(self, results):
        self.results = results

    def search_by_embedding(self, embedding, top_k=3):
        return self.results[:top_k]


def test_word_windows_stay_inside_sections_and_retain_the_complete_rule():
    document = Document(
        "policy.md",
        "Garantía",
        "## Cobertura\n"
        + "dato " * 25
        + "12 meses\n\n## Exclusiones\nNo cubre desgaste normal.",
    )
    chunks = chunk_documents([document], chunk_size_words=10, overlap_words=2)
    assert all(len(chunk.text.split()) <= 10 for chunk in chunks)
    coverage = [chunk for chunk in chunks if "## Cobertura" in chunk.section_text]
    assert len(coverage) > 1
    assert all("12 meses" in chunk.section_text for chunk in coverage)
    assert all("## Exclusiones" not in chunk.section_text for chunk in coverage)
    assert not any(
        "12 meses" in chunk.text and "desgaste normal" in chunk.text for chunk in chunks
    )
    assert all(chunk.text and "# Garantía" in chunk.section_text for chunk in chunks)


def test_iris_hit_expands_to_the_same_section_as_an_in_memory_hit():
    chunks = chunk_documents(
        [
            Document(
                "policy.md", "Garantía", "## Cobertura\n" + "dato " * 25 + "12 meses"
            )
        ],
        10,
        2,
    )
    fragment = chunks[0]
    stored = Chunk(fragment.chunk_id, fragment.source, fragment.title, fragment.text)
    pipeline = RAGPipeline(
        RankedStore([SearchResult(stored, 0.8)]),
        ConstantEmbedder(),
        context_chunks=chunks,
    )
    answer = pipeline.answer("garantía")
    assert "12 meses" not in fragment.text
    assert "12 meses" in answer.answer
    assert answer.citations[0].chunk.chunk_id == fragment.chunk_id
    assert answer.citations[0].chunk.text == fragment.section_text


def test_multiple_windows_of_one_section_do_not_duplicate_the_context():
    chunks = chunk_documents(
        [
            Document(
                "policy.md", "Garantía", "## Cobertura\n" + "dato " * 25 + "12 meses"
            )
        ],
        10,
        2,
    )
    pipeline = RAGPipeline(
        RankedStore([SearchResult(c, 0.8) for c in chunks]), ConstantEmbedder()
    )
    answer = pipeline.answer("garantía")
    assert len(answer.citations) == 1
    assert answer.citations[0].chunk.text == chunks[0].section_text


def test_stale_persisted_fragments_require_an_explicit_reload():
    current = Chunk(
        "policy#1", "policy.md", "Policy", "current", "complete current section"
    )
    stale = Chunk("policy#1", "policy.md", "Policy", "outdated")
    pipeline = RAGPipeline(
        RankedStore([SearchResult(stale, 0.9)]),
        ConstantEmbedder(),
        context_chunks=[current],
    )
    with pytest.raises(RuntimeError, match="--load"):
        pipeline.answer("question")


def test_heading_reranking_keeps_the_original_similarity_visible():
    unrelated = Chunk(
        "returns#1", "returns-policy.md", "Devoluciones", "## Devoluciones\nOtra regla."
    )
    warranty = Chunk(
        "warranty#1", "warranty-policy.md", "Garantía", "## Garantía\n12 meses."
    )
    pipeline = RAGPipeline(
        RankedStore([SearchResult(unrelated, 0.65), SearchResult(warranty, 0.62)]),
        ConstantEmbedder(),
    )
    answer = pipeline.answer("garantía")
    assert answer.citations[0].chunk.source == "warranty-policy.md"
    assert answer.citations[0].score == 0.62


def test_versioned_corpus_keeps_warranty_period_and_exclusions_in_section_context():
    chunks = chunk_documents(load_markdown_documents(ROOT / "datos-demo/knowledge"))
    coverage = [
        c
        for c in chunks
        if c.source == "warranty-policy.md" and "## Cobertura" in c.section_text
    ]
    assert coverage and all("12 meses" in c.section_text for c in coverage)
    assert any(
        "no cubre" in c.section_text and "desgaste normal" in c.section_text
        for c in chunks
        if c.source == "warranty-policy.md"
    )


@pytest.mark.parametrize(
    "rule_source,rule_text,passed",
    [
        ("warranty-policy.md", "Sólo explica el proceso, sin el plazo.", False),
        ("returns-policy.md", "12 meses", False),
        ("warranty-policy.md", "Los reacondicionados incluyen **12 meses**.", True),
    ],
)
def test_evaluation_requires_the_rule_from_its_expected_source(
    rule_source, rule_text, passed
):
    citation = SearchResult(Chunk("rule#1", rule_source, "Regla", rule_text), 0.8)
    pipeline = SimpleNamespace(
        answer=lambda question: RAGAnswer(rule_text, (citation,), False)
    )
    result = evaluate_cases(
        pipeline,
        [
            {
                "id": "warranty",
                "question": "garantía",
                "expected_source": "warranty-policy.md",
                "required_terms": ["12 meses"],
            }
        ],
    )[0]
    assert result.passed is passed


def test_failed_corpus_replacement_rolls_back_instead_of_committing_partial_data():
    calls = []

    class FailingCursor:
        def execute(self, *args):
            calls.append("execute")
            if calls.count("execute") == 2:
                raise RuntimeError("insertion failed")

        def close(self):
            calls.append("close")

    connection = SimpleNamespace(
        cursor=lambda: FailingCursor(),
        commit=lambda: calls.append("commit"),
        rollback=lambda: calls.append("rollback"),
    )
    store = IrisVectorStore(connection)
    with pytest.raises(RuntimeError, match="insertion failed"):
        store.replace_chunks(
            [Chunk("chunk#1", "policy.md", "Policy", "text")], np.ones((1, 384))
        )
    assert "rollback" in calls and "commit" not in calls
    assert calls[-1] == "close"


def test_evaluation_checks_the_context_not_only_the_first_hit():
    hits = (
        SearchResult(
            Chunk("returns#1", "returns-policy.md", "Returns", "Otra regla."), 0.8
        ),
        SearchResult(
            Chunk("warranty#1", "warranty-policy.md", "Warranty", "12 meses"), 0.7
        ),
    )
    pipeline = SimpleNamespace(
        answer=lambda question: RAGAnswer("context", hits, False)
    )
    result = evaluate_cases(
        pipeline,
        [
            {
                "id": "warranty",
                "question": "garantía",
                "expected_source": "warranty-policy.md",
                "required_terms": ["12 meses"],
            }
        ],
    )[0]
    assert result.passed
    assert result.retrieved_source == "returns-policy.md"
    assert result.retrieved_sources == ("returns-policy.md", "warranty-policy.md")
