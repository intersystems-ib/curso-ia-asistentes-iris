Include %occStatus

/// Deterministic checks for the read-only AI Hub support surface.
Class Learning.Test.Support Extends %RegisteredObject
{

/// Check an authorized read and a denied write-like tool call without modifying demo data.
ClassMethod Run() As %Status
{
    Set order = ##class(Learning.Tools.OrderTools).%New().GetOrder("ORD-002")
    If 'order.%Get("found") || (order.%Get("orderRef") '= "ORD-002") {
        Quit $$$ERROR($$$GeneralError, "The authorized order query did not return ORD-002")
    }
    Set policy = ##class(Learning.Policy.ReadOnlySupport).%New()
    Set allowedTool = {"name":"GetOrder"}.%ToJSON()
    Set sc = policy.%CanExecute(allowedTool, {"arguments":"{}"}, {})
    If $$$ISERR(sc) { Quit sc }
    Set sc = policy.%CanExecute("iris:Learning.Tools.OrderTools:GetOrder", {"arguments":"{}"}, {})
    If $$$ISERR(sc) { Quit sc }
    Set sc = policy.%CanExecute("GetUnapprovedData", {}, {})
    If $$$ISOK(sc) { Quit $$$ERROR($$$GeneralError, "An unlisted Get tool must be denied") }
    Set manager = ##class(%AI.ToolMgr).%New()
    Do manager.AddTool(##class(Learning.ToolSet.ReadOnlySupport).%New())
    Set result = manager.ExecuteTool("GetOrder", {"orderRef":"ORD-002"})
    If '$IsObject(result) { Quit $$$ERROR($$$GeneralError, "ToolManager returned no object") }
    If '$IsObject(result.value) { Quit $$$ERROR($$$GeneralError, "ToolManager returned no order") }
    If result.value.%Get("orderRef") '= "ORD-002" { Quit $$$ERROR($$$GeneralError, "ToolManager did not execute the authorized order query") }
    Set deniedTool = {"name":"CreateOrder"}.%ToJSON()
    Set sc = policy.%CanExecute(deniedTool, {"arguments":"{}"}, {})
    If $$$ISERR(sc) {
        Write "Support checks passed: authorized read and denied write.", !
        Quit $$$OK
    }
    Quit $$$ERROR($$$GeneralError, "A write-like tool was not denied")
}

}
