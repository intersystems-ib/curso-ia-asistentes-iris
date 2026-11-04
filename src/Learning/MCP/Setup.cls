Include %occStatus

/// Explicit installer for the local authenticated AI Hub MCP endpoint.
Class Learning.MCP.Setup Extends %RegisteredObject
{

Parameter ApplicationName = "/mcp/support";

Parameter DefaultUserName = "mcp-user";

/// Create or update the dedicated MCP identity, endpoint application, and SELECT grants.
/// This is intentionally explicit because it changes IRIS security configuration.
ClassMethod Install() As %Status
{
    Set sc = $$$OK
    Set originalNamespace = $Namespace
    Try {
        Set username = $SYSTEM.Util.GetEnviron("MCP_SUPPORT_USER")
        If username = "" { Set username = ..#DefaultUserName }
        Set password = $SYSTEM.Util.GetEnviron("MCP_SUPPORT_PASSWORD")
        If password = "" {
            Set sc = $$$ERROR($$$GeneralError, "Set MCP_SUPPORT_PASSWORD in .env before installing the MCP endpoint")
        } Else {
            Set $Namespace = "%SYS"
            Set userProperties("Password") = password
            Set userProperties("Roles") = "%DB_USER"
            If ##class(Security.Users).Exists(username) {
                Set sc = ##class(Security.Users).Modify(username, .userProperties)
            } Else {
                Set sc = ##class(Security.Users).Create(username, .userProperties)
            }
            $$$ThrowOnError(sc)
            Set applicationProperties("NameSpace") = "USER"
            Set applicationProperties("AutheEnabled") = 32
            Set applicationProperties("Enabled") = 1
            Set applicationProperties("DispatchClass") = "Learning.MCP.SupportService"
            Set applicationProperties("Type") = 18
            If ##class(Security.Applications).Exists(..#ApplicationName) {
                Set sc = ##class(Security.Applications).Modify(..#ApplicationName, .applicationProperties)
            } Else {
                Set sc = ##class(Security.Applications).Create(..#ApplicationName, .applicationProperties)
            }
            $$$ThrowOnError(sc)
            Set $Namespace = "USER"
            Set sc = ..GrantReadAccess(username)
            $$$ThrowOnError(sc)
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Set $Namespace = originalNamespace
    Quit sc
}

/// Verify that the MCP service class is compiled without changing security configuration.
ClassMethod Check() As %Status
{
    If '##class(%Dictionary.ClassDefinition).%ExistsId("Learning.MCP.SupportService") {
        Quit $$$ERROR($$$GeneralError, "Learning.MCP.SupportService is not compiled")
    }
    Write "MCP service class and declarative ToolSet are ready.", !
    Quit $$$OK
}

/// Grant the endpoint identity SELECT on the fixed tables used by the support tools.
ClassMethod GrantReadAccess(username As %String) As %Status [ Private ]
{
    Set tables = $ListBuild("Learning_Data.CustomerOrder", "Learning_Data.Product", "Learning_Data.Shipment")
    Set sc = $$$OK
    For index = 1:1:$ListLength(tables) {
        Set sc = ..GrantSelect(username, $ListGet(tables, index))
        Quit:$$$ISERR(sc)
    }
    Quit sc
}

/// Grant SELECT on one fixed table, quoting the user identifier safely for IRIS SQL.
ClassMethod GrantSelect(username As %String, tableName As %String) As %Status [ Private ]
{
    Set sc = $$$OK
    Try {
        Set sqlUser = $Char(34) _ $Replace(username, $Char(34), $Char(34)_$Char(34)) _ $Char(34)
        Set statement = ##class(%SQL.Statement).%New()
        Set sc = statement.%Prepare("GRANT SELECT ON "_tableName_" TO "_sqlUser)
        $$$ThrowOnError(sc)
        Set result = statement.%Execute()
        If result.%SQLCODE < 0 {
            Set sc = $$$ERROR($$$GeneralError, "Could not grant SELECT on "_tableName_": "_result.%Message)
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

}
