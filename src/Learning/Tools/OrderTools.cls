/// Read-only order queries exposed to AI Hub.
Class Learning.Tools.OrderTools Extends %AI.Tool
{

/// Return order facts. purchaseDate is the purchase date, never a shipment or delivery date.
/// Actual shipment/delivery dates and the return deadline are not recorded and remain unknown.
Method GetOrder(orderRef As %String) As %DynamicObject
{
    Set result = {}
    Set order = ##class(Learning.Data.CustomerOrder).OrderRefIdxOpen(orderRef)
    If '$IsObject(order) {
        Do result.%Set("found", 0)
        Do result.%Set("orderRef", orderRef)
        Return result
    }
    Do result.%Set("found", 1)
    Do result.%Set("orderRef", order.OrderRef)
    Do result.%Set("status", order.OrderStatus)
    Do result.%Set("purchaseDate", $ZDATE(order.OrderDate, 3))
    Do result.%Set("shippedDate", "", "null")
    Do result.%Set("actualDeliveryDate", "", "null")
    Do result.%Set("returnDeadline", "", "null")
    Do result.%Set("returnEligibility", "unknown")
    Set dateSemantics = {}
    Do dateSemantics.%Set("purchaseDate", "Fecha de compra o creación del pedido. No es fecha de envío ni de entrega.")
    Do dateSemantics.%Set("actualDeliveryDate", "No consta en la base, incluso si status es Delivered. No se puede calcular ni confirmar el plazo de devolución de este pedido.")
    Do result.%Set("dateSemantics", dateSemantics)
    Do result.%Set("quantity", order.Quantity)
    Do result.%Set("totalAmount", order.TotalAmount)
    Do result.%Set("trackingNumber", order.TrackingNumber)
    Do result.%Set("customer", order.Customer.FullName)
    Do result.%Set("product", order.Product.ProductName)
    Do result.%Set("source", "Learning_Data.CustomerOrder")
    Do result.%Set("sourceRef", "Learning_Data.CustomerOrder:"_order.OrderRef)
    Do result.%Set("sourceUrl", "", "null")
    Return result
}

}
