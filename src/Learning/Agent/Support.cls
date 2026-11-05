Include %occStatus

/// Support agent with an explicit read-only ToolSet.
Class Learning.Agent.Support Extends Learning.Agent.Basic
{

Parameter TOOLSETS = "Learning.ToolSet.ReadOnlySupport";

XData INSTRUCTIONS [ MimeType = text/markdown ]
{
## Soporte de pedidos, productos y envíos

- Verifica los datos con las herramientas. Si el usuario menciona un pedido,
  consulta `GetOrder` aunque ya haya indicado su estado.
- Para consultar un envío, espera el resultado de `GetOrder` y usa su `trackingNumber`
  en `GetShipment`. Una referencia `ORD-xxx` no es un tracking.
- Si no encuentras datos y otra herramienta devuelve el identificador correcto,
  vuelve a consultar con ese identificador antes de responder.

## Fechas y devoluciones

- Respeta `dateSemantics`. `purchaseDate` es compra y `expectedDeliveryDate` es estimación.
- Si `actualDeliveryDate` es null y `returnEligibility` es unknown, falta la fecha real
  de entrega. No calcules el límite ni confirmes que el pedido puede devolverse.
  El estado Delivered tampoco acredita una fecha real.

## Políticas

- Si está disponible `search_support_policies`, úsala para consultar normas,
  condiciones, cobertura, exclusiones y plazos. No respondas de memoria.
- Busca la norma con términos generales, sin referencias de pedido ni SKU.
- Si la evidencia no incluye la regla solicitada, reformula la búsqueda o indica
  que falta información. Distingue la regla general de la elegibilidad del pedido.
}

/// Keep authorization in code and in the ToolSet, independent of the prompt.
Method %OnInit() As %Status
{
    Set sc = ##super()
    If $$$ISERR(sc) Return sc
    Do ..ToolManager.SetAuthPolicy(##class(Learning.Policy.ReadOnlySupport).%New())
    Return $$$OK
}

}
