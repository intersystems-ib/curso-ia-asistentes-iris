Include %occStatus

/// Lab 05 only: select an approved policy by topic or expand native semantic hits.
Class Learning.Knowledge.PolicyDocuments Extends %AI.ToolSet
{

Property SearchManager As %AI.ToolMgr [ Private ];

/// Keep the native knowledge base alive while its generated tool is in use.
Property KnowledgeBase As %AI.RAG.KnowledgeBase [ Private ];

XData Definition [ MimeType = application/xml ]
{
<ToolSet Name="Lab05PolicyDocuments">
  <Tool Name="search_support_policies" Method="Search">
    <Description>Recupera políticas COMPLETAS. Selecciona topic según la norma solicitada: garantia, devoluciones, cancelaciones, envios, cambios, productos o general. Un tema concreto lee su política autorizada completa y no usa query para elegir otro documento. Para preguntas de cobertura o exclusiones usa garantia, aunque el producto tenga cancelación de ruido. general busca semánticamente con query en español y devuelve hasta dos fuentes; no incluyas SKU ni referencias de pedido en esa consulta. Cita metadata.source como archivo, sin inventar enlaces. No confirma fechas ni elegibilidad.</Description>
  </Tool>
</ToolSet>
}

/// Register only this wrapper on the Lab 05 agent; the native search stays in a private manager.
ClassMethod AddToAgent(agent As %AI.Agent, knowledgeBase As %AI.RAG.KnowledgeBase) As %Status
{
    Set sc = $$$OK
    Try {
        Set tool = ..%New()
        Set tool.KnowledgeBase = knowledgeBase
        Set tool.SearchManager = ##class(%AI.ToolMgr).%New()
        Set sc = knowledgeBase.AddToManager(tool.SearchManager)
        $$$ThrowOnError(sc)
        Set sc = agent.ToolManager.AddTool(tool)
        $$$ThrowOnError(sc)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

/// A named topic selects one approved policy; general retains native semantic discovery.
Method Search(query As %String = "", topic As %String = "general") As %DynamicArray
{
    If topic '= "general" {
        Set source = ..TopicSource(topic)
        If source = "" {
            $$$ThrowOnError($$$ERROR($$$GeneralError, "Unknown policy topic; use garantia, devoluciones, cancelaciones, envios, cambios, productos or general"))
        }
        Set documents = []
        Do documents.%Push(..ReadDocument(source, "topic"))
        Return documents
    }
    If $ZStrip(query, "<>W") = "" Return []
    Set arguments = {}
    Do arguments.%Set("query", query)
    Set result = ..SearchManager.ExecuteTool("search_support_policies", arguments)
    If '$IsObject(result.value) {
        $$$ThrowOnError($$$ERROR($$$GeneralError, "Native policy search did not return a result array"))
    }
    Return ..ExpandHits(result.value)
}

/// Exact topic allow-list. A tool argument can never become an arbitrary file path.
ClassMethod TopicSource(topic As %String) As %String
{
    Return $Case(topic, "garantia":"warranty-policy.md", "devoluciones":"returns-policy.md", "cancelaciones":"cancellation-policy.md", "envios":"delivery-policy.md", "cambios":"order-changes-policy.md", "productos":"product-guide.md", :"")
}

/// Read the approved source and describe whether selection came from a topic or a search hit.
ClassMethod ReadDocument(source As %String, selection As %String, matchedChunkId As %String = "") As %DynamicObject [ Private ]
{
    Set sc = ##class(Learning.Knowledge.SupportRAG).ReadPolicy(source, .text)
    $$$ThrowOnError(sc)
    Set metadata = {}
    Do metadata.%Set("source", source)
    Do metadata.%Set("sourceType", "local_markdown")
    Do metadata.%Set("sourcePath", "datos-demo/knowledge/"_source)
    Do metadata.%Set("sourceUrl", "", "null")
    Do metadata.%Set("retrievalMode", "full_document")
    Do metadata.%Set("selection", selection)
    Set document = {}
    Do document.%Set("id", source)
    Do document.%Set("text", text)
    Do document.%Set("metadata", metadata)
    If matchedChunkId '= "" Do document.%Set("matchedChunkId", matchedChunkId)
    Return document
}

/// Expand by first occurrence (native relevance order), deduplicate, and reject unknown sources.
ClassMethod ExpandHits(hits As %DynamicArray) As %DynamicArray
{
    Set documents = []
    Set iterator = hits.%GetIterator()
    While iterator.%GetNext(.index, .hit) {
        Continue:'$IsObject(hit)
        Set metadata = hit.%Get("metadata")
        Continue:'$IsObject(metadata)
        Set source = metadata.%Get("source")
        Continue:'$ListFind(##class(Learning.Knowledge.SupportRAG).PolicyFiles(), source)
        Continue:$Data(seen(source))
        Do documents.%Push(..ReadDocument(source, "semantic", hit.%Get("id")))
        Set seen(source) = 1
        Quit:documents.%Size()=2
    }
    Return documents
}

}
