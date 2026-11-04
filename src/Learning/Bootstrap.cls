Include %occStatus

/// Entry point for loading the deterministic course data.
Class Learning.Bootstrap Extends %RegisteredObject
{

/// Load the data required by the direct execution labs.
ClassMethod LoadDemoData() As %Status
{
    Return ##class(Learning.Data.DemoData).Load()
}

}
