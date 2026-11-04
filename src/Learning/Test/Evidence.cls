Include %occStatus

/// Check factual date distinctions and source identifiers without calling an LLM or writing data.
Class Learning.Test.Evidence Extends %RegisteredObject
{

ClassMethod Run() As %Status
{
    Set orders = ##class(Learning.Tools.OrderTools).%New()
    Set shipments = ##class(Learning.Tools.ShipmentTools).%New()
    For index = 2:1:3 {
        Set reference = "ORD-00"_index
        Set order = orders.GetOrder(reference)
        If 'order.%Get("found") Return $$$ERROR($$$GeneralError, "Missing evidence fixture: "_reference)
        Set sc = ..CheckUnknownDates(order)
        If $$$ISERR(sc) Return sc
        If order.%Get("sourceRef") '= ("Learning_Data.CustomerOrder:"_reference) {
            Return $$$ERROR($$$GeneralError, "Order citation does not identify its record")
        }
        Set shipment = shipments.GetShipment(order.%Get("trackingNumber"))
        If 'shipment.%Get("found") Return $$$ERROR($$$GeneralError, "Missing shipment fixture")
        Set sc = ..CheckUnknownDates(shipment)
        If $$$ISERR(sc) Return sc
        If shipment.%Get("sourceRef") '= ("Learning_Data.Shipment:"_order.%Get("trackingNumber")) {
            Return $$$ERROR($$$GeneralError, "Shipment citation does not identify its record")
        }
    }
    // A Delivered status must not turn the purchase date or estimate into a real delivery date.
    If order.%Get("purchaseDate") '= "2026-08-02" Return $$$ERROR($$$GeneralError, "Purchase date changed")
    If shipment.%Get("expectedDeliveryDate") '= "2026-08-05" Return $$$ERROR($$$GeneralError, "Delivery estimate changed")
    If shipment.%Get("status") '= "Delivered" Return $$$ERROR($$$GeneralError, "Delivered fixture changed")
    Set product = ##class(Learning.Tools.CatalogTools).%New().GetProduct("SKU-AUD-001")
    If product.%Get("sourceRef") '= "Learning_Data.Product:SKU-AUD-001" Return $$$ERROR($$$GeneralError, "Missing product citation")
    If product.%GetTypeOf("sourceUrl") '= "null" Return $$$ERROR($$$GeneralError, "A local record must not invent a web URL")
    Write "Evidence checks passed: purchase, estimate and unknown actual dates remain distinct; citations identify local records.", !
    Return $$$OK
}

ClassMethod CheckUnknownDates(facts As %DynamicObject) As %Status [ Private ]
{
    For field = "shippedDate", "actualDeliveryDate", "returnDeadline", "sourceUrl" {
        If 'facts.%IsDefined(field) Return $$$ERROR($$$GeneralError, "Unknown evidence field must be explicit: "_field)
        If facts.%GetTypeOf(field) '= "null" Return $$$ERROR($$$GeneralError, "Unknown evidence must be JSON null: "_field)
    }
    If facts.%Get("returnEligibility") '= "unknown" Return $$$ERROR($$$GeneralError, "A missing actual delivery date cannot establish return eligibility")
    If '$IsObject(facts.%Get("dateSemantics")) Return $$$ERROR($$$GeneralError, "Missing explanation of date meanings")
    Return $$$OK
}

}
