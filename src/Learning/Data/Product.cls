/// A catalog product used by the Learning support domain.
Class Learning.Data.Product Extends %Persistent
{

Property Sku As %String(MAXLEN = 30) [ Required ];

Property ProductName As %String(MAXLEN = 150) [ Required ];

Property Category As %String(MAXLEN = 50) [ Required ];

Property UnitPrice As %Numeric(SCALE = 2) [ Required ];

Property StockQuantity As %Integer [ Required ];

Property WarrantyMonths As %Integer [ InitialExpression = 12 ];

Property Description As %String(MAXLEN = 1000);

Index SkuIdx On Sku [ Unique ];

Storage Default
{
<Data name="ProductDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Sku</Value>
</Value>
<Value name="3">
<Value>ProductName</Value>
</Value>
<Value name="4">
<Value>Category</Value>
</Value>
<Value name="5">
<Value>UnitPrice</Value>
</Value>
<Value name="6">
<Value>StockQuantity</Value>
</Value>
<Value name="7">
<Value>WarrantyMonths</Value>
</Value>
<Value name="8">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^Learning.Data.ProductD</DataLocation>
<DefaultData>ProductDefaultData</DefaultData>
<IdLocation>^Learning.Data.ProductD</IdLocation>
<IndexLocation>^Learning.Data.ProductI</IndexLocation>
<StreamLocation>^Learning.Data.ProductS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
