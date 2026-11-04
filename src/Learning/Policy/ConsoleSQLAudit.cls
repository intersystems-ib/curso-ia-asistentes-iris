Include %occStatus

/// Prints the complete SQL statement for the Text-to-SQL teaching lab.
/// Unlike persistent auditing, this only writes to the current terminal.
Class Learning.Policy.ConsoleSQLAudit Extends %AI.Policy.Audit
{

/// Display a compact tool trace and the full SQL before showing the result summary.
Method %LogExecution(call As %DynamicObject, metadata As %DynamicObject, result As %DynamicObject, duration As %Integer, status As %Status) As %Status
{
    Set toolName = "tool"
    If $IsObject(metadata) && metadata.%IsDefined("name") Set toolName = metadata.%Get("name")
    Set query = ##class(Learning.Policy.SQLAllowList).CallValue(call, "query")
    If query '= "" Set toolName = "RunQuery"
    Write !, "[AI Hub] ", toolName, " (", duration, " ms)", !
    If query '= "" {
        Write "SQL> ", query, !
    } ElseIf $IsObject(call) {
        Write "Argumentos> ", call.%ToJSON(), !
    }
    If $$$ISERR(status) {
        Write "Resultado> ERROR: ", $System.Status.GetErrorText(status), !
    } ElseIf $IsObject(result) && result.%IsDefined("row_count") {
        Write "Resultado> ", result.row_count, " filas", !
    }
    Quit $$$OK
}

}
