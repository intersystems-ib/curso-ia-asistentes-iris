Include %occStatus

/// Local JSON endpoint that sends one support question to the AI Hub agent.
/// This class is an optional adapter for the UI extension, not a production API.
Class Learning.REST.SupportService Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/chat" Method="POST" Call="Chat"/>
</Routes>
}

/// Receive {"question":"..."}, ask the governed support agent, and return JSON.
ClassMethod Chat() As %Status
{
    Set sc = $$$OK
    Try {
        Set request = {}.%FromJSON(%request.Content.Read())
        Set question = $ZSTRIP(request.%Get("question", ""), "<W")
        If question = "" {
            Set %response.Status = 400
            Set payload = {"error":"El campo question es obligatorio."}
            Do ..WriteJson(payload)
        } Else {
            Set sc = ##class(Learning.Agent.Support).Create(.agent)
            $$$ThrowOnError(sc)
            Set session = agent.CreateSession()
            Set agentResponse = agent.Chat(session, question)
            Set payload = {"citations":[], "abstained":0}
            Do payload.%Set("answer", agentResponse.Content)
            Do ..WriteJson(payload)
        }
    } Catch ex {
        Set %response.Status = 503
        Set payload = {}
        Do payload.%Set("error", ex.DisplayString())
        Do ..WriteJson(payload)
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Serialize a dynamic response and make its media type explicit.
ClassMethod WriteJson(payload As %DynamicObject) As %Status [ Private ]
{
    Set %response.ContentType = "application/json"
    Do payload.%ToJSON()
    Quit $$$OK
}

}
