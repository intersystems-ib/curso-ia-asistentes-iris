"""Evaluate retrieval and abstention for the persistent IRIS-backed RAG."""

from pathlib import Path
import sys

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag import (  # noqa: E402
    RAGPipeline,
    SentenceTransformerEmbedder,
    evaluate_cases,
    load_rag_cases,
)
from learning_ai_rag.evaluation import pass_rate  # noqa: E402
from learning_ai_rag.ingest import chunk_documents, load_markdown_documents  # noqa: E402
from learning_ai_rag.iris_vector import IrisConnectionSettings, IrisVectorStore  # noqa: E402


def main() -> None:
    load_dotenv(ROOT / ".env")
    embedder = SentenceTransformerEmbedder()
    store = IrisVectorStore.connect(IrisConnectionSettings.from_environment())
    chunk_count = store.check_ready()
    print(f"Corpus de IRIS comprobado: {chunk_count} chunks.\n")
    chunks = chunk_documents(load_markdown_documents(ROOT / "datos-demo" / "knowledge"))
    pipeline = RAGPipeline(store, embedder, context_chunks=chunks)
    cases = load_rag_cases(ROOT / "datos-demo" / "evaluation" / "rag-cases.json")
    results = evaluate_cases(pipeline, cases)

    for result in results:
        status = "PASS" if result.passed else "FAIL"
        print(
            f"{status} {result.case_id}: expected={result.expected_source}, "
            f"first={result.retrieved_source}, context_sources={result.retrieved_sources}, "
            f"abstained={result.abstained}, missing_terms={result.missing_terms}"
        )
    print(
        f"\nPass rate: {pass_rate(results):.0%} ({sum(item.passed for item in results)}/{len(results)})"
    )


if __name__ == "__main__":
    main()
