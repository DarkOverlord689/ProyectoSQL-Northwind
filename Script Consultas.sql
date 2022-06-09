---CONSULTAS EN EL PROYECTO


-- ### ¿ Como saber cuanto se vendió de cada producto y categoría según mes y año? -- #### 
--Consulta para saber cuanto se ha vendido por producto y categoria segun mes y año
--		trunque fechas usando DATEADD(DATEDIFFF), tabbla de numero y concatenacion de cadenas 
--		implemente el uso de formatos de codigo en convert() y la funcion QUOTENAME

DECLARE @FechaInicio datetime,
        @FechaFin    datetime;

SELECT @FechaInicio = MIN(OrderDate), 
       @FechaFin    = MAX(OrderDate)
FROM Orders;

DECLARE @Columnas nvarchar(max) = '',
        @SQL      nvarchar(max);

--código de las columnas
WITH 
E(n) AS( -- 10 filas
    SELECT n FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0))E(n)
),
E2(n) AS( -- 10x10 = 100 filas
    SELECT a.n FROM E a, E b
),	
E4(n) AS( -- 100x100 = 10,000 filas
    SELECT a.n FROM E2 a, E2 b
),
cteTally(n) AS(
    SELECT TOP(DATEDIFF( MM, @FechaInicio, @FechaFin) + 1 )		--limitamos el número de filas
        ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) - 1 AS n		--Generamos los números del 0 a N
    FROM E4
),
cteMeses(Mes) AS(
    SELECT DATEADD(MM, DATEDIFF( MM, 0, @FechaInicio) + n, 0) Mes	--sumamos N meses a la fecha inicial y los convertimos al primer día del mes.
    FROM cteTally
)
SELECT @Columnas =( SELECT CHAR(9) + N',SUM(CASE WHEN o.OrderDate >= ' + QUOTENAME( CONVERT( nchar(8), Mes, 112), '''') --Conversión del mes actual a formato YYYYMMDD y agregago de comillas
                            + N' AND o.OrderDate < ' + QUOTENAME( CONVERT( nchar(8), DATEADD( MM, 1, Mes), 112), '''') --Conversión del mes siguiente a formato YYYYMMDD y agrego comillas
                            + N' THEN ( od.UnitPrice * od.Quantity ) * ( 1 - od.Discount ) + o.Freight ELSE 0 END) AS ' 
                            + QUOTENAME( DATENAME(MM, Mes) + '-' + DATENAME(YY, Mes)) + NCHAR(10)	--nombre del mes y año y se coloca entre corchetes
                FROM cteMeses
                FOR XML PATH(''), TYPE).value('./text()[1]', 'nvarchar(max)');		--Esta parte concatena todo en un XML y luego lo convierte en nvarchar(max)

	--Se procede a juntar las 3 partes de la consulta        
SELECT @SQL =  N'
    SELECT ISNULL( p.ProductName, ''Total'') AS Producto
           ,ISNULL( c.CategoryName, ''Global'') AS Categoria
           ,SUM(( od.UnitPrice * od.Quantity ) * ( 1 - od.Discount ) + o.Freight) TT
           ' + @Columnas + N'
    FROM   Products         AS P
    JOIN   Categories       AS C  ON P.CategoryID = C.CategoryID
    JOIN   [Order Details]  AS OD ON P.ProductID  = OD.ProductID
    JOIN   Orders           AS O  ON OD.OrderID   = O.OrderID
    WHERE o.OrderDate >= @FechaInicio
    AND   o.OrderDate <  @FechaFin
    GROUP BY c.CategoryName, p.ProductName WITH ROLLUP
    ORDER BY c.CategoryName, p.ProductName;';

EXECUTE sp_executesql @SQL, --Envio de la consulta
                    N'@FechaInicio datetime, @FechaFin datetime',	--Declaración de los parámetros
                    @FechaInicio, @FechaFin;	--Envio de los parámetros	



-----------------------------------------------------------------------------------------------------

---		##¿Como saber los productos vendidos por cualquier año?
---		Para este ejemplo he tomado como referencia el año 1997 
---		hago uso de pivot
SELECT 
Producto, [1] Ene, [2] Feb, [3] Mar, [4] Abr, [5] May, [6] Jun,
[7] Jul, [8] Ago, [9] Sep, [10] Oct, [11] Nov, [12] Dic
FROM 
(
   -- select inicial, a pivotar. Podría ser una tabla
   SELECT P.ProductName AS Producto, MONTH(O.OrderDate) AS Mes, D.Quantity AS Cantidad
   FROM [Order Details] D INNER JOIN Orders O ON D.OrderID = O.OrderID
          INNER JOIN Products P ON D.ProductID = P.ProductID
      WHERE O.OrderDate BETWEEN '19970101' AND '19971231'
     ) V PIVOT ( SUM(Cantidad) FOR Mes IN ([1], [2], [3], [4], [5],
                 [6], [7], [8], [9], [10], [11], [12]) ) AS PT


---------------------------------------------------------------------------------------------------

--- En terminos de seguridad ¿Como Saber la cantidad de pedidos llevadas por cada transportista?
SELECT 
Employees.FirstName + ' ' + Employees.LastName AS Empleado, Shippers.CompanyName AS Transportista, 
COUNT(Orders.OrderID)AS 'Numero de pedidos'
FROM 
Orders 
INNER JOIN Shippers ON Orders.ShipVia = Shippers.ShipperID
INNER JOIN Employees ON Orders.EmployeeID=Employees.EmployeeID
GROUP BY 
Employees.FirstName + ' ' + Employees.LastName, Shippers.CompanyName


----------------------------------------------------------------------------------------------------
-- En terminos de almacenado, ¿Como resumir la cantidad de artículos pedidos?

--	resumí la cantidad de pedidos por ProductID y OrderID
--		uso de SUM para un calculo acumulativo de la cantidad
SELECT 
ProductID AS ID_Producto, OrderID AS ID_ORDEN, SUM(quantity) AS Cantidad_TOTAL 
FROM 
[Order Details]
WHERE
ProductID = 50
GROUP BY
ProductID, OrderID
WITH ROLLUP	---rollup usado para generar reportes que contienen totales o subtotales
ORDER BY 
ProductID, OrderID


-------------------------------------------------------------------------------------------------
---		##Implementar un procedimiento para determinar la cantidad de registros de cliente por pedidos
---		creamos un procedure
CREATE PROCEDURE [dbo].[ObtenerPedidosPorClientes]
AS
BEGIN
	SET NOCOUNT ON	---esta sentencia indica al motor de base de datos que no cuente las filas afectadas.
	SELECT CustomerID, COUNT(CustomerID) COUNT_ORDERS FROM Orders
	GROUP BY CustomerID
END

EXECUTE [dbo].ObtenerPedidosPorClientes;

