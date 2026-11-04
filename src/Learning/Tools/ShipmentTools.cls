/// Read-only shipment queries exposed to AI Hub.
Class Learning.Tools.ShipmentTools Extends %AI.Tool
{

/// Query a shipment by carrier tracking (for example DHL-1002), never by order reference.
/// First call GetOrder and use its trackingNumber result when only an ORD reference is known.
/// expectedDeliveryDate is only an estimate; actual shipment/delivery dates are not recorded.
Method GetShipment(trackingNumber As %String) As %DynamicObject
{
    Set result = {}
    Set shipment = ##class(Learning.Data.Shipment).TrackingIdxOpen(trackingNumber)
    If '$IsObject(shipment) {
        Do result.%Set("found", 0)
        Do result.%Set("trackingNumber", trackingNumber)
        Return result
    }
    Do result.%Set("found", 1)
    Do result.%Set("trackingNumber", shipment.TrackingNumber)
    Do result.%Set("carrier", shipment.Carrier)
    Do result.%Set("status", shipment.ShipmentStatus)
    Do result.%Set("lastEvent", shipment.LastEvent)
    If shipment.ExpectedDeliveryDate = "" {
        Do result.%Set("expectedDeliveryDate", "", "null")
    } Else {
        Do result.%Set("expectedDeliveryDate", $ZDATE(shipment.ExpectedDeliveryDate, 3))
    }
    Do result.%Set("shippedDate", "", "null")
    Do result.%Set("actualDeliveryDate", "", "null")
    Do result.%Set("returnDeadline", "", "null")
    Do result.%Set("returnEligibility", "unknown")
    Set dateSemantics = {}
    Do dateSemantics.%Set("expectedDeliveryDate", "Fecha estimada, no fecha real de entrega. No sirve para calcular el plazo de devolución.")
    Do dateSemantics.%Set("actualDeliveryDate", "No consta en la base. El estado Delivered confirma una entrega, pero no indica cuándo ocurrió.")
    Do result.%Set("dateSemantics", dateSemantics)
    Do result.%Set("orderRef", shipment.CustomerOrder.OrderRef)
    Do result.%Set("source", "Learning_Data.Shipment")
    Do result.%Set("sourceRef", "Learning_Data.Shipment:"_shipment.TrackingNumber)
    Do result.%Set("sourceUrl", "", "null")
    Return result
}

}
