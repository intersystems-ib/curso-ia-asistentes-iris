"""Small HTTP contract over the optional Python RAG demonstration."""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from swagger_ui import api_doc

from service import ChatResult, ask


class ChatRequest(BaseModel):
    """The single input accepted by the demonstration API."""

    question: str = Field(min_length=1, max_length=2_000)
    generate: bool = False


class Citation(BaseModel):
    """A source passage exposed without hiding the retrieval step."""

    source: str
    chunk_id: str
    score: float
    text: str


class ChatResponse(BaseModel):
    """The answer, evidence, and whether generation happened."""

    answer: str
    citations: list[Citation]
    abstained: bool
    generated: bool


app = FastAPI(title="Asistente RAG del curso", version="1.0.0", docs_url=None)


def _response(result: ChatResult) -> ChatResponse:
    return ChatResponse(
        answer=result.answer,
        citations=[Citation(**citation) for citation in result.citations],
        abstained=result.abstained,
        generated=result.generated,
    )


@app.get("/health")
def health() -> dict[str, str]:
    """Keep health checking independent from model loading and IRIS access."""
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    """Return evidence or an explicitly requested grounded RAG answer."""
    try:
        return _response(ask(request.question, request.generate))
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except RuntimeError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error


# Register a local Swagger UI bundle after the application routes are defined.
api_doc(
    app,
    # The local bundle also publishes this generated specification under /docs.
    config=app.openapi(),
    url_prefix="/docs",
    title=f"{app.title} - documentación API",
    app_type="starlette",
)
