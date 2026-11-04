Include %occStatus

/// Explicit installer for the local REST adapter used only by the UI extension.
Class Learning.REST.Setup Extends %RegisteredObject
{

Parameter ApplicationName = "/api/support";

/// Create the local unauthenticated CSP application without changing support data.
/// This teaching-only endpoint must never be exposed outside the local Docker setup.
ClassMethod Install() As %Status
{
    Set sc = $$$OK
    Set originalNamespace = $Namespace
    Try {
        Set $Namespace = "%SYS"
        Set applicationProperties("NameSpace") = "USER"
        // 64 enables the Unauthenticated option in the CSP application settings.
        Set applicationProperties("AutheEnabled") = 64
        // :%All lets the local unauthenticated application enter USER for this demo.
        Set applicationProperties("MatchRoles") = ":%All"
        Set applicationProperties("Enabled") = 1
        Set applicationProperties("DispatchClass") = "Learning.REST.SupportService"
        Set applicationProperties("Type") = 2
        If ##class(Security.Applications).Exists(..#ApplicationName) {
            Set sc = ##class(Security.Applications).Modify(..#ApplicationName, .applicationProperties)
        } Else {
            Set sc = ##class(Security.Applications).Create(..#ApplicationName, .applicationProperties)
        }
        $$$ThrowOnError(sc)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Set $Namespace = originalNamespace
    Quit sc
}

/// Confirm that the service class is compiled without changing web configuration.
ClassMethod Check() As %Status
{
    If '##class(%Dictionary.ClassDefinition).%ExistsId("Learning.REST.SupportService") {
        Quit $$$ERROR($$$GeneralError, "Learning.REST.SupportService is not compiled")
    }
    Write "REST support service class is ready.", !
    Quit $$$OK
}

}
