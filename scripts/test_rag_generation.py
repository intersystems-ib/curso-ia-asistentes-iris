#!/usr/bin/env python3
"""Optional generation smoke checks. Only --run enables paid OpenRouter calls."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import sys
import unicodedata

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "packages" / "learning_ai_rag"))

from learning_ai_rag import (  # noqa: E402
    InMemoryVectorStore,
    OpenRouterAnswerGenerator,
    RAGPipeline,
    SentenceTransformerEmbedder,
    load_markdown_documents,
)
from learning_ai_rag.ingest import chunk_documents  # noqa: E402

CASES = ROOT / "datos-demo/evaluation/generation-cases.json"


def check_answer(case: dict, answer: str, citation_ids: set[str]) -> list[str]:
    """Check explicit textual expectations, without another LLM or a semantic judge."""
    failures = []
    if not answer.strip():
        failures.append("Respuesta vacía.")
    references = [
        reference.strip()
        for group in re.findall(r"\[([^\[\]\n]+)\]", answer)
        for reference in re.split(r"\s*[,;]\s*", group)
    ]
    if case.get("require_citations") and not references:
        failures.append("Faltan citas de los fragmentos recuperados.")
    invalid = sorted(set(references) - citation_ids)
    if invalid:
        failures.append("Citas no presentes en el contexto: " + ", ".join(invalid))

    # Do not mistake the digits in [policy.md#1] for an invented account number.
    plain = re.sub(r"\[[^\[\]\n]+\]", "", answer)
    plain = unicodedata.normalize("NFKC", plain).casefold()
    plain = " ".join(re.sub(r"[*_`]", "", plain).split())
    for pattern in case.get("required_patterns", []):
        if not re.search(pattern, plain):
            failures.append(f"No se cumple el patrón esperado: {pattern}")
    for pattern in case.get("forbidden_patterns", []):
        if re.search(pattern, plain):
            failures.append(f"Aparece un patrón no permitido: {pattern}")
    return failures


def run_case(pipeline, generator, case: dict, attempt: int) -> dict:
    """Exercise the real pipeline and record whether it actually called generation."""
    record = {
        "id": case["id"],
        "attempt": attempt,
        "question": case["question"],
        "generation_called": False,
        "context": "",
    }

    class RecordedGenerator:
        def generate(self, question: str, context: str) -> str:
            record["generation_called"] = True
            record["context"] = context
            return generator.generate(question, context)

    try:
        result = pipeline.answer_with_generator(case["question"], RecordedGenerator())
        record.update(
            answer=result.answer,
            retrieval_abstained=result.abstained,
            evidence=[
                {
                    "chunk_id": hit.chunk.chunk_id,
                    "source": hit.chunk.source,
                    "score": hit.score,
                    "text": hit.chunk.text,
                }
                for hit in result.citations
            ],
        )
        failures = check_answer(
            case, result.answer, {hit.chunk.chunk_id for hit in result.citations}
        )
        if (
            "expect_generation" in case
            and record["generation_called"] != case["expect_generation"]
        ):
            failures.append("La llamada al generador no coincide con la expectativa.")
        record.update(status="fail" if failures else "pass", failures=failures)
    except Exception as error:
        # An empty response or HTTP error must not abort the other cases or become a PASS.
        message = str(error)
        key = os.environ.get("OPENROUTER_API_KEY")
        if key:
            message = message.replace(key, "[clave ocultada]")
        record.update(status="error", error=f"{type(error).__name__}: {message}")
    return record


def positive_int(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("Debe ser al menos 1.")
    return number


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--run",
        action="store_true",
        help="Ejecuta los casos con llamadas reales a OpenRouter.",
    )
    parser.add_argument(
        "--repeats",
        type=positive_int,
        default=1,
        help="Intentos por caso (por defecto, 1. Cada intento puede consumir créditos).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "tmp/generation-evaluation.json",
        help="Archivo JSON con respuestas y contexto.",
    )
    args = parser.parse_args(argv)
    if not args.run:
        print(
            "Prueba opcional. Para llamar a OpenRouter: python scripts/test_rag_generation.py --run"
        )
        return 0

    load_dotenv(ROOT / ".env")
    generator = OpenRouterAnswerGenerator()
    # Fail before embedding/model loading if the key is missing. Reuse one API client.
    generator._client = generator._create_client().with_options(
        max_retries=0, timeout=60.0
    )
    cases = json.loads(CASES.read_text(encoding="utf-8"))
    chunks = chunk_documents(load_markdown_documents(ROOT / "datos-demo/knowledge"))
    embedder = SentenceTransformerEmbedder()
    pipeline = RAGPipeline(InMemoryVectorStore.from_chunks(chunks, embedder), embedder)
    report = {
        "started_at": datetime.now(timezone.utc).isoformat(),
        "model": generator.model,
        "provider": "openrouter",
        "backend": "memory",
        "repeats": args.repeats,
        "results": [],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    print(
        f"Modelo: {generator.model}. Casos: {len(cases)} × {args.repeats}. Sin reintentos automáticos."
    )
    for case in cases:
        for attempt in range(1, args.repeats + 1):
            result = run_case(pipeline, generator, case, attempt)
            report["results"].append(result)
            args.output.write_text(
                json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            print(
                f"{result['status'].upper()} {case['id']} ({attempt}/{args.repeats})",
                flush=True,
            )
            for failure in result.get("failures", []):
                print(f"  {failure}")
            if result.get("error"):
                print(f"  {result['error']}")
    passed = sum(result["status"] == "pass" for result in report["results"])
    print(f"Resultado: {passed}/{len(report['results'])}. Registro: {args.output}")
    print("Comprobaciones de humo: revisa también las respuestas y su contexto.")
    return 0 if passed == len(report["results"]) else 1


if __name__ == "__main__":
    raise SystemExit(main())
