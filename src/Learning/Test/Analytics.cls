Include %occStatus

/// Deterministic authorization checks for the Text-to-SQL teaching policy.
Class Learning.Test.Analytics Extends %RegisteredObject
{

/// Run allowed and denied SQL checks without making an external model call.
ClassMethod Run() As %Status
{
    Set cases(1) = "SELECT OrderStatus, COUNT(*) FROM Learning_Data.CustomerOrder GROUP BY OrderStatus"
    Set cases(2) = "SELECT ProductName FROM Learning_Data.Product WHERE StockQuantity < 5"
    Set cases(3) = "SELECT o.OrderRef FROM Learning_Data.CustomerOrder o JOIN Learning_Data.Customer c ON o.Customer = c.ID WHERE c.FullName = 'Alice'"
    Set testError = ""
    For index = 1:1:3 {
        Set sc = ##class(Learning.Policy.SQLAllowList).ValidateSQL(cases(index))
        If $$$ISERR(sc) Set testError = sc
    }
    If testError '= "" Quit testError
    Set policy = ##class(Learning.Policy.SQLAllowList).%New()
    Set call = {}
    Do call.%Set("query", cases(1))
    Set sc = policy.%CanExecute("{""name"":""RunQuery""}", call, {})
    Quit:$$$ISERR(sc) sc
    Set sc = policy.%CanExecute("iris:%AI.Tools.SQL:RunQuery", call, {})
    Quit:$$$ISERR(sc) sc
    Set manager = ##class(%AI.ToolMgr).%New()
    Set sc = manager.RegisterToolSet("Learning.ToolSet.ReadOnlyAnalytics")
    Quit:$$$ISERR(sc) sc
    Set result = manager.ExecuteTool("RunQuery", call)
    If '$IsObject(result) Quit $$$ERROR($$$GeneralError, "The SQL tool returned no result object")
    If '$IsObject(result.value) Quit $$$ERROR($$$GeneralError, "The SQL tool returned no rows object")
    If result.value.%Get("row_count") < 1 Quit $$$ERROR($$$GeneralError, "The SQL tool returned no demo rows")
    Set nestedArguments = {}
    Do nestedArguments.%Set("query", cases(1))
    Set nestedCall = {}
    Do nestedCall.%Set("arguments", nestedArguments)
    Set sc = policy.%CanExecute("{""name"":""RunQuery""}", nestedCall, {})
    Quit:$$$ISERR(sc) sc
    Set sc = ##class(Learning.Policy.SQLAllowList).ValidateSQL("DELETE FROM Learning_Data.CustomerOrder")
    If $$$ISOK(sc) Quit $$$ERROR($$$GeneralError, "DELETE must be denied")
    Set sc = ##class(Learning.Policy.SQLAllowList).ValidateSQL("SELECT Name FROM %Dictionary.CompiledClass")
    If $$$ISOK(sc) Quit $$$ERROR($$$GeneralError, "System tables must be denied")
    Write "Analytics authorization checks passed.", !
    Quit $$$OK
}

}
