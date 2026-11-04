/// Exposes the native SQL tool through a named, deliberately narrow ToolSet.
Class Learning.ToolSet.ReadOnlyAnalytics Extends %AI.ToolSet
    [ DependsOn = Learning.Policy.SQLAllowList ]
{

XData Definition [ MimeType = application/xml ]
{
<ToolSet Name="ReadOnlyAnalytics">
  <Description>Consulta analítica de solo lectura sobre las cuatro tablas demo.</Description>
  <Policies>
    <Authorization Class="Learning.Policy.SQLAllowList" />
  </Policies>
  <Include Class="%AI.Tools.SQL" Match="^(RunQuery|DescribeTable|SampleRows)$" />
</ToolSet>
}

}
