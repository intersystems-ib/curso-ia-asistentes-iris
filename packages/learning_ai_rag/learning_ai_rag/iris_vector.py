"""IRIS VECTOR SQL store used by the persistent RAG labs."""

from dataclasses import dataclass
import os

import numpy as np

from .models import Chunk, SearchResult


VECTOR_DIMENSION = 384
TABLE_NAME = "Learning_RAG.ChunkEmbedding"
CLASS_NAME = "Learning.RAG.ChunkEmbedding"
INDEX_NAME = "ChunkEmbeddingHnsw"


@dataclass(frozen=True)
class IrisConnectionSettings:
    host: str
    port: int
    namespace: str
    username: str
    password: str

    @classmethod
    def from_environment(cls) -> "IrisConnectionSettings":
        return cls(
            host=os.getenv("IRIS_HOST", "localhost"),
            port=int(os.getenv("IRIS_PORT", "1972")),
            namespace=os.getenv("IRIS_NAMESPACE", "USER"),
            username=os.getenv("IRIS_USERNAME", ""),
            password=os.getenv("IRIS_PASSWORD", ""),
        )


class IrisVectorStore:
    """Persist and search normalized 384-dimensional vectors in IRIS."""

    def __init__(self, connection: object) -> None:
        self.connection = connection

    @staticmethod
    def connect(settings: IrisConnectionSettings) -> "IrisVectorStore":
        import iris

        connection = iris.connect(
            settings.host,
            settings.port,
            settings.namespace,
            settings.username,
            settings.password,
        )
        return IrisVectorStore(connection)

    def initialize(self) -> None:
        """Create the table and its HNSW cosine index once."""
        cursor = self.connection.cursor()
        try:
            cursor.execute(
                f"CREATE TABLE {TABLE_NAME} ("
                "ChunkId VARCHAR(120) NOT NULL, "
                "SourceName VARCHAR(255) NOT NULL, "
                "ChunkText VARCHAR(10000) NOT NULL, "
                f"Embedding VECTOR(DOUBLE, {VECTOR_DIMENSION}), "
                "PRIMARY KEY (ChunkId))"
            )
            cursor.execute(
                f"CREATE INDEX {INDEX_NAME} ON TABLE {TABLE_NAME} (Embedding) "
                "AS HNSW(Distance='Cosine')"
            )
            self.connection.commit()
        finally:
            cursor.close()

    def replace_chunks(self, chunks: list[Chunk], embeddings: np.ndarray) -> None:
        """Replace a known course chunk set using typed parameter binding."""
        if embeddings.shape != (len(chunks), VECTOR_DIMENSION):
            raise ValueError(f"Expected embeddings with shape (n, {VECTOR_DIMENSION})")
        cursor = self.connection.cursor()
        try:
            # --load replaces the course corpus, including obsolete chunk IDs after re-splitting.
            cursor.execute(f"DELETE FROM {TABLE_NAME}")
            for chunk, embedding in zip(chunks, embeddings, strict=True):
                cursor.execute(
                    f"INSERT INTO {TABLE_NAME} (ChunkId, SourceName, ChunkText, Embedding) "
                    f"VALUES (?, ?, ?, TO_VECTOR(?, DOUBLE, {VECTOR_DIMENSION}))",
                    [chunk.chunk_id, chunk.source, chunk.text, _vector_parameter(embedding)],
                )
            self.connection.commit()
        except Exception:
            self.connection.rollback()
            raise
        finally:
            cursor.close()

    def search_by_embedding(
        self, query_embedding: np.ndarray, top_k: int = 3
    ) -> list[SearchResult]:
        """Use TOP plus ORDER BY so IRIS can use the HNSW index."""
        if query_embedding.shape != (VECTOR_DIMENSION,):
            raise ValueError(f"Expected a {VECTOR_DIMENSION}-dimensional query embedding")
        cursor = self.connection.cursor()
        try:
            cursor.execute(
                f"SELECT TOP {top_k} ChunkId, SourceName, ChunkText, "
                f"VECTOR_COSINE(Embedding, TO_VECTOR(?, DOUBLE, {VECTOR_DIMENSION})) AS score "
                f"FROM {TABLE_NAME} ORDER BY score DESC",
                [_vector_parameter(query_embedding)],
            )
            rows = cursor.fetchall()
        finally:
            cursor.close()
        return [
            SearchResult(
                chunk=Chunk(chunk_id=row[0], source=row[1], title=row[1], text=row[2]),
                score=float(row[3]),
            )
            for row in rows
        ]

    def check_ready(self) -> int:
        """Verify that the Lab 02 table, index, and corpus exist without writing."""
        cursor = self.connection.cursor()
        try:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {TABLE_NAME}")
                row = cursor.fetchone()
            except Exception as error:
                raise RuntimeError(
                    "No encuentro la tabla vectorial de IRIS. Completa primero el Lab 02 "
                    "con: python labs/02-sql-vector-search/vector_search.py --initialize --load"
                ) from error
            chunk_count = int(row[0])
            if chunk_count == 0:
                raise RuntimeError(
                    "La tabla vectorial está vacía. Carga el corpus con: "
                    "python labs/02-sql-vector-search/vector_search.py --load"
                )
            cursor.execute(
                "SELECT COUNT(*) FROM %Dictionary.CompiledIndex WHERE parent = ? AND Name = ?",
                [CLASS_NAME, INDEX_NAME],
            )
            if int(cursor.fetchone()[0]) == 0:
                raise RuntimeError(
                    "No encuentro el índice HNSW. Completa primero el Lab 02 con: "
                    "python labs/02-sql-vector-search/vector_search.py --initialize --load"
                )
            return chunk_count
        finally:
            cursor.close()


def _vector_parameter(vector: np.ndarray) -> str:
    return ",".join(f"{float(value):.12g}" for value in vector)
