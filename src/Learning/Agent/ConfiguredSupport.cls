/// Optional support variant backed by Config Store and Wallet.
Class Learning.Agent.ConfiguredSupport Extends Learning.Agent.Support
{

/// Clear inherited overrides so the stored configuration supplies all three values.
Parameter PROVIDER = "";
Parameter APIKEY = "";
Parameter MODEL = "";
Parameter PROVIDERCONFIG = "@{config:AI.LLM.learning-support}";

}
