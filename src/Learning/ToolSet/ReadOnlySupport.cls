/// Read-only support surface selected at compile time for agents and MCP.
Class Learning.ToolSet.ReadOnlySupport Extends %AI.ToolSet
    [ DependsOn = (Learning.Policy.ReadOnlySupport, Learning.Tools.OrderTools, Learning.Tools.CatalogTools, Learning.Tools.ShipmentTools) ]
{

XData Definition [ MimeType = application/xml ]
{
<ToolSet Name="ReadOnlySupport">
  <Description>Consulta pedidos, catálogo y envíos del dominio docente. No expone escrituras ni SQL genérico.</Description>
  <Policies>
    <Authorization Class="Learning.Policy.ReadOnlySupport" />
  </Policies>
  <Tool Name="GetOrder" Class="Learning.Tools.OrderTools" Method="GetOrder">
    <Description>Consulta un pedido. purchaseDate es fecha de compra, no envío ni entrega. Las fechas reales de envío y entrega y el límite de devolución no constan; se devuelven como null. Cita sourceRef como identificador, no como URL.</Description>
  </Tool>
  <Tool Name="GetProduct" Class="Learning.Tools.CatalogTools" Method="GetProduct">
    <Description>Obtiene los datos de catálogo, stock y garantía de un producto a partir de su SKU.</Description>
  </Tool>
  <Tool Name="ListOutOfStock" Class="Learning.Tools.CatalogTools" Method="ListOutOfStock">
    <Description>Lista los productos cuyo stock registrado es cero, sin modificar el catálogo.</Description>
  </Tool>
  <Tool Name="GetShipment" Class="Learning.Tools.ShipmentTools" Method="GetShipment">
    <Description>Consulta transportista, estado y último evento por tracking (ejemplo DHL-1002). Primero obtén trackingNumber con GetOrder. expectedDeliveryDate es sólo una estimación; actualDeliveryDate no consta, incluso si está Delivered. No calcules una fecha límite usando la estimación. Cita sourceRef como identificador, no como URL.</Description>
  </Tool>
</ToolSet>
}

}
