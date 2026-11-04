/// A synthetic customer used by the Learning support domain.
Class Learning.Data.Customer Extends %Persistent
{

Property CustomerId As %String(MAXLEN = 20) [ Required ];

Property FullName As %String(MAXLEN = 100) [ Required ];

Property Email As %String(MAXLEN = 150) [ Required ];

Property CustomerTier As %String(MAXLEN = 20);

Index CustomerIdIdx On CustomerId [ Unique ];

Index EmailIdx On Email [ Unique ];

Storage Default
{
<Data name="CustomerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CustomerId</Value>
</Value>
<Value name="3">
<Value>FullName</Value>
</Value>
<Value name="4">
<Value>Email</Value>
</Value>
<Value name="5">
<Value>CustomerTier</Value>
</Value>
</Data>
<DataLocation>^Learning.Data.CustomerD</DataLocation>
<DefaultData>CustomerDefaultData</DefaultData>
<IdLocation>^Learning.Data.CustomerD</IdLocation>
<IndexLocation>^Learning.Data.CustomerI</IndexLocation>
<StreamLocation>^Learning.Data.CustomerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
