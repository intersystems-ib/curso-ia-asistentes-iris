Include %AI

/// Restricts the teaching SQL tool to read-only queries on the demo domain.
/// This is deliberately small and transparent, not a general SQL firewall.
Class Learning.Policy.SQLAllowList Extends %AI.Policy.Authorization
{

/// Authorize SQL tool calls only when their statement or table is in scope.
Method %CanExecute(tool As %String, call As %DynamicObject, metadata As %DynamicObject) As %Status
{
    // AI Hub passes a tool reference, not a JSON specification.
    Set method = tool
    If $Extract(tool, 1) = "{" {
        Set specification = {}.%FromJSON(tool)
        Set method = specification.%Get("name")
    }
    Set method = $Piece(method, ":", $Length(method, ":"))
    If method = "RunQuery" {
        Set sql = ..CallValue(call, "query")
        If sql = "" Set sql = ..CallValue(call, "sql")
        Quit ..ValidateSQL(sql)
    }
    If (method = "DescribeTable") || (method = "SampleRows") {
        Set table = ..CallValue(call, "table")
        If table = "" Set table = ..CallValue(call, "tableName")
        Quit ..ValidateTable(table)
    }
    Quit $$$ERROR($$$AICoreToolAccessDenied, "SQL tool operation is not allowed: "_method)
}

/// Validate one SQL statement before the tool can submit it to IRIS.
ClassMethod ValidateSQL(sql As %String) As %Status
{
    Set normalized = $ZCONVERT($ZSTRIP(sql, "<>W"), "U")
    If normalized = "" Quit $$$ERROR($$$AICoreToolAccessDenied, "The SQL statement is empty")
    If $Extract(normalized, 1, 6) '= "SELECT" Quit $$$ERROR($$$AICoreToolAccessDenied, "Only SELECT statements are allowed")
    If $Find(normalized, ";") Quit $$$ERROR($$$AICoreToolAccessDenied, "Multiple SQL statements are not allowed")
    Set forbiddenError = ""
    For index = 1:1:$Length("INSERT,UPDATE,DELETE,MERGE,CREATE,ALTER,DROP,TRUNCATE,CALL,EXECUTE,GRANT,REVOKE", ",") {
        Set forbidden = $Piece("INSERT,UPDATE,DELETE,MERGE,CREATE,ALTER,DROP,TRUNCATE,CALL,EXECUTE,GRANT,REVOKE", ",", index)
        If $Find(normalized, forbidden) Set forbiddenError = forbidden
    }
    If forbiddenError '= "" Quit $$$ERROR($$$AICoreToolAccessDenied, "SQL operation is not allowed: "_forbiddenError)
    Set tokens = $Translate(normalized, ",()=<>+-*/""", "             ")
    Set validationError = ""
    For position = 1:1:$Length(tokens, " ") {
        Set token = $Piece(tokens, " ", position)
        If (token = "FROM") || (token = "JOIN") {
            Set table = $Piece(tokens, " ", position + 1)
            Set sc = ..ValidateTable(table)
            If $$$ISERR(sc) Set validationError = $System.Status.GetErrorText(sc)
        }
    }
    If validationError '= "" Quit $$$ERROR($$$AICoreToolAccessDenied, validationError)
    Quit $$$OK
}

/// Accept a fully qualified demo table name, with or without SQL quoting.
ClassMethod ValidateTable(table As %String) As %Status
{
    Set normalized = $ZCONVERT($ZSTRIP(table, "<>W"), "U")
    If (normalized = "LEARNING_DATA.CUSTOMER") || (normalized = "LEARNING_DATA.PRODUCT") || (normalized = "LEARNING_DATA.CUSTOMERORDER") || (normalized = "LEARNING_DATA.SHIPMENT") {
        Quit $$$OK
    }
    Quit $$$ERROR($$$AICoreToolAccessDenied, "Table is outside the analytics demo domain: "_table)
}

/// Read a named argument safely from the dynamic call received from AI Hub.
ClassMethod CallValue(call As %DynamicObject, name As %String) As %String
{
    Set value = ""
    If '$IsObject(call) Quit value
    If call.%IsDefined(name) Set value = call.%Get(name)
    If (value = "") && call.%IsDefined("arguments") {
        Set arguments = call.%Get("arguments")
        If '$IsObject(arguments) && (arguments '= "") {
            Try {
                Set arguments = {}.%FromJSON(arguments)
            } Catch ex {
                Set arguments = ""
            }
        }
        If $IsObject(arguments) && arguments.%IsDefined(name) Set value = arguments.%Get(name)
    }
    Quit value
}

}
