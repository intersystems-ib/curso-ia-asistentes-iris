"""Run the persistent IRIS-backed RAG example from a terminal."""

import argparse
import os
from pathlib import Path
import sys

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag import (  # noqa: E402
    OpenRouterAnswerGenerator,
    RAGPipeline,
    SentenceTransformerEmbedder,
    load_markdown_documents,
)
from learning_ai_rag.ingest import chunk_documents  # noqa: E402
from learning_ai_rag.iris_vector import IrisConnectionSettings, IrisVectorStore  # noqa: E402


def main() -> None:
    load_dotenv(ROOT / ".env")
    parser = argparse.ArgumentParser(description="Ejecuta el RAG persistente sobre IRIS.")
    parser.add_argument("--initialize", action="store_true", help="Crea la tabla e índice HNSW.")
    parser.add_argument("--load", action="store_true", help="Inserta o actualiza los chunks demo.")
    parser.add_argument("--question", default="¿Puedo cambiar la dirección después del envío?")
    parser.add_argument(
        "--generate",
        action="store_true",
        help="Genera una respuesta con OpenRouter a partir de la evidencia de IRIS.",
    )
    args = parser.parse_args()

    embedder = SentenceTransformerEmbedder()
    if embedder.dimension != 384:
        raise ValueError("Este laboratorio necesita un modelo de embeddings de 384 dimensiones")
    store = IrisVectorStore.connect(IrisConnectionSettings.from_environment())
    if args.initialize:
        store.initialize()
        print("Tabla e índice HNSW creados.")
    chunks = chunk_documents(load_markdown_documents(ROOT / "datos-demo" / "knowledge"))
    if args.load:
        store.replace_chunks(chunks, embedder.encode([chunk.text for chunk in chunks]))
        print(f"{len(chunks)} chunks cargados en IRIS.")

    pipeline = RAGPipeline(store, embedder, context_chunks=chunks)
    evidence_answer = pipeline.answer(args.question)
    print(f"Pregunta: {args.question}\n")
    print("Evidencia recuperada desde IRIS:\n")
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
