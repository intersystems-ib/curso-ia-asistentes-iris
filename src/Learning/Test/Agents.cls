Include %occStatus

/// Declarative initialization checks. Requires an API key but never calls the LLM.
Class Learning.Test.Agents Extends %RegisteredObject
{

ClassMethod Run() As %Status
{
    Try {
        For name = "Basic", "Support", "Analytics", "SupportWithSkill" {
            Set agent = $ClassMethod("Learning.Agent."_name, "%New")
            Set sc = agent.%Init()
            $$$ThrowOnError(sc)
            If $Length(agent.SystemPrompt, "## Reglas comunes") '= 2 {
                Return $$$ERROR($$$GeneralError, "Common instructions must appear exactly once: "_name)
            }
            If '$IsObject(agent.Provider) || (agent.Model = "") {
                Return $$$ERROR($$$GeneralError, "Provider or model missing: "_name)
            }
        }
        Set agent = ##class(Learning.Agent.Support).%New()
        $$$ThrowOnError(agent.%Init())
        $$$ThrowOnError(..CheckTools(agent, "GetOrder,GetProduct,GetShipment,ListOutOfStock"))
        If '(agent.SystemPrompt [ "actualDeliveryDate") {
            Return $$$ERROR($$$GeneralError, "Support evidence instructions missing")
        }
        Set agent = ##class(Learning.Agent.Analytics).%New()
        $$$ThrowOnError(agent.%Init())
        $$$ThrowOnError(..CheckTools(agent, "RunQuery,DescribeTable,SampleRows"))
        If '(agent.SystemPrompt [ "Learning_Data.CustomerOrder") {
            Return $$$ERROR($$$GeneralError, "Analytics schema instructions missing")
        }
        Set agent = ##class(Learning.Agent.SupportWithSkill).%New()
        $$$ThrowOnError(agent.%Init())
        If '$IsObject(agent.AvailableSkills) {
            Return $$$ERROR($$$GeneralError, "Available skill missing")
        }
        If agent.AvailableSkills.%Size() '= 1 {
            Return $$$ERROR($$$GeneralError, "Expected exactly one support skill")
        }
        Set skill = agent.AvailableSkills.%Get(0)
        If (skill.%Get("id") '= "Learning.Skill.SupportWorkflow") || (skill.%Get("instructions") = "") {
            Return $$$ERROR($$$GeneralError, "Skill metadata or instructions missing")
        }
        Set session = agent.CreateSession({"max_iterations":10})
        If session.ActiveSkills.%Size() '= 0 {
            Return $$$ERROR($$$GeneralError, "Skill must stay inactive before conversation")
        }
        Write "Declarative agents passed: common rules, tools and inactive skill.", !
        Return $$$OK
    } Catch ex {
        Return ex.AsStatus()
    }
}

/// Compare the complete catalog so accidental extra tools fail the check.
ClassMethod CheckTools(agent As %AI.Agent, expected As %String) As %Status [ Private ]
{
    Set tools = agent.ToolManager.GetToolStatuses()
    If tools.%Size() '= $Length(expected, ",") {
        Return $$$ERROR($$$GeneralError, "Unexpected tool count")
    }
    Set names = $ListFromString(expected)
    Set iter = tools.%GetIterator()
    While iter.%GetNext(.index, .tool) {
        If '$ListFind(names, tool.%Get("name")) {
            Return $$$ERROR($$$GeneralError, "Unexpected tool: "_tool.%Get("name"))
        }
    }
    Return $$$OK
}

}
