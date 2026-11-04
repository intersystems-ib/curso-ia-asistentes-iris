Include %occStatus

/// Loads deterministic, idempotent records for the course support domain.
Class Learning.Data.DemoData Extends %RegisteredObject
{

/// Load every structured demo record. Re-running this method never duplicates data.
ClassMethod Load() As %Status
{
    Set sc = ..LoadCustomers()
    If $$$ISERR(sc) {
        Return sc
    }
    Set sc = ..LoadProducts()
    If $$$ISERR(sc) {
        Return sc
    }
    Set sc = ..LoadOrders()
    If $$$ISERR(sc) {
        Return sc
    }
    Return ..LoadShipments()
}

/// Create the six customers used by the exercises.
ClassMethod LoadCustomers() As %Status [ Private ]
{
    Set data(1) = $LISTBUILD("CUS-001", "Alice Martin", "alice@example.com", "Gold")
    Set data(2) = $LISTBUILD("CUS-002", "Bob Navarro", "bob@example.com", "Standard")
    Set data(3) = $LISTBUILD("CUS-003", "Carla Ruiz", "carla@example.com", "Gold")
    Set data(4) = $LISTBUILD("CUS-004", "Diego Soto", "diego@example.com", "Standard")
    Set data(5) = $LISTBUILD("CUS-005", "Elena Vega", "elena@example.com", "Standard")
    Set data(6) = $LISTBUILD("CUS-006", "Francisco Lara", "francisco@example.com", "Gold")
    Set sc = $$$OK
    Try {
        For i = 1:1:6 {
            Set customerId = $LISTGET(data(i), 1)
            Set customer = ##class(Learning.Data.Customer).CustomerIdIdxOpen(customerId)
            If '$IsObject(customer) {
                Set customer = ##class(Learning.Data.Customer).%New()
                Set customer.CustomerId = customerId
                Set customer.FullName = $LISTGET(data(i), 2)
                Set customer.Email = $LISTGET(data(i), 3)
                Set customer.CustomerTier = $LISTGET(data(i), 4)
                Set sc = customer.%Save()
                $$$ThrowOnError(sc)
            }
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

/// Create the catalog records used by support and analytics examples.
ClassMethod LoadProducts() As %Status [ Private ]
{
    Set data(1) = $LISTBUILD("SKU-AUD-001", "Auriculares inalámbricos Nova", "Audio", 79.90, 15, 24, "Auriculares con cancelación de ruido y batería de 30 horas.")
    Set data(2) = $LISTBUILD("SKU-AUD-002", "Altavoz portátil Wave", "Audio", 49.90, 0, 12, "Altavoz resistente al agua con doce horas de autonomía.")
    Set data(3) = $LISTBUILD("SKU-AUD-003", "Micrófono USB Studio", "Audio", 109.00, 7, 24, "Micrófono de escritorio para llamadas y grabación doméstica.")
    Set data(4) = $LISTBUILD("SKU-CMP-001", "Hub USB-C Connect", "Computing", 69.50, 8, 24, "Hub de siete puertos con HDMI, Ethernet y carga.")
    Set data(5) = $LISTBUILD("SKU-CMP-002", "Teclado mecánico Compact", "Computing", 129.00, 5, 24, "Teclado compacto con interruptores táctiles.")
    Set data(6) = $LISTBUILD("SKU-CMP-003", "Soporte de portátil Lift", "Computing", 55.00, 23, 12, "Soporte de aluminio ajustable para portátiles.")
    Set data(7) = $LISTBUILD("SKU-CMP-004", "Ratón ergonómico Arc", "Computing", 44.90, 3, 24, "Ratón vertical inalámbrico para jornadas largas.")
    Set data(8) = $LISTBUILD("SKU-HOM-001", "Lámpara de escritorio Focus", "HomeOffice", 39.90, 19, 12, "Lámpara LED regulable con puerto USB.")
    Set data(9) = $LISTBUILD("SKU-HOM-002", "Alfombrilla Desk Mat", "HomeOffice", 24.90, 34, 6, "Alfombrilla amplia para teclado y ratón.")
    Set data(10) = $LISTBUILD("SKU-HOM-003", "Webcam ClearView", "HomeOffice", 89.00, 6, 24, "Webcam 1080p con tapa de privacidad.")
    Set data(11) = $LISTBUILD("SKU-MOB-001", "Batería externa PowerGo", "Mobile", 35.00, 28, 12, "Batería externa de 10000 mAh con USB-C.")
    Set data(12) = $LISTBUILD("SKU-MOB-002", "Cargador GaN 65W", "Mobile", 45.00, 11, 24, "Cargador compacto para portátil, móvil y tableta.")
    Set data(13) = $LISTBUILD("SKU-MOB-003", "Funda protectora Flex", "Mobile", 19.90, 40, 6, "Funda de silicona flexible para teléfono.")
    Set data(14) = $LISTBUILD("SKU-REF-001", "Auriculares Nova reacondicionados", "Refurbished", 54.90, 4, 12, "Unidad revisada con embalaje alternativo.")
    Set data(15) = $LISTBUILD("SKU-REF-002", "Hub Connect reacondicionado", "Refurbished", 45.00, 2, 12, "Hub revisado y probado funcionalmente.")
    Set data(16) = $LISTBUILD("SKU-ACC-001", "Cable USB-C reforzado", "Accessories", 14.90, 60, 24, "Cable trenzado de dos metros.")
    Set data(17) = $LISTBUILD("SKU-ACC-002", "Organizador de cables", "Accessories", 12.50, 45, 6, "Juego de clips y cintas reutilizables.")
    Set data(18) = $LISTBUILD("SKU-ACC-003", "Adaptador HDMI", "Accessories", 22.00, 0, 12, "Adaptador USB-C a HDMI 4K.")
    Set sc = $$$OK
    Try {
        For i = 1:1:18 {
            Set sku = $LISTGET(data(i), 1)
            Set product = ##class(Learning.Data.Product).SkuIdxOpen(sku)
            If '$IsObject(product) {
                Set product = ##class(Learning.Data.Product).%New()
                Set product.Sku = sku
                Set product.ProductName = $LISTGET(data(i), 2)
                Set product.Category = $LISTGET(data(i), 3)
                Set product.UnitPrice = $LISTGET(data(i), 4)
                Set product.StockQuantity = $LISTGET(data(i), 5)
                Set product.WarrantyMonths = $LISTGET(data(i), 6)
                Set product.Description = $LISTGET(data(i), 7)
                Set sc = product.%Save()
                $$$ThrowOnError(sc)
            }
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

/// Create orders that cover every state used in the course.
ClassMethod LoadOrders() As %Status [ Private ]
{
    Set data(1) = $LISTBUILD("ORD-001", "CUS-001", "SKU-AUD-001", 1, "Processing", "2026-08-20", 79.90, "")
    Set data(2) = $LISTBUILD("ORD-002", "CUS-002", "SKU-CMP-001", 1, "Shipped", "2026-08-18", 69.50, "DHL-1002")
    Set data(3) = $LISTBUILD("ORD-003", "CUS-003", "SKU-CMP-003", 2, "Delivered", "2026-08-02", 110.00, "SEUR-1003")
    Set data(4) = $LISTBUILD("ORD-004", "CUS-004", "SKU-MOB-002", 1, "Cancelled", "2026-08-10", 45.00, "")
    Set data(5) = $LISTBUILD("ORD-005", "CUS-005", "SKU-REF-001", 1, "Returned", "2026-07-21", 54.90, "CTT-1005")
    Set data(6) = $LISTBUILD("ORD-006", "CUS-006", "SKU-HOM-003", 1, "Delivered", "2026-08-05", 89.00, "DHL-1006")
    Set data(7) = $LISTBUILD("ORD-007", "CUS-001", "SKU-ACC-001", 3, "Processing", "2026-08-21", 44.70, "")
    Set data(8) = $LISTBUILD("ORD-008", "CUS-002", "SKU-AUD-003", 1, "Shipped", "2026-08-16", 109.00, "SEUR-1008")
    Set data(9) = $LISTBUILD("ORD-009", "CUS-003", "SKU-HOM-001", 1, "Delivered", "2026-08-01", 39.90, "CTT-1009")
    Set data(10) = $LISTBUILD("ORD-010", "CUS-004", "SKU-CMP-002", 1, "Cancelled", "2026-08-12", 129.00, "")
    Set data(11) = $LISTBUILD("ORD-011", "CUS-005", "SKU-MOB-001", 2, "Shipped", "2026-08-19", 70.00, "DHL-1011")
    Set data(12) = $LISTBUILD("ORD-012", "CUS-006", "SKU-ACC-002", 2, "Delivered", "2026-07-29", 25.00, "SEUR-1012")
    Set data(13) = $LISTBUILD("ORD-013", "CUS-001", "SKU-HOM-002", 1, "Returned", "2026-07-15", 24.90, "CTT-1013")
    Set data(14) = $LISTBUILD("ORD-014", "CUS-002", "SKU-REF-002", 1, "Processing", "2026-08-22", 45.00, "")
    Set data(15) = $LISTBUILD("ORD-015", "CUS-003", "SKU-MOB-003", 2, "Delivered", "2026-08-03", 39.80, "DHL-1015")
    Set sc = $$$OK
    Try {
        For i = 1:1:15 {
            Set orderRef = $LISTGET(data(i), 1)
            Set order = ##class(Learning.Data.CustomerOrder).OrderRefIdxOpen(orderRef)
            If '$IsObject(order) {
                Set customer = ##class(Learning.Data.Customer).CustomerIdIdxOpen($LISTGET(data(i), 2))
                Set product = ##class(Learning.Data.Product).SkuIdxOpen($LISTGET(data(i), 3))
                If '$IsObject(customer) || '$IsObject(product) {
                    $$$ThrowStatus($$$ERROR($$$GeneralError, "A seed order references missing data"))
                }
                Set order = ##class(Learning.Data.CustomerOrder).%New()
                Set order.OrderRef = orderRef
                Set order.Customer = customer
                Set order.Product = product
                Set order.Quantity = $LISTGET(data(i), 4)
                Set order.OrderStatus = $LISTGET(data(i), 5)
                Set order.OrderDate = $ZDATEH($LISTGET(data(i), 6), 3)
                Set order.TotalAmount = $LISTGET(data(i), 7)
                Set order.TrackingNumber = $LISTGET(data(i), 8)
                Set sc = order.%Save()
                $$$ThrowOnError(sc)
            }
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

/// Create shipment records for orders that have left the warehouse.
ClassMethod LoadShipments() As %Status [ Private ]
{
    Set data(1) = $LISTBUILD("DHL-1002", "ORD-002", "DHL", "InTransit", "El envío ha salido del centro logístico de Madrid.", "2026-08-23")
    Set data(2) = $LISTBUILD("SEUR-1003", "ORD-003", "SEUR", "Delivered", "Entregado en la dirección indicada.", "2026-08-05")
    Set data(3) = $LISTBUILD("CTT-1005", "ORD-005", "CTT", "Returned", "El paquete de devolución ha sido recibido.", "2026-07-28")
    Set data(4) = $LISTBUILD("DHL-1006", "ORD-006", "DHL", "Delivered", "Entregado en recepción.", "2026-08-08")
    Set data(5) = $LISTBUILD("SEUR-1008", "ORD-008", "SEUR", "Delayed", "Retraso por incidencia meteorológica en ruta.", "2026-08-25")
    Set data(6) = $LISTBUILD("CTT-1009", "ORD-009", "CTT", "Delivered", "Entregado al destinatario.", "2026-08-04")
    Set data(7) = $LISTBUILD("DHL-1011", "ORD-011", "DHL", "InTransit", "Clasificado en la plataforma regional.", "2026-08-24")
    Set data(8) = $LISTBUILD("SEUR-1012", "ORD-012", "SEUR", "Delivered", "Entregado en buzón seguro.", "2026-08-01")
    Set data(9) = $LISTBUILD("CTT-1013", "ORD-013", "CTT", "Returned", "Devolución aceptada y en tránsito al almacén.", "2026-07-22")
    Set data(10) = $LISTBUILD("DHL-1015", "ORD-015", "DHL", "Delivered", "Entregado sin incidencias.", "2026-08-06")
    Set sc = $$$OK
    Try {
        For i = 1:1:10 {
            Set trackingNumber = $LISTGET(data(i), 1)
            Set shipment = ##class(Learning.Data.Shipment).TrackingIdxOpen(trackingNumber)
            If '$IsObject(shipment) {
                Set order = ##class(Learning.Data.CustomerOrder).OrderRefIdxOpen($LISTGET(data(i), 2))
                If '$IsObject(order) {
                    $$$ThrowStatus($$$ERROR($$$GeneralError, "A seed shipment references a missing order"))
                }
                Set shipment = ##class(Learning.Data.Shipment).%New()
                Set shipment.TrackingNumber = trackingNumber
                Set shipment.CustomerOrder = order
                Set shipment.Carrier = $LISTGET(data(i), 3)
                Set shipment.ShipmentStatus = $LISTGET(data(i), 4)
                Set shipment.LastEvent = $LISTGET(data(i), 5)
                Set shipment.ExpectedDeliveryDate = $ZDATEH($LISTGET(data(i), 6), 3)
                Set sc = shipment.%Save()
                $$$ThrowOnError(sc)
            }
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Return sc
}

}
