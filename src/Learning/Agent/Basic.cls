Include %occStatus

/// Creates AI Hub agents using OpenRouter and credentials from the environment.
Class Learning.Agent.Basic Extends %RegisteredObject
{

/// Shared default model for the Python labs and native agents.
Parameter MODEL = "openai/gpt-oss-20b";

/// Create OpenRouter without exposing its key or falling back to another provider.
ClassMethod CreateProvider(Output provider As %AI.Provider) As %Status
{
    Set apiKey = $SYSTEM.Util.GetEnviron("OPENROUTER_API_KEY")
    If apiKey = "" {
        Quit $$$ERROR($$$GeneralError, "Set OPENROUTER_API_KEY in .env and recreate the container to use an AI Hub agent")
    }
    Set sc = $$$OK
    Try {
        Set settings = {}
        Do settings.%Set("api_key", apiKey)
        Set provider = ##class(%AI.Provider).Create("openrouter", settings)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Create a base AI Hub agent with the common model and Spanish safety prompt.
ClassMethod Create(Output agent As %AI.Agent) As %Status
{
    Set sc = ..CreateProvider(.provider)
    Quit:$$$ISERR(sc) sc
    Set agent = ##class(%AI.Agent).%New(provider)
    Set model = $SYSTEM.Util.GetEnviron("OPENROUTER_MODEL")
    If model = "" {
        Set model = ..#MODEL
    }
    Set agent.Model = model
    Set agent.SystemPrompt = "Responde en español. No inventes datos ni ejecutes escrituras. Indica la fuente de cada dato recuperado."
    Quit $$$OK
}

}
