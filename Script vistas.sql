---CREACION DE VISTAS 


---- vista nro 1: 
---		VISTA DE PROOVEDORES Y PRODUCTOS
CREATE VIEW VISTA_PROVEEDORES_PRODUCTOS
AS
SELECT S.SUPPLIERID,S.COMPANYNAME,S.CONTACTNAME
,P.PRODUCTID,P.PRODUCTNAME, P.UNITPRICE
FROM SUPPLIERS AS S INNER JOIN PRODUCTS AS P
ON
S.SUPPLIERID=P.SUPPLIERID;

select * from VISTA_PROVEEDORES_PRODUCTOS;


--- VISTA NRO 2:
---	VISTA DE UNA FACTURA en base al id de orden de compra
CREATE VIEW FACTURA AS
  SELECT         b.OrderID, -- dato extraidos de orden
               b.CustomerID,	--dato extraido de orden 
              c.CompanyName,	--dato extraido de customer
              c.Address,	--dato extraido de customer
              c.City,	--dato extraido de customer
              c.PostalCode,		--dato extraido de customer
              c.Country as 'Customer country',		--dato extraido de customer
              concat(d.FirstName, ' ', d.LastName) as Salesperson, ---concatenacion del nombre y apellido de empleado en una sola columna
              a.CompanyName as ShippingVia,		---dato de shippers
              e.ProductID,	--dato de detalles de orden
              f.ProductName,	--dato de producto
              e.Quantity,	--dato de detalles de orden(cantidad de producto xd
              e.UnitPrice * e.Quantity * (1 - e.Discount) as ExtendedPrice	--formular para saber el precio extendido y se agrega a una columna, datos extraidos de detalles de orden(order details)
  from Shippers a 
  inner join Orders b on a.ShipperID = b.ShipVia 
  inner join Customers c on c.CustomerID = b.CustomerID
  inner join Employees d on d.EmployeeID = b.EmployeeID
  inner join [Order Details] e on b.OrderID = e.OrderID
  inner join Products f on f.ProductID = e.ProductID
  WHERE b.OrderID = 10248		--- pasamos el id de order del cual se generará la factura

  select * from FACTURA;
