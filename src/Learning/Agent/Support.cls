Include %occStatus

/// Creates the support agent with the reviewed read-only ToolSet and policy.
Class Learning.Agent.Support Extends %RegisteredObject
{

/// Create the support agent and attach its declarative read-only ToolSet and policy.
ClassMethod Create(Output agent As %AI.Agent) As %Status
{
    Set sc = ##class(Learning.Agent.Basic).Create(.agent)
    Quit:$$$ISERR(sc) sc
    Try {
        Set agent.SystemPrompt = "Eres un asistente de soporte. Usa herramientas para pedidos, productos y envíos. Para localizar un pedido, llama primero a GetOrder. Espera su resultado y usa exclusivamente su trackingNumber para llamar después a GetShipment; una referencia ORD-xxx no es un tracking. No llames GetShipment en paralelo con GetOrder si aún no conoces el tracking. Si una consulta no encuentra datos pero tienes un identificador válido en otra herramienta, vuelve a consultar con ese identificador antes de responder. Si el usuario menciona un pedido, consulta GetOrder para verificar su estado aunque el usuario lo haya indicado. Para políticas usa la base de conocimiento con consultas sobre la norma, sin referencias de pedido ni SKU. No afirmes un plazo ni una condición si los fragmentos recuperados no incluyen esa regla; reformula la búsqueda o indica que falta evidencia. Si falta evidencia, dilo claramente. No confirmes que una devolución está en plazo sin conocer la fecha real de entrega; distingue la regla general de la elegibilidad del pedido."
        Set agent.SystemPrompt = agent.SystemPrompt _ ..EvidenceInstructions()
        Do agent.ToolManager.AddTool(##class(Learning.ToolSet.ReadOnlySupport).%New())
        Do agent.ToolManager.SetAuthPolicy(##class(Learning.Policy.ReadOnlySupport).%New())
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Create the same governed support agent, packaging its instructions and ToolSet as a reusable skill.
ClassMethod CreateWithSkill(Output agent As %AI.Agent) As %Status
{
    Set sc = ##class(Learning.Agent.Basic).Create(.agent)
    Quit:$$$ISERR(sc) sc
    Try {
        Set sc = agent.UseSkill("Learning.Skill.SupportWorkflow")
        $$$ThrowOnError(sc)
        Set agent.SystemPrompt = agent.SystemPrompt _ " Antes de atender una consulta de soporte, activa la skill support-workflow mediante load_skill con el identificador Learning.Skill.SupportWorkflow. Sigue sus instrucciones y usa sus herramientas para verificar los datos."
        Set agent.SystemPrompt = agent.SystemPrompt _ ..EvidenceInstructions()
        Do agent.ToolManager.SetAuthPolicy(##class(Learning.Policy.ReadOnlySupport).%New())
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Shared evidence rules apply to both the direct agent and the skill-based variant.
ClassMethod EvidenceInstructions() As %String [ Private ]
{
    Quit " Respeta dateSemantics y los null de las herramientas: purchaseDate es compra, expectedDeliveryDate es estimación; ninguna es fecha real de envío o entrega. Si actualDeliveryDate es null y returnEligibility es unknown, di que falta la fecha real de entrega para confirmar si puede devolverlo y calcular el límite. Puedes explicar sólo el plazo general documentado, sin decir que ese pedido está dentro del plazo. No inventes fechas ni condiciones ausentes de la evidencia. Cita sourceRef para datos y metadata.source para Markdown como texto entre corchetes. Genera enlaces sólo si sourceUrl contiene una URL explícita; null significa que no hay URL."
}

}
