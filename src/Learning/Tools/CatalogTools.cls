/// Read-only catalog queries exposed to AI Hub.
Class Learning.Tools.CatalogTools Extends %AI.Tool
{

/// Return one catalogue product by SKU as traceable read-only evidence.
Method GetProduct(sku As %String) As %DynamicObject
{
    Set result = {}
    Set product = ##class(Learning.Data.Product).SkuIdxOpen(sku)
    If '$IsObject(product) {
        Do result.%Set("found", 0)
        Do result.%Set("sku", sku)
        Return result
    }
    Do result.%Set("found", 1)
    Do result.%Set("sku", product.Sku)
    Do result.%Set("name", product.ProductName)
    Do result.%Set("category", product.Category)
    Do result.%Set("unitPrice", product.UnitPrice)
    Do result.%Set("stockQuantity", product.StockQuantity)
    Do result.%Set("warrantyMonths", product.WarrantyMonths)
    Do result.%Set("description", product.Description)
    Do result.%Set("source", "Learning_Data.Product")
    Do result.%Set("sourceRef", "Learning_Data.Product:"_product.Sku)
    Do result.%Set("sourceUrl", "", "null")
    Return result
}

/// List the products whose recorded stock is zero without changing catalogue data.
Method ListOutOfStock() As %DynamicArray
{
    Set products = []
    Set product = ""
    For  {
        Set product = $Order(^Learning.Data.ProductD(product))
        Quit:product=""
        Set item = ##class(Learning.Data.Product).%OpenId(product)
        If '$IsObject(item) Continue
        If item.StockQuantity = 0 {
            Set result = {}
            Do result.%Set("sku", item.Sku)
            Do result.%Set("name", item.ProductName)
            Do result.%Set("category", item.Category)
            Do result.%Set("source", "Learning_Data.Product")
            Do result.%Set("sourceRef", "Learning_Data.Product:"_item.Sku)
            Do result.%Set("sourceUrl", "", "null")
            Do products.%Push(result)
        }
    }
    Return products
}

}
