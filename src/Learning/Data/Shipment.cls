/// A simulated carrier shipment associated with a customer order.
Class Learning.Data.Shipment Extends %Persistent
{

Property TrackingNumber As %String(MAXLEN = 40) [ Required ];

Property CustomerOrder As Learning.Data.CustomerOrder [ Required ];

Property Carrier As %String(MAXLEN = 50) [ Required ];

Property ShipmentStatus As %String(MAXLEN = 30) [ Required ];

Property LastEvent As %String(MAXLEN = 500) [ Required ];

Property ExpectedDeliveryDate As %Date;

Index TrackingIdx On TrackingNumber [ Unique ];

Storage Default
{
<Data name="ShipmentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TrackingNumber</Value>
</Value>
<Value name="3">
<Value>CustomerOrder</Value>
</Value>
<Value name="4">
<Value>Carrier</Value>
</Value>
<Value name="5">
<Value>ShipmentStatus</Value>
</Value>
<Value name="6">
<Value>LastEvent</Value>
</Value>
<Value name="7">
<Value>ExpectedDeliveryDate</Value>
</Value>
</Data>
<DataLocation>^Learning.Data.ShipmentD</DataLocation>
<DefaultData>ShipmentDefaultData</DefaultData>
<IdLocation>^Learning.Data.ShipmentD</IdLocation>
<IndexLocation>^Learning.Data.ShipmentI</IndexLocation>
<StreamLocation>^Learning.Data.ShipmentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
