"""Gradio user interface for the optional persistent RAG walkthrough."""

import gradio as gr

from service import ChatResult, ask


def _evidence_markdown(result: ChatResult) -> str:
    # An abstention intentionally has no source passages to display.
    if not result.citations:
        return "_No hay citas porque el sistema se ha abstenido._"
    blocks = []
    for citation in result.citations:
        # Keep the complete passage visible so the learner can verify the answer.
        blocks.append(
            f"**{citation['source']} · {citation['chunk_id']}** "
            f"(similitud: {citation['score']})\n\n{citation['text']}"
        )
    return "\n\n---\n\n".join(blocks)


def respond(
    question: str, history: list[dict[str, str]], generate: bool
) -> tuple[list[dict[str, str]], str]:
    """Add one traceable response to the chat history."""
    try:
        # The shared service owns retrieval, optional generation, and citations.
        result = ask(question, generate)
        answer = result.answer
        evidence = _evidence_markdown(result)
    except (RuntimeError, ValueError) as error:
        # Render configuration and validation failures in the UI instead of a traceback.
        answer = f"⚠️ {error}"
        evidence = "_No se ha podido consultar el corpus._"
    # Chatbot uses an explicit message history; evidence stays in its separate panel.
    return history + [{"role": "user", "content": question}, {"role": "assistant", "content": answer}], evidence


with gr.Blocks(title="Asistente RAG del curso") as demo:
    gr.Markdown(
        "# Asistente RAG: políticas de soporte\n"
        "Pregunta sobre las políticas demo. La respuesta siempre enseña los fragmentos "
        "recuperados: aquí las fuentes no van escondidas detrás de una cortina."
    )
    chatbot = gr.Chatbot(height=360, label="Conversación")
    with gr.Row():
        question = gr.Textbox(
            label="Tu pregunta",
            placeholder="Por ejemplo: ¿Puedo devolver un pedido ya entregado?",
            scale=5,
        )
        send = gr.Button("Preguntar", variant="primary", scale=1)
    generate = gr.Checkbox(
        label="Generar con OpenRouter",
        value=False,
        info="Opcional: requiere OPENROUTER_API_KEY. Sin marcar, sólo se recupera evidencia.",
    )
    with gr.Accordion("Evidencia recuperada y citas", open=False):
        evidence = gr.Markdown("_Haz una pregunta para ver los fragmentos recuperados._")

    # Button clicks and Enter submit the same traceable interaction.
    send.click(respond, [question, chatbot, generate], [chatbot, evidence])
    question.submit(respond, [question, chatbot, generate], [chatbot, evidence])


if __name__ == "__main__":
    demo.launch(theme=gr.themes.Soft())
