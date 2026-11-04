Include %occStatus

/// Creates a narrowly scoped Text-to-SQL agent for the four demo tables.
Class Learning.Agent.Analytics Extends %RegisteredObject
{

/// Default instructions for the analytics teaching agent.
Parameter INSTRUCTIONS = "Eres un asistente de analítica del dominio docente. Para cada pregunta analítica permitida debes usar RunQuery y responder con sus filas; no respondas diciendo que no tienes acceso sin intentar la herramienta. Usa SQL sólo para Learning_Data.Customer, Learning_Data.Product, Learning_Data.CustomerOrder y Learning_Data.Shipment. Genera una única consulta SELECT. No intentes modificar datos, llamar procedimientos ni explorar tablas fuera de este dominio. Las columnas principales son: Customer(ID, CustomerId, FullName, Email, CustomerTier); Product(ID, Sku, ProductName, Category, UnitPrice, StockQuantity, WarrantyMonths); CustomerOrder(ID, OrderRef, Customer, Product, Quantity, OrderStatus, OrderDate, TotalAmount, TrackingNumber); Shipment(ID, TrackingNumber, CustomerOrder, Carrier, ShipmentStatus, LastEvent, ExpectedDeliveryDate). Usa DescribeTable sólo para una de esas cuatro tablas si necesitas confirmación; nunca uses ListTables. Escribe la respuesta para una terminal: texto plano y líneas cortas. No uses bloques de código delimitados por ``` ni Markdown. Para una lista, usa una línea sencilla por elemento, sin sangría inicial.";

/// Create the analytics agent, attach the native SQL tool and its allow-list.
ClassMethod Create(Output agent As %AI.Agent, instructions As %String = "") As %Status
{
    Set sc = ##class(Learning.Agent.Basic).Create(.agent)
    Quit:$$$ISERR(sc) sc
    Try {
        Set agent.SystemPrompt = $Select(instructions '= "": instructions, 1: ..#INSTRUCTIONS)
        Set sc = agent.ToolManager.RegisterToolSet("Learning.ToolSet.ReadOnlyAnalytics")
        If $$$ISOK(sc) {
            Do agent.ToolManager.SetAuthPolicy(##class(Learning.Policy.SQLAllowList).%New())
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

}
