/// A customer order. The class name avoids the reserved SQL word ORDER.
Class Learning.Data.CustomerOrder Extends %Persistent
{

Property OrderRef As %String(MAXLEN = 20) [ Required ];

Property Customer As Learning.Data.Customer [ Required ];

Property Product As Learning.Data.Product [ Required ];

Property Quantity As %Integer [ Required ];

Property OrderStatus As %String(MAXLEN = 20) [ Required ];

Property OrderDate As %Date [ Required ];

Property TotalAmount As %Numeric(SCALE = 2) [ Required ];

Property TrackingNumber As %String(MAXLEN = 40);

Index OrderRefIdx On OrderRef [ Unique ];

Storage Default
{
<Data name="CustomerOrderDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OrderRef</Value>
</Value>
<Value name="3">
<Value>Customer</Value>
</Value>
<Value name="4">
<Value>Product</Value>
</Value>
<Value name="5">
<Value>Quantity</Value>
</Value>
<Value name="6">
<Value>OrderStatus</Value>
</Value>
<Value name="7">
<Value>OrderDate</Value>
</Value>
<Value name="8">
<Value>TotalAmount</Value>
</Value>
<Value name="9">
<Value>TrackingNumber</Value>
</Value>
</Data>
<DataLocation>^Learning.Data.CustomerOrderD</DataLocation>
<DefaultData>CustomerOrderDefaultData</DefaultData>
<IdLocation>^Learning.Data.CustomerOrderD</IdLocation>
<IndexLocation>^Learning.Data.CustomerOrderI</IndexLocation>
<StreamLocation>^Learning.Data.CustomerOrderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
