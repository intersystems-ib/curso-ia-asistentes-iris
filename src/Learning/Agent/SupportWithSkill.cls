Include %occStatus

/// Same support capability, disclosed through a skill instead of direct tools.
Class Learning.Agent.SupportWithSkill Extends Learning.Agent.Basic
{

Parameter SKILLS = "Learning.Skill.SupportWorkflow";

XData INSTRUCTIONS [ MimeType = text/markdown ]
{
Eres un asistente de soporte.
Antes de atender una consulta de soporte, activa `support-workflow` mediante
`load_skill` con el identificador `Learning.Skill.SupportWorkflow`.
Sigue sus instrucciones y verifica los datos con sus herramientas.
}

Method %OnInit() As %Status
{
    Set sc = ##super()
    If $$$ISERR(sc) Return sc
    Do ..ToolManager.SetAuthPolicy(##class(Learning.Policy.ReadOnlySupport).%New())
    Return $$$OK
}

}
