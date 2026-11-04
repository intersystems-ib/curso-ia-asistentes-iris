"""OpenRouter adapter for the optional generation step in the course labs."""

import os
from typing import Any


OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
DEFAULT_MODEL = "openai/gpt-oss-20b"


class OpenRouterAnswerGenerator:
    """Generate a Spanish answer from retrieved evidence through OpenRouter."""

    def __init__(self, model: str | None = None, client: Any | None = None) -> None:
        self.model = model or os.environ.get("OPENROUTER_MODEL") or DEFAULT_MODEL
        self._client = client

    def generate(self, question: str, context: str) -> str:
        """Ask the model to answer only from the supplied, citeable context."""
        client = self._client or self._create_client()
        response = client.chat.completions.create(
            model=self.model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Responde en español y usa únicamente el contexto proporcionado. "
                        "Si no basta para responder, dilo claramente. No inventes condiciones, "
                        "fechas ni políticas. Tras cada afirmación relevante, cita el identificador "
                        "del fragmento entre corchetes, por ejemplo [warranty-policy#1]."
                    ),
                },
                {
                    "role": "user",
                    "content": f"Pregunta: {question}\n\nContexto recuperado:\n{context}",
                },
            ],
        )
        content = response.choices[0].message.content
        if not content or not content.strip():
            raise RuntimeError(
                "OpenRouter no ha devuelto una respuesta de texto. Vuelve a intentarlo."
            )
        return content

    @staticmethod
    def _create_client() -> Any:
        api_key = os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            raise RuntimeError(
                "Define OPENROUTER_API_KEY en .env para generar respuestas."
            )
        try:
            from openai import OpenAI
        except ImportError as error:
            raise RuntimeError(
                "Falta el cliente compatible. Ejecuta: python -m pip install -r requirements.txt"
            ) from error
        return OpenAI(api_key=api_key, base_url=OPENROUTER_BASE_URL)
