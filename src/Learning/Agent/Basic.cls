Include %occStatus

/// Shared OpenRouter configuration and evidence rules for the teaching agents.
Class Learning.Agent.Basic Extends %AI.Agent
{

Parameter PROVIDER = "openrouter";
Parameter APIKEY = "@{env:OPENROUTER_API_KEY}";
Parameter MODEL = "openai/gpt-oss-20b";

XData INSTRUCTIONS [ MimeType = text/markdown ]
{
## Reglas comunes

- Responde en español. No inventes datos ni ejecutes escrituras.
- Usa la evidencia recuperada y reconoce cuándo falta información.
- Cita los registros con `sourceRef` y los documentos con `metadata.source`, entre corchetes.
- Sólo genera enlaces si `sourceUrl` contiene una URL explícita. Un null no es una URL.
}

/// XData overrides inherited instructions. Prepend the base rules explicitly.
/// Stored configurations supply their own model, independent of the environment.
Method %OnInit() As %Status
{
    If ..#PROVIDERCONFIG = "" {
        If $SYSTEM.Util.GetEnviron("OPENROUTER_API_KEY") = "" {
            Return $$$ERROR($$$GeneralError, "Configura OPENROUTER_API_KEY en .env y recrea el contenedor")
        }
        Set model = $SYSTEM.Util.GetEnviron("OPENROUTER_MODEL")
        If model '= "" Set ..Model = model
    }
    If $ClassName($This) '= "Learning.Agent.Basic" {
        Set xdata = ##class(%Dictionary.CompiledXData).IDKEYOpen("Learning.Agent.Basic", "INSTRUCTIONS")
        If '$IsObject(xdata) Return $$$ERROR($$$GeneralError, "No se encuentran las instrucciones comunes")
        Set common = ""
        Do xdata.Data.Rewind()
        While 'xdata.Data.AtEnd {
            Set common = common _ xdata.Data.ReadLine() _ $Char(10)
        }
        Set ..SystemPrompt = common _ $Char(10) _ ..SystemPrompt
    }
    Return $$$OK
}

}
