"""Markdown ingestion and transparent word-based chunking."""

from pathlib import Path
import re

from .models import Chunk, Document


def load_markdown_documents(directory: Path) -> list[Document]:
    """Load the versioned policy documents in a stable filename order."""
    documents: list[Document] = []
    for path in sorted(directory.glob("*.md")):
        raw_text = path.read_text(encoding="utf-8").strip()
        title, text = _split_title(raw_text, path.stem)
        documents.append(Document(source=path.name, title=title, text=text))
    if not documents:
        raise FileNotFoundError(f"No Markdown documents found in {directory}")
    return documents


def chunk_documents(
    documents: list[Document], chunk_size_words: int = 120, overlap_words: int = 30
) -> list[Chunk]:
    """Index word windows within sections and retain each complete section as context."""
    if chunk_size_words <= 0:
        raise ValueError("chunk_size_words must be greater than zero")
    if overlap_words < 0 or overlap_words >= chunk_size_words:
        raise ValueError(
            "overlap_words must be at least zero and smaller than chunk_size_words"
        )

    chunks: list[Chunk] = []
    step = chunk_size_words - overlap_words
    for document in documents:
        index = 0
        for section in _sections(document.text):
            section = f"# {document.title}\n\n{section}"
            words = section.split()
            for start in range(0, len(words), step):
                passage = " ".join(words[start : start + chunk_size_words])
                if not passage:
                    continue
                index += 1
                chunks.append(
                    Chunk(
                        chunk_id=f"{document.source}#{index}",
                        source=document.source,
                        title=document.title,
                        text=passage,
                        section_text=section,
                    )
                )
                if start + chunk_size_words >= len(words):
                    break
    return chunks


def _sections(text: str) -> list[str]:
    """Keep Markdown section boundaries; share the document preamble with each section."""
    parts = re.split(r"^(#{2,6}\s+.+)$", text, flags=re.MULTILINE)
    if len(parts) == 1:
        return [text.strip()]
    preamble = parts[0].strip()
    return [
        "\n\n".join(part for part in (preamble, heading, body.strip()) if part)
        for heading, body in zip(parts[1::2], parts[2::2], strict=True)
        if body.strip()
    ]


def _split_title(raw_text: str, fallback: str) -> tuple[str, str]:
    match = re.match(r"^#\s+(.+?)\s*$", raw_text, flags=re.MULTILINE)
    title = match.group(1).strip() if match else fallback
    text = re.sub(r"^#\s+.+?\s*$", "", raw_text, count=1, flags=re.MULTILINE)
    return title, text.strip()
