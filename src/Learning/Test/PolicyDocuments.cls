Include %occStatus

/// Deterministic Lab 05 document expansion checks; no embedding writes or LLM calls.
Class Learning.Test.PolicyDocuments Extends %RegisteredObject
{

ClassMethod Run() As %Status
{
    Set hits = []
    For source = "../.env", "returns-policy.md", "returns-policy.md", "warranty-policy.md", "product-guide.md" {
        Set hit = {}
        Set metadata = {}
        Do metadata.%Set("source", source)
        Do hit.%Set("metadata", metadata)
        Do hit.%Set("id", "test-heading-only")
        Do hit.%Set("text", "## Plazo general")
        Do hits.%Push(hit)
    }
    Set documents = ##class(Learning.Knowledge.PolicyDocuments).ExpandHits(hits)
    If documents.%Size() '= 2 Return $$$ERROR($$$GeneralError, "Expansion must return two distinct approved documents")
    Set returns = documents.%Get(0)
    Set warranty = documents.%Get(1)
    If returns.metadata.source '= "returns-policy.md" Return $$$ERROR($$$GeneralError, "Native relevance order was not preserved")
    If warranty.metadata.source '= "warranty-policy.md" Return $$$ERROR($$$GeneralError, "Duplicate sources must not consume the document limit")
    If '$Find(returns.text, "30") Return $$$ERROR($$$GeneralError, "A heading hit must include the return-period paragraph")
    If '$Find(returns.text, "## Categor") Return $$$ERROR($$$GeneralError, "The full policy must include its exceptions")
    If '$Find(returns.text, "## Relaci") Return $$$ERROR($$$GeneralError, "The full policy must include its final section")
    If returns.metadata.%GetTypeOf("sourceUrl") '= "null" Return $$$ERROR($$$GeneralError, "Local policy expansion must not invent URLs")
    If returns.metadata.retrievalMode '= "full_document" Return $$$ERROR($$$GeneralError, "Document scope must be explicit")
    Set sc = ##class(Learning.Knowledge.SupportRAG).ReadPolicy("../.env", .text)
    If $$$ISOK(sc) Return $$$ERROR($$$GeneralError, "Arbitrary paths must be rejected")
    Set empty = ##class(Learning.Knowledge.PolicyDocuments).ExpandHits([])
    If empty.%Size() '= 0 Return $$$ERROR($$$GeneralError, "An empty search must not load unrelated documents")
    Set tool = ##class(Learning.Knowledge.PolicyDocuments).%New()
    Set empty = tool.Search("")
    If empty.%Size() '= 0 Return $$$ERROR($$$GeneralError, "An empty general query must not return policies")
    Set documents = tool.Search("auriculares con cancelacion de ruido", "garantia")
    If documents.%Size() '= 1 Return $$$ERROR($$$GeneralError, "An explicit topic must select exactly one policy")
    Set warranty = documents.%Get(0)
    If warranty.metadata.source '= "warranty-policy.md" Return $$$ERROR($$$GeneralError, "Product details must not redirect a warranty question to cancellation")
    If warranty.metadata.selection '= "topic" Return $$$ERROR($$$GeneralError, "Topic selection must be explicit in evidence")
    If '$Find(warranty.text, "12 meses") Return $$$ERROR($$$GeneralError, "Warranty evidence must include the refurbished period")
    If '$Find(warranty.text, "no cubre") || ('$Find(warranty.text, "desgaste normal")) Return $$$ERROR($$$GeneralError, "Warranty evidence must include the exclusions")
    Set documents = tool.Search("", "devoluciones")
    If '$Find(documents.%Get(0).text, "30") Return $$$ERROR($$$GeneralError, "Return evidence must contain the thirty-day rule")
    Set rejected = 0
    Try {
        Set documents = tool.Search("", "../.env")
    } Catch ex {
        Set rejected = 1
    }
    If 'rejected Return $$$ERROR($$$GeneralError, "Unknown topics must be rejected instead of becoming paths or broad searches")
    Write "Policy document checks passed: complete rules, topic selection, unique sources, two-document limit and approved paths.", !
    Return $$$OK
}

}
