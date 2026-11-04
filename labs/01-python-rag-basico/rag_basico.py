"""Run the first retrieval-first RAG example from a terminal."""

import argparse
import os
from pathlib import Path
import sys

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag import (  # noqa: E402
    InMemoryVectorStore,
    OpenRouterAnswerGenerator,
    RAGPipeline,
    SentenceTransformerEmbedder,
    load_markdown_documents,
)
from learning_ai_rag.ingest import chunk_documents  # noqa: E402


def main() -> None:
    load_dotenv(ROOT / ".env")
    parser = argparse.ArgumentParser(description="Consulta las políticas demo con recuperación local o RAG.")
    parser.add_argument(
        "--question",
        default="¿Puedo cancelar un pedido que ya se ha enviado?",
        help="Pregunta en español sobre las políticas demo.",
    )
    parser.add_argument(
        "--generate",
        action="store_true",
        help="Genera una respuesta con OpenRouter usando la evidencia recuperada como contexto.",
    )
    args = parser.parse_args()

    documents = load_markdown_documents(ROOT / "datos-demo" / "knowledge")
    chunks = chunk_documents(documents)
    embedder = SentenceTransformerEmbedder()
    pipeline = RAGPipeline(InMemoryVectorStore.from_chunks(chunks, embedder), embedder)
    evidence_answer = pipeline.answer(args.question)

    print(f"Pregunta: {args.question}\n")
    print("Evidencia recuperada:\n")
    print(evidence_answer.answer)
    if evidence_answer.abstained:
        print("\nResultado: abstención por falta de evidencia.")
        return

    print("\nCitas:")
    for citation in evidence_answer.citations:
        print(f"- {citation.chunk.source} · {citation.chunk.chunk_id} ({citation.score:.3f})")

    if not args.generate:
        print("\nPara convertir esta evidencia en una respuesta RAG, añade --generate.")
        return

    if not os.environ.get("OPENROUTER_API_KEY"):
        print(
            "\nNo puedo generar la respuesta: define OPENROUTER_API_KEY y vuelve a ejecutar con --generate."
        )
        return

    generator = OpenRouterAnswerGenerator()
    answer = pipeline.answer_with_generator(args.question, generator)
    print("\nRespuesta RAG:\n")
    print(answer.answer)


if __name__ == "__main__":
    main()
