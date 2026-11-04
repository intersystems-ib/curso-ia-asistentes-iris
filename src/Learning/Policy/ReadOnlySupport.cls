Include %AI

/// Defense in depth: allow only read-only support tools even if a ToolSet changes.
Class Learning.Policy.ReadOnlySupport Extends %AI.Policy.Authorization
{

/// Allow the four named support tools and the explicit read-only policy search tool.
Method %CanExecute(tool As %String, call As %DynamicObject, metadata As %DynamicObject) As %Status
{
    // AI Hub passes a tool reference, not a JSON specification.
    Set method = tool
    If $Extract(tool, 1) = "{" {
        Set specification = {}.%FromJSON(tool)
        Set method = specification.%Get("name")
    }
    Set method = $Piece(method, ":", $Length(method, ":"))
    If $ListFind($ListBuild("GetOrder", "GetProduct", "GetShipment", "ListOutOfStock", "search_support_policies"), method) {
        Quit $$$OK
    }
    Quit $$$ERROR($$$AICoreToolAccessDenied, "Only read-only support tools are allowed: "_tool)
}

}
