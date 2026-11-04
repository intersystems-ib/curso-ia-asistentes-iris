Include %occStatus

/// Local smoke checks that never write data, call an external model, or reveal secrets.
Class Learning.Test.Smoke Extends %RegisteredObject
{

/// Verify the minimum components required by the first labs.
ClassMethod Run() As %Status
{
    If '##class(%Dictionary.ClassDefinition).%ExistsId("%AI.Agent") {
        Return $$$ERROR($$$GeneralError, "%AI.Agent is not available")
    }
    Set customer = ##class(Learning.Data.Customer).CustomerIdIdxOpen("CUS-001")
    Set product = ##class(Learning.Data.Product).SkuIdxOpen("SKU-AUD-001")
    Set order = ##class(Learning.Data.CustomerOrder).OrderRefIdxOpen("ORD-001")
    If '$IsObject(customer) || '$IsObject(product) || '$IsObject(order) {
        Return $$$ERROR($$$GeneralError, "The demo domain data is missing; run ##class(Learning.Bootstrap).LoadDemoData() first")
    }
    Write "Local smoke test passed.", !
    Write "OPENROUTER_API_KEY available: ", $SELECT($SYSTEM.Util.GetEnviron("OPENROUTER_API_KEY") = "": "no", 1: "yes"), !
    Return $$$OK
}

}
