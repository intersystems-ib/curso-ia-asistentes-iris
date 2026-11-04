Include %occStatus

/// Native AI Hub RAG over the versioned Markdown policy corpus.
Class Learning.Knowledge.SupportRAG Extends %RegisteredObject
{

/// Create the persistent FastEmbed vector store and index the six policy documents.
/// This method writes the vector store state in IRIS.
ClassMethod Build(Output knowledgeBase As %AI.RAG.KnowledgeBase) As %Status
{
    Set sc = $$$OK
    Try {
        Set embedding = ##class(%AI.RAG.Embedding.FastEmbed).Create()
        Set vectorStore = ##class(%AI.RAG.VectorStore.IRIS).%New()
        Set vectorStore.TableName = "LearningSupportPolicies"
        Set vectorStore.Dimensions = embedding.Dimensions
        Set vectorStore.ModelName = embedding.ModelName
        Set sc = vectorStore.Build()
        $$$ThrowOnError(sc)
        Set knowledgeBase = ##class(%AI.RAG.KnowledgeBase).%New(
            "search_support_policies",
            "Busca reglas de soporte con consultas en español. Cada resultado es un fragmento, no el documento completo. Afirma sólo condiciones presentes en text; si no aparecen, reformula o indica falta de evidencia. Cita metadata.source como nombre de archivo; sourceUrl null significa que no hay enlace web."
        )
        // Keep enough evidence to combine an order status with a policy rule.
        Set knowledgeBase.TopK = 8
        Set sc = knowledgeBase.Build(embedding, vectorStore)
        $$$ThrowOnError(sc)
        Set sc = ..AddVersionedDocuments(knowledgeBase)
        $$$ThrowOnError(sc)
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Read each versioned Markdown source mounted by Docker Compose and add it with a traceable source field.
ClassMethod AddVersionedDocuments(knowledgeBase As %AI.RAG.KnowledgeBase) As %Status [ Private ]
{
    Set files = ..PolicyFiles()
    Set sc = $$$OK
    Try {
        For index = 1:1:$ListLength(files) {
            Set fileName = $ListGet(files, index)
            Set sc = ..ReadText("/app/datos-demo/knowledge/" _ fileName, .text)
            $$$ThrowOnError(sc)
            Set metadata = {}
            Do metadata.%Set("source", fileName)
            Do metadata.%Set("sourceType", "local_markdown")
            Do metadata.%Set("sourcePath", "datos-demo/knowledge/"_fileName)
            Do metadata.%Set("sourceUrl", "", "null")
            Set sc = knowledgeBase.AddDocument(text, metadata)
            $$$ThrowOnError(sc)
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Fixed corpus shared by ingestion and the Lab 05 full-document reader.
ClassMethod PolicyFiles() As %List
{
    Return $ListBuild("cancellation-policy.md", "delivery-policy.md", "order-changes-policy.md", "returns-policy.md", "warranty-policy.md", "product-guide.md")
}

/// Read only a known policy file; never accept an arbitrary path from a search result.
ClassMethod ReadPolicy(fileName As %String, Output text As %String) As %Status
{
    Set text = ""
    If '$ListFind(..PolicyFiles(), fileName) {
        Return $$$ERROR($$$GeneralError, "Source is outside the approved policy corpus")
    }
    Return ..ReadText("/app/datos-demo/knowledge/"_fileName, .text)
}

/// Read one UTF-8 Markdown file from the mounted project into a string for indexing.
ClassMethod ReadText(path As %String, Output text As %String) As %Status [ Private ]
{
    Set sc = $$$OK
    Set text = ""
    Try {
        Set stream = ##class(%Stream.FileCharacter).%New()
        Set stream.TranslateTable = "UTF8"
        Set sc = stream.LinkToFile(path)
        $$$ThrowOnError(sc)
        For {
            Set chunk = stream.Read(32000)
            Quit:chunk=""
            Set text = text _ chunk
        }
        Do stream.%Close()
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

/// Lab 05: create a governed agent and expand native search hits to full policy documents.
ClassMethod AddToSupportAgent(Output agent As %AI.Agent) As %Status
{
    Set sc = ##class(Learning.Agent.Support).Create(.agent)
    Quit:$$$ISERR(sc) sc
    Set sc = ..Build(.knowledgeBase)
    Quit:$$$ISERR(sc) sc
    Set sc = ##class(Learning.Knowledge.PolicyDocuments).AddToAgent(agent, knowledgeBase)
    Quit:$$$ISERR(sc) sc
    Set agent.SystemPrompt = agent.SystemPrompt _ ..PolicyInstructions()
    Quit $$$OK
}

/// Lab 05 skill variant: attach the same full-document policy search.
ClassMethod AddToSupportAgentWithSkill(Output agent As %AI.Agent) As %Status
{
    Set sc = ##class(Learning.Agent.Support).CreateWithSkill(.agent)
    Quit:$$$ISERR(sc) sc
    Set sc = ..Build(.knowledgeBase)
    Quit:$$$ISERR(sc) sc
    Set sc = ##class(Learning.Knowledge.PolicyDocuments).AddToAgent(agent, knowledgeBase)
    Quit:$$$ISERR(sc) sc
    Set agent.SystemPrompt = agent.SystemPrompt _ ..PolicyInstructions()
    Quit $$$OK
}

/// Both Lab 05 variants must retrieve the policy, even when the catalog supplies a duration.
ClassMethod PolicyInstructions() As %String [ Private ]
{
    Return " Para cualquier pregunta sobre cobertura, exclusiones, condiciones, plazos, devoluciones, cancelaciones o garantia, llama a search_support_policies antes de responder y cita el archivo recuperado. Elige su topic explicito: garantia, devoluciones, cancelaciones, envios, cambios o productos. Usa general solo para consultas sin un tema definido. GetProduct informa de los meses de garantia, pero no acredita cobertura ni exclusiones: para explicar que cubre un producto debes recuperar la politica con topic garantia, tambien despues de activar una skill."
}

}
