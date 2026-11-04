/// Reusable LLM-facing support workflow: instructions, metadata, and the read-only ToolSet.
Class Learning.Skill.SupportWorkflow Extends %AI.Agent.Skill
{

/// The skill makes the existing, declarative support surface available to an agent.
Parameter TOOLS = "Learning.ToolSet.ReadOnlySupport";

XData SUMMARY [ MimeType = text/yaml ]
{
name: support-workflow
description: Atiende consultas de soporte con datos estructurados y políticas aprobadas.
tags:
  - support
  - read-only
  - rag
}

XData INSTRUCTIONS [ MimeType = text/markdown ]
{
## Flujo de soporte

- Consulta pedidos, productos y envíos mediante las herramientas estructuradas disponibles.
- Si el usuario menciona un pedido, verifica su estado con `GetOrder` aunque ya lo haya descrito.
- Para localizar un pedido, consulta primero `GetOrder`, espera su resultado y usa
  su `trackingNumber` para consultar después `GetShipment`. Una referencia `ORD-xxx`
  no es un tracking; no ejecutes esas consultas en paralelo si aún no conoces el tracking.
- Si una consulta no encuentra datos, pero otra herramienta devuelve el identificador
  correcto, vuelve a consultar con él antes de responder.
- Explica el plazo general de devolución sin confirmar que el pedido está en plazo
  cuando no conoces la fecha real de entrega.
- Respeta `dateSemantics`: `purchaseDate` es compra y `expectedDeliveryDate` es sólo
  una estimación. Si `actualDeliveryDate` es null y `returnEligibility` es unknown,
  indica que falta la fecha real de entrega; no calcules el límite ni confirmes
  que este pedido puede devolverse. `Delivered` no aporta una fecha real.
- Cuando la pregunta trate sobre políticas, devoluciones, cancelaciones, garantías o plazos,
  usa `search_support_policies` si está disponible. Busca la norma con términos generales,
  sin incluir referencias de pedido ni SKU. Si los fragmentos sólo son títulos o no
  incluyen la condición o el plazo solicitado, reformula la búsqueda. No afirmes un
  plazo ni una condición sin evidencia textual de esa regla.
- Distingue los datos del pedido de las condiciones de la política y cita las fuentes recuperadas.
- Cita los datos con `sourceRef` y los documentos con `metadata.source`, entre
  corchetes. Sólo crea un enlace si hay una URL explícita en `sourceUrl`;
  si es null, cita el identificador o archivo sin inventar enlaces.
- Si no hay evidencia suficiente, dilo claramente. No inventes datos ni condiciones.
}

}
