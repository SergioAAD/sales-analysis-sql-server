-- Comprobar que tablas existen en la BD

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Conocer las columnas reales de cada tabla

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'Orders',
    'Order Details',
    'Customers',
    'Employees',
    'Products',
    'Categories',
    'Suppliers',
    'Shippers',
    'Territories',
    'Region',
    'EmployeeTerritories'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Cantidad de registros:

SELECT 
    'Orders' AS Tabla,
    COUNT(*) AS Registros
FROM Orders

UNION ALL

SELECT 
    'Order Details',
    COUNT(*)
FROM [Order Details]

UNION ALL

SELECT 
    'Customers',
    COUNT(*)
FROM Customers

UNION ALL

SELECT 
    'Products',
    COUNT(*)
FROM Products

UNION ALL

SELECT 
    'Categories',
    COUNT(*)
FROM Categories

UNION ALL

SELECT 
    'Employees',
    COUNT(*)
FROM Employees;

/*
Tabla	Registros
Orders	830
Order Details	2155
Customers	91
Products	77
Categories	8
Employees	9
*/

-- fechas de primer y ultimo pedido -- 
SELECT
    MIN(OrderDate) AS PrimeraFechaPedido,
    MAX(OrderDate) AS UltimaFechaPedido,
    COUNT(DISTINCT YEAR(OrderDate)) AS Anios
FROM Orders;

/*
PrimeraFechaPedido	UltimaFechaPedido	Anios
2023-07-04 00:00:00.000	2025-05-06 00:00:00.000	3
*/

-- Total de pedidos ocn fecha y sin fecha --
SELECT
    COUNT(*) AS TotalPedidos,
    SUM(CASE WHEN ShippedDate IS NULL THEN 1 ELSE 0 END) AS SinFechaEnvio,
    SUM(CASE WHEN ShippedDate IS NOT NULL THEN 1 ELSE 0 END) AS ConFechaEnvio
FROM Orders;

/*
TotalPedidos	SinFechaEnvio	ConFechaEnvio
830	            21	            809
*/


-- saber descuento minimo, maximo y promedio --
SELECT
    MIN(Discount) AS DescuentoMinimo,
    MAX(Discount) AS DescuentoMaximo,
    AVG(Discount) AS DescuentoPromedio
FROM [Order Details];

/*
DescuentoMinimo	DescuentoMaximo	DescuentoPromedio
0	            0.25	           0.0561670542022607
*/


--- total de registros de OrderDetails ---
SELECT
    COUNT(*) AS TotalRegistros,

    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS OrderID_Nulos,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS ProductID_Nulos,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS UnitPrice_Nulos,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Quantity_Nulos,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Discount_Nulos

FROM [Order Details];

/*
TotalRegistros	OrderID_Nulos	ProductID_Nulos	UnitPrice_Nulos	Quantity_Nulos	Discount_Nulos
         2155	0	                0	            0	            0	            0
*/


-- Total de registros nulos de Orders -- 
SELECT
    COUNT(*) AS TotalRegistros,

    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS OrderID_Nulos,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS CustomerID_Nulos,
    SUM(CASE WHEN EmployeeID IS NULL THEN 1 ELSE 0 END) AS EmployeeID_Nulos,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS OrderDate_Nulos,
    SUM(CASE WHEN ShippedDate IS NULL THEN 1 ELSE 0 END) AS ShippedDate_Nulos

FROM Orders;

/*
TotalRegistros	OrderID_Nulos	CustomerID_Nulos	EmployeeID_Nulos	OrderDate_Nulos	ShippedDate_Nulos
830	            0	            0	                0	                0	                21
*/

-- Tabla de Order Details con importe bruto y neto (despues de descuento) --

SELECT
    OrderID,
    ProductID,
    UnitPrice,
    Quantity,
    Discount,
    UnitPrice * Quantity AS ImporteBruto,
    UnitPrice * Quantity * (1 - Discount) AS ImporteNeto
FROM [Order Details]
ORDER BY OrderID, ProductID;


-- Ya que un pedido tiene varios productos se agrupan por orderID para tener el total por la order --
SELECT
    OrderID,
    CAST(SUM(UnitPrice * Quantity) AS DECIMAL(7,2)) AS ImporteBrutoPedido,
    CAST(SUM(UnitPrice * Quantity * (1 - Discount)) AS DECIMAL(7,2)) AS ImporteNetoPedido
FROM [Order Details]
GROUP BY OrderID
ORDER BY OrderID;

-- POObtener por pedidos, un analisis de minimo, maximo y promedio ---

SELECT
    MIN(Pedidos.ImporteNetoPedido) AS PedidoMinimo,
    MAX(Pedidos.ImporteNetoPedido) AS PedidoMaximo,
    CAST(AVG(Pedidos.ImporteNetoPedido) AS DECIMAL(10,2)) AS TicketPromedio,
    COUNT(*) AS CantidadPedidos
FROM (
    SELECT
        OrderID,
        SUM(UnitPrice * Quantity * (1 - Discount)) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY OrderID
) AS Pedidos;

/*
PedidoMinimo	PedidoMaximo	TicketPromedio	CantidadPedidos
12.5	        16387.5	            1525.05	        830
*/

-- Distribución de la data para sabver el tamaño del pedido --

SELECT
    CAST(PERCENTILE_CONT(0.25) 
        WITHIN GROUP (ORDER BY Pedidos.ImporteNetoPedido) 
        OVER () AS DECIMAL(10,2)) AS Q1,

    CAST(PERCENTILE_CONT(0.50) 
        WITHIN GROUP (ORDER BY Pedidos.ImporteNetoPedido) 
        OVER () AS DECIMAL(10,2)) AS Mediana,

    CAST(PERCENTILE_CONT(0.75) 
        WITHIN GROUP (ORDER BY Pedidos.ImporteNetoPedido) 
        OVER () AS DECIMAL(10,2)) AS Q3

FROM (
    SELECT
        OrderID,
        SUM(UnitPrice * Quantity * (1 - Discount)) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY OrderID
) AS Pedidos;

/*
Q1	Mediana	Q3
456.69	943.25	1882.20
*/

SELECT
    Pedidos.OrderID,
    Pedidos.ImporteNetoPedido,
    CASE
        WHEN Pedidos.ImporteNetoPedido <= 500 THEN 'Chico'
        WHEN Pedidos.ImporteNetoPedido <= 2000 THEN 'Mediano'
        ELSE 'Grande'
    END AS TamanoPedido
FROM (
    SELECT
        OrderID,
        CAST(
            SUM(UnitPrice * Quantity * (1 - Discount))
            AS DECIMAL(7,2)
        ) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY OrderID
) AS Pedidos
ORDER BY Pedidos.OrderID;


SELECT
    TamanoPedido,
    COUNT(*) AS CantidadPedidos,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PorcentajePedidos
FROM (
    SELECT
        Pedidos.OrderID,
        Pedidos.ImporteNetoPedido,
        CASE
            WHEN Pedidos.ImporteNetoPedido <= 500 THEN 'Chico'
            WHEN Pedidos.ImporteNetoPedido <= 2000 THEN 'Mediano'
            ELSE 'Grande'
        END AS TamanoPedido
    FROM (
        SELECT
            OrderID,
            CAST(
                SUM(UnitPrice * Quantity * (1 - Discount))
                AS DECIMAL(7,2)
            ) AS ImporteNetoPedido
        FROM [Order Details]
        GROUP BY OrderID
    ) AS Pedidos
) AS Clasificacion
GROUP BY TamanoPedido
ORDER BY
    CASE TamanoPedido
        WHEN 'Chico' THEN 1
        WHEN 'Mediano' THEN 2
        WHEN 'Grande' THEN 3
    END;


-- calcular dias de despacho--
SELECT
    MIN(DiasDespacho) AS Minimo,
    MAX(DiasDespacho) AS Maximo,
    CAST(AVG(DiasDespacho) AS DECIMAL(10,2)) AS Promedio,
    COUNT(*) AS PedidosDespachados
FROM (
    SELECT
        DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) AS DiasDespacho
    FROM Orders
    WHERE Orders.ShippedDate IS NOT NULL
) AS Pedidos;

/*
Minimo	Maximo	Promedio	PedidosDespachados
1	37	8.00	809
*/

-- calculamos los cuartiles ---
SELECT
    CAST(PERCENTILE_CONT(0.10)
        WITHIN GROUP (ORDER BY Pedidos.DiasDespacho)
        OVER () AS DECIMAL(10,2)) AS P10,

    CAST(PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY Pedidos.DiasDespacho)
        OVER () AS DECIMAL(10,2)) AS Q1,

    CAST(PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY Pedidos.DiasDespacho)
        OVER () AS DECIMAL(10,2)) AS Mediana,

    CAST(PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY Pedidos.DiasDespacho)
        OVER () AS DECIMAL(10,2)) AS Q3,

    CAST(PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY Pedidos.DiasDespacho)
        OVER () AS DECIMAL(10,2)) AS P90

FROM (
    SELECT
        DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) AS DiasDespacho
    FROM Orders
    WHERE Orders.ShippedDate IS NOT NULL
) AS Pedidos;

/*
P10	Q1	Mediana	Q3	P90
3.00	4.00	7.00	9.00	18.00
*/

-- Definios cuantos dias de despacho mediante - shippeddate - Orderdate
SELECT
    Orders.OrderID,
    Orders.OrderDate,
    Orders.ShippedDate,
    DATEDIFF(
        DAY,
        Orders.OrderDate,
        Orders.ShippedDate
    ) AS DiasDespacho
FROM Orders
WHERE Orders.ShippedDate IS NOT NULL;

-- calcular los dias de despacho mínimo y maximo.
SELECT
    MIN(DiasDespacho) AS Minimo,
    MAX(DiasDespacho) AS Maximo
FROM (
    SELECT
        DATEDIFF(
            DAY,
            Orders.OrderDate,
            Orders.ShippedDate
        ) AS DiasDespacho
    FROM Orders
    WHERE Orders.ShippedDate IS NOT NULL
) AS Pedidos;


-- Cantidad de pedidos por estado de despacho --- 
SELECT
    EstadoDespacho,
    COUNT(*) AS CantidadPedidos
FROM (
    SELECT
        Orders.OrderID,

        CASE
            WHEN Orders.ShippedDate IS NULL THEN 'Por definir'
            WHEN DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) <= 4 THEN 'Optimo'
            WHEN DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) <= 9 THEN 'Bueno'
            WHEN DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) <= 18 THEN 'Regular'
            ELSE 'Critico'
        END AS EstadoDespacho

    FROM Orders
) AS Pedidos

GROUP BY EstadoDespacho

ORDER BY
    CASE EstadoDespacho
        WHEN 'Optimo' THEN 1
        WHEN 'Bueno' THEN 2
        WHEN 'Regular' THEN 3
        WHEN 'Critico' THEN 4
        WHEN 'Por definir' THEN 5
    END;
/*
EstadoDespacho	CantidadPedidos
Optimo	                209
Bueno	                405
Regular	                116
Critico	                79
Por definir	            21
*/

SELECT
    Orders.CustomerID,
    MAX(Orders.OrderDate) AS UltimaCompra
FROM Orders
GROUP BY Orders.CustomerID
ORDER BY Orders.CustomerID;

-- se obtuvo como resultado última compra: '2025-05-06' --

SELECT
    Pedidos.CustomerID,
    Pedidos.UltimaCompra,
    DATEDIFF(
        DAY,
        Pedidos.UltimaCompra,
        '2025-05-06'
    ) AS DiasRecencia
FROM (
    SELECT
        Orders.CustomerID,
        MAX(Orders.OrderDate) AS UltimaCompra
    FROM Orders
    GROUP BY Orders.CustomerID
) AS Pedidos
ORDER BY Pedidos.CustomerID;

-- definimos mínio, maximo promedio y cantidad de clientes --
SELECT
    MIN(DiasRecencia) AS Minimo,
    MAX(DiasRecencia) AS Maximo,
    CAST(AVG(DiasRecencia) AS DECIMAL(10,2)) AS Promedio,
    COUNT(*) AS CantidadClientes
FROM (
    SELECT
        Orders.CustomerID,
        DATEDIFF(
            DAY,
            MAX(Orders.OrderDate),
            '2025-05-06'
        ) AS DiasRecencia
    FROM Orders
    GROUP BY Orders.CustomerID
) AS Clientes;


SELECT
    MIN(Clientes.DiasRecencia) AS Minimo,
    MAX(Clientes.DiasRecencia) AS Maximo,
    CAST(AVG(Clientes.DiasRecencia) AS DECIMAL(10,2)) AS Promedio,
    COUNT(*) AS CantidadClientes
FROM (
    SELECT
        Customers.CustomerID,
        MAX(Orders.OrderDate) AS UltimaCompra,
        DATEDIFF(
            DAY,
            MAX(Orders.OrderDate),
            '2025-05-06'
        ) AS DiasRecencia
    FROM Customers
    LEFT JOIN Orders
        ON Customers.CustomerID = Orders.CustomerID
    GROUP BY Customers.CustomerID
) AS Clientes;


/*

Minimo	Maximo	Promedio	CantidadClientes
0	    658	    51.00	        89

Hacemos Join porque en Customers son 91 pero solo 89 tienen compras, 2 clientes no tiene compras
Minimo	Maximo	Promedio	CantidadClientes
0	    658	     51.00	        91

*/

-- Calculamos lospercentiles para caategorizas estado de cliente --

SELECT
    CAST(PERCENTILE_CONT(0.10)
        WITHIN GROUP (ORDER BY Clientes.DiasRecencia)
        OVER () AS DECIMAL(10,2)) AS P10,

    CAST(PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY Clientes.DiasRecencia)
        OVER () AS DECIMAL(10,2)) AS Q1,

    CAST(PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY Clientes.DiasRecencia)
        OVER () AS DECIMAL(10,2)) AS Mediana,

    CAST(PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY Clientes.DiasRecencia)
        OVER () AS DECIMAL(10,2)) AS Q3,

    CAST(PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY Clientes.DiasRecencia)
        OVER () AS DECIMAL(10,2)) AS P90

FROM (
    SELECT
        Orders.CustomerID,
        DATEDIFF(
            DAY,
            MAX(Orders.OrderDate),
            '2025-05-06'
        ) AS DiasRecencia
    FROM Orders
    GROUP BY Orders.CustomerID
) AS Clientes;

/*P10	Q1	Mediana	Q3	P90
2.00	8.00	23.00	58.00	119.40*/


-- obtenemos la cantidad de clientes por su estado --
SELECT
    EstadoCliente,
    COUNT(*) AS CantidadClientes
FROM (
    SELECT
        Clientes.CustomerID,
        Clientes.DiasRecencia,

        CASE
            WHEN Clientes.DiasRecencia <= 23 THEN 'Activo'
            WHEN Clientes.DiasRecencia <= 58 THEN 'En riesgo'
            ELSE 'Inactivo'
        END AS EstadoCliente

    FROM (
        SELECT
            Pedidos.CustomerID,
            Pedidos.UltimaCompra,
            DATEDIFF(
                DAY,
                Pedidos.UltimaCompra,
                '2025-05-06'
            ) AS DiasRecencia
        FROM (
            SELECT
                Orders.CustomerID,
                MAX(Orders.OrderDate) AS UltimaCompra
            FROM Orders
            GROUP BY Orders.CustomerID
        ) AS Pedidos
    ) AS Clientes
) AS Clasificacion

GROUP BY EstadoCliente

ORDER BY
    CASE EstadoCliente
        WHEN 'Activo' THEN 1
        WHEN 'En riesgo' THEN 2
        WHEN 'Inactivo' THEN 3
    END;

/*
EstadoCliente	CantidadClientes
Activo	            45
En riesgo	        22
Inactivo	        22
*/

SELECT
    Clientes.CustomerID,
    Clientes.UltimaCompra,
    Clientes.DiasRecencia,
    CASE
        WHEN Clientes.UltimaCompra IS NULL THEN 'Sin compras'
        WHEN Clientes.DiasRecencia <= 23 THEN 'Activo'
        WHEN Clientes.DiasRecencia <= 58 THEN 'En riesgo'
        ELSE 'Inactivo'
    END AS EstadoCliente
FROM (
    SELECT
        Customers.CustomerID,
        MAX(Orders.OrderDate) AS UltimaCompra,
        DATEDIFF(
            DAY,
            MAX(Orders.OrderDate),
            '2025-05-06'
        ) AS DiasRecencia
    FROM Customers
    LEFT JOIN Orders
        ON Customers.CustomerID = Orders.CustomerID
    GROUP BY Customers.CustomerID
) AS Clientes
ORDER BY Clientes.CustomerID;


-- 12. Análisis de ventas
--12.1 Ventas totales
SELECT
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM [Order Details];
--12.2 Ventas por año
SELECT
    YEAR(Orders.OrderDate) AS Anio,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM Orders
INNER JOIN [Order Details]
    ON Orders.OrderID = [Order Details].OrderID
GROUP BY
    YEAR(Orders.OrderDate)
ORDER BY
    Anio;


--12.3 Ventas por mes
SELECT
    YEAR(Orders.OrderDate) AS Anio,
    MONTH(Orders.OrderDate) AS Mes,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM Orders
INNER JOIN [Order Details]
    ON Orders.OrderID = [Order Details].OrderID
GROUP BY
    YEAR(Orders.OrderDate),
    MONTH(Orders.OrderDate)
ORDER BY
    Anio,
    Mes;

--12.4 Ventas promedio / comportamiento
SELECT
    YEAR(Orders.OrderDate) AS Anio,
    CAST(
        AVG(Pedidos.ImporteNetoPedido)
        AS DECIMAL(10,2)
    ) AS VentaPromedioPorPedido
FROM Orders
INNER JOIN (
    SELECT
        [Order Details].OrderID,
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY
        [Order Details].OrderID
) AS Pedidos
    ON Orders.OrderID = Pedidos.OrderID
GROUP BY
    YEAR(Orders.OrderDate)
ORDER BY
    Anio;


-- 13.1 Número de pedidos
SELECT
    COUNT(*) AS NumeroPedidos
FROM Orders;
-- 13.2 Pedidos por año
SELECT
    YEAR(Orders.OrderDate) AS Anio,
    COUNT(*) AS NumeroPedidos
FROM Orders
GROUP BY
    YEAR(Orders.OrderDate)
ORDER BY
    Anio;
-- 13.3 Pedidos por mes
SELECT
    YEAR(Orders.OrderDate) AS Anio,
    MONTH(Orders.OrderDate) AS Mes,
    COUNT(*) AS NumeroPedidos
FROM Orders
GROUP BY
    YEAR(Orders.OrderDate),
    MONTH(Orders.OrderDate)
ORDER BY
    Anio,
    Mes;
-- 13.4 Ticket promedio por pedido
SELECT
    YEAR(Orders.OrderDate) AS Anio,
    MONTH(Orders.OrderDate) AS Mes,
    CAST(
        AVG(Pedidos.ImporteNetoPedido)
        AS DECIMAL(10,2)
    ) AS TicketPromedioPorPedido
FROM Orders
INNER JOIN (
    SELECT
        [Order Details].OrderID,
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY
        [Order Details].OrderID
) AS Pedidos
    ON Orders.OrderID = Pedidos.OrderID
GROUP BY
    YEAR(Orders.OrderDate),
    MONTH(Orders.OrderDate)
ORDER BY
    Anio,
    Mes;

-- 13.5 Pedidos por tamaño de pedido
SELECT
    CASE
        WHEN Pedidos.ImporteNetoPedido <= 500 THEN 'Chico'
        WHEN Pedidos.ImporteNetoPedido <= 2000 THEN 'Mediano'
        ELSE 'Grande'
    END AS TamanoPedido,
    COUNT(*) AS NumeroPedidos
FROM (
    SELECT
        [Order Details].OrderID,
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY
        [Order Details].OrderID
) AS Pedidos
GROUP BY
    CASE
        WHEN Pedidos.ImporteNetoPedido <= 500 THEN 'Chico'
        WHEN Pedidos.ImporteNetoPedido <= 2000 THEN 'Mediano'
        ELSE 'Grande'
    END
ORDER BY
    NumeroPedidos DESC;

-- 14.1 Ventas por categoría
SELECT
    Categories.CategoryName AS Categoria,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM [Order Details]
INNER JOIN Products
    ON [Order Details].ProductID = Products.ProductID
INNER JOIN Categories
    ON Products.CategoryID = Categories.CategoryID
GROUP BY
    Categories.CategoryName
ORDER BY
    VentasTotales DESC;

-- 14.2 Ventas por categoría y año

SELECT
    YEAR(Orders.OrderDate) AS Anio,
    Categories.CategoryName AS Categoria,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM Orders
INNER JOIN [Order Details]
    ON Orders.OrderID = [Order Details].OrderID
INNER JOIN Products
    ON [Order Details].ProductID = Products.ProductID
INNER JOIN Categories
    ON Products.CategoryID = Categories.CategoryID
GROUP BY
    YEAR(Orders.OrderDate),
    Categories.CategoryName
ORDER BY
    Anio,
    VentasTotales DESC;

-- 14.3 Top 10 productos por ventas

SELECT TOP 10
    Products.ProductName AS Producto,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM [Order Details]
INNER JOIN Products
    ON [Order Details].ProductID = Products.ProductID
GROUP BY
    Products.ProductName
ORDER BY
    VentasTotales DESC;

-- 14.4 Top 10 productos por unidades

SELECT TOP 10
    Products.ProductName AS Producto,
    SUM([Order Details].Quantity) AS UnidadesVendidas
FROM [Order Details]
INNER JOIN Products
    ON [Order Details].ProductID = Products.ProductID
GROUP BY
    Products.ProductName
ORDER BY
    UnidadesVendidas DESC;

-- 15.1 Clientes con compras
SELECT
    COUNT(DISTINCT Orders.CustomerID) AS ClientesConCompras
FROM Orders;
-- 15.2 Top clientes por facturación
SELECT TOP 10
    Customers.CustomerID,
    Customers.CompanyName AS Cliente,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM Customers
INNER JOIN Orders
    ON Customers.CustomerID = Orders.CustomerID
INNER JOIN [Order Details]
    ON Orders.OrderID = [Order Details].OrderID
GROUP BY
    Customers.CustomerID,
    Customers.CompanyName
ORDER BY
    VentasTotales DESC;
-- 15.3 Frecuencia de compra
SELECT TOP 10
    Customers.CustomerID,
    Customers.CompanyName AS Cliente,
    COUNT(Orders.OrderID) AS NumeroPedidos
FROM Customers
INNER JOIN Orders
    ON Customers.CustomerID = Orders.CustomerID
GROUP BY
    Customers.CustomerID,
    Customers.CompanyName
ORDER BY
    NumeroPedidos DESC;
-- 15.4 Ticket promedio por cliente
SELECT TOP 10
    Customers.CustomerID,
    Customers.CompanyName AS Cliente,
    CAST(
        AVG(Pedidos.ImporteNetoPedido) AS DECIMAL(10,2)
    ) AS TicketPromedio
FROM Customers
INNER JOIN Orders
    ON Customers.CustomerID = Orders.CustomerID
INNER JOIN (
    SELECT
        [Order Details].OrderID,
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY
        [Order Details].OrderID
) AS Pedidos
    ON Orders.OrderID = Pedidos.OrderID
GROUP BY
    Customers.CustomerID,
    Customers.CompanyName
ORDER BY
    TicketPromedio DESC;

-- 15.5 Clientes por EstadoCliente
SELECT
    Clientes.EstadoCliente,
    COUNT(*) AS NumeroClientes
FROM (
    SELECT
        Customers.CustomerID,
        CASE
            WHEN MAX(Orders.OrderDate) IS NULL THEN 'Sin compras'
            WHEN DATEDIFF(DAY, MAX(Orders.OrderDate), '2025-05-06') <= 23 THEN 'Activo'
            WHEN DATEDIFF(DAY, MAX(Orders.OrderDate), '2025-05-06') <= 58 THEN 'En riesgo'
            ELSE 'Inactivo'
        END AS EstadoCliente
    FROM Customers
    LEFT JOIN Orders
        ON Customers.CustomerID = Orders.CustomerID
    GROUP BY
        Customers.CustomerID
) AS Clientes
GROUP BY
    Clientes.EstadoCliente
ORDER BY
    NumeroClientes DESC;

-- 16.1 Ventas por empleado
SELECT
    Employees.EmployeeID,
    Employees.FirstName + ' ' + Employees.LastName AS Empleado,
    CAST(
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS DECIMAL(10,2)
    ) AS VentasTotales
FROM Employees
INNER JOIN Orders
    ON Employees.EmployeeID = Orders.EmployeeID
INNER JOIN [Order Details]
    ON Orders.OrderID = [Order Details].OrderID
GROUP BY
    Employees.EmployeeID,
    Employees.FirstName,
    Employees.LastName
ORDER BY
    VentasTotales DESC;

-- 16.2 edidos por empleado
SELECT
    Employees.EmployeeID,
    Employees.FirstName + ' ' + Employees.LastName AS Empleado,
    COUNT(Orders.OrderID) AS NumeroPedidos
FROM Employees
INNER JOIN Orders
    ON Employees.EmployeeID = Orders.EmployeeID
GROUP BY
    Employees.EmployeeID,
    Employees.FirstName,
    Employees.LastName
ORDER BY
    NumeroPedidos DESC;

-- 16.3 Ticket promedio por empleado
SELECT
    Employees.EmployeeID,
    Employees.FirstName + ' ' + Employees.LastName AS Empleado,
    CAST(
        AVG(Pedidos.ImporteNetoPedido) AS DECIMAL(10,2)
    ) AS TicketPromedio
FROM Employees
INNER JOIN Orders
    ON Employees.EmployeeID = Orders.EmployeeID
INNER JOIN (
    SELECT
        [Order Details].OrderID,
        SUM(
            [Order Details].UnitPrice
            * [Order Details].Quantity
            * (1 - [Order Details].Discount)
        ) AS ImporteNetoPedido
    FROM [Order Details]
    GROUP BY
        [Order Details].OrderID
) AS Pedidos
    ON Orders.OrderID = Pedidos.OrderID
GROUP BY
    Employees.EmployeeID,
    Employees.FirstName,
    Employees.LastName
ORDER BY
    TicketPromedio DESC;

-- 16.4 Volumen gestionado
SELECT
    Employees.EmployeeID,
    Employees.FirstName + ' ' + Employees.LastName AS Empleado,
    SUM([Order Details].Quantity) AS UnidadesGestionadas
FROM Employees
INNER JOIN Orders
    ON Employees.EmployeeID = Orders.EmployeeID
INNER JOIN [Order Details]
    ON Orders.OrderID = [Order Details].OrderID
GROUP BY
    Employees.EmployeeID,
    Employees.FirstName,
    Employees.LastName
ORDER BY
    UnidadesGestionadas DESC;

-- 17.1 Tiempo promedio de despacho
SELECT
    CAST(
        AVG(
            DATEDIFF(
                DAY,
                Orders.OrderDate,
                Orders.ShippedDate
            )
        ) AS DECIMAL(10,2)
    ) AS TiempoPromedioDespacho
FROM Orders
WHERE Orders.ShippedDate IS NOT NULL;

-- 17.2 Distribución de EstadoDespacho
SELECT
    EstadoDespacho,
    COUNT(*) AS NumeroPedidos
FROM (
    SELECT
        CASE
            WHEN Orders.ShippedDate IS NULL THEN 'Por definir'
            WHEN DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) <= 4 THEN 'Óptimo'
            WHEN DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) <= 9 THEN 'Bueno'
            WHEN DATEDIFF(DAY, Orders.OrderDate, Orders.ShippedDate) <= 18 THEN 'Regular'
            ELSE 'Crítico'
        END AS EstadoDespacho
    FROM Orders
) AS Despachos
GROUP BY
    EstadoDespacho
ORDER BY
    NumeroPedidos DESC;

-- 17.3 Tiempo de despacho por empleado
SELECT
    Employees.EmployeeID,
    Employees.FirstName + ' ' + Employees.LastName AS Empleado,
    CAST(
        AVG(
            DATEDIFF(
                DAY,
                Orders.OrderDate,
                Orders.ShippedDate
            )
        ) AS DECIMAL(10,2)
    ) AS TiempoPromedioDespacho
FROM Employees
INNER JOIN Orders
    ON Employees.EmployeeID = Orders.EmployeeID
WHERE Orders.ShippedDate IS NOT NULL
GROUP BY
    Employees.EmployeeID,
    Employees.FirstName,
    Employees.LastName
ORDER BY
    TiempoPromedioDespacho;

-- 17.4 Tiempo de despacho por país
SELECT
    Orders.ShipCountry AS Pais,
    CAST(
        AVG(
            DATEDIFF(
                DAY,
                Orders.OrderDate,
                Orders.ShippedDate
            )
        ) AS DECIMAL(10,2)
    ) AS TiempoPromedioDespacho
FROM Orders
WHERE Orders.ShippedDate IS NOT NULL
GROUP BY
    Orders.ShipCountry
ORDER BY
    TiempoPromedioDespacho;



/* =========================================================
   PASO 1: Eliminar la tabla si ya existe
   ========================================================= */

DROP TABLE IF EXISTS dbo.AnalisisVentas;



/* =========================================================
   PASO 2: Crear la tabla analítica a nivel de pedido
   Una fila = un OrderID
   ========================================================= */


SELECT
    O.OrderID,
    O.CustomerID,
    O.EmployeeID,
    O.ShipVia,

    YEAR(O.OrderDate) AS Anio,
    MONTH(O.OrderDate) AS Mes,

    O.OrderDate,
    O.RequiredDate,
    O.ShippedDate,

    /* Días de despacho */
    CASE
        WHEN O.ShippedDate IS NULL THEN NULL
        ELSE DATEDIFF(
            DAY,
            O.OrderDate,
            O.ShippedDate
        )
    END AS DiasDespacho,

    /* Estado del despacho */
    CASE
        WHEN O.ShippedDate IS NULL THEN 'Por definir'

        WHEN DATEDIFF(
            DAY,
            O.OrderDate,
            O.ShippedDate
        ) <= 4 THEN 'Óptimo'

        WHEN DATEDIFF(
            DAY,
            O.OrderDate,
            O.ShippedDate
        ) <= 9 THEN 'Bueno'

        WHEN DATEDIFF(
            DAY,
            O.OrderDate,
            O.ShippedDate
        ) <= 18 THEN 'Regular'

        ELSE 'Crítico'
    END AS EstadoDespacho,

    O.Freight,

    O.ShipName,
    O.ShipAddress,
    O.ShipCity,
    O.ShipRegion,
    O.ShipPostalCode,
    O.ShipCountry,

    /* Importe neto del pedido */
    CAST(
        SUM(
            OD.UnitPrice
            * OD.Quantity
            * (1 - OD.Discount)
        ) AS DECIMAL(7,2)
    ) AS ImporteNetoPedido,

    /* Tamaño del pedido */
    CASE
        WHEN SUM(
            OD.UnitPrice
            * OD.Quantity
            * (1 - OD.Discount)
        ) <= 500
            THEN 'Chico'

        WHEN SUM(
            OD.UnitPrice
            * OD.Quantity
            * (1 - OD.Discount)
        ) <= 2000
            THEN 'Mediano'

        ELSE 'Grande'
    END AS TamanoPedido,

    /* Última compra del cliente */
    EC.UltimaCompraCliente,

    /* Días de recencia */
    DATEDIFF(
        DAY,
        EC.UltimaCompraCliente,
        CAST('2025-05-06' AS DATE)
    ) AS DiasRecencia,

    /* Estado del cliente */
    CASE
        WHEN EC.UltimaCompraCliente IS NULL
            THEN 'Sin compras'

        WHEN DATEDIFF(
            DAY,
            EC.UltimaCompraCliente,
            CAST('2025-05-06' AS DATE)
        ) <= 23
            THEN 'Activo'

        WHEN DATEDIFF(
            DAY,
            EC.UltimaCompraCliente,
            CAST('2025-05-06' AS DATE)
        ) <= 58
            THEN 'En riesgo'

        ELSE 'Inactivo'
    END AS EstadoCliente

INTO dbo.AnalisisVentas

FROM dbo.Orders AS O

INNER JOIN dbo.[Order Details] AS OD
    ON O.OrderID = OD.OrderID

LEFT JOIN
(
    SELECT
        CustomerID,
        MAX(OrderDate) AS UltimaCompraCliente

    FROM dbo.Orders

    GROUP BY
        CustomerID
) AS EC
    ON O.CustomerID = EC.CustomerID

GROUP BY
    O.OrderID,
    O.CustomerID,
    O.EmployeeID,
    O.ShipVia,
    O.OrderDate,
    O.RequiredDate,
    O.ShippedDate,
    O.Freight,
    O.ShipName,
    O.ShipAddress,
    O.ShipCity,
    O.ShipRegion,
    O.ShipPostalCode,
    O.ShipCountry,
    EC.UltimaCompraCliente;
GO

-- Confirmamos si la tabla AnalisisVentas existe

USE SalesAnalyticsDB;
GO

SELECT TOP 10 *
FROM dbo.AnalisisVentas;

-- verificar registros duplicados
USE SalesAnalyticsDB;
GO

SELECT
    COUNT(*) AS TotalRegistros,
    COUNT(DISTINCT OrderID) AS PedidosUnicos
FROM dbo.AnalisisVentas;
-- comprobar ventas totales

SELECT
    SUM(ImporteNetoPedido) AS VentasTotales
FROM dbo.AnalisisVentas;

-- comprobas estados de despacho
SELECT
    EstadoDespacho,
    COUNT(*) AS CantidadPedidos
FROM dbo.AnalisisVentas
GROUP BY
    EstadoDespacho
ORDER BY
    CantidadPedidos DESC;

-- coprobar tamaño de pedidos

SELECT
    TamanoPedido,
    COUNT(*) AS CantidadPedidos
FROM dbo.AnalisisVentas
GROUP BY
    TamanoPedido
ORDER BY
    CantidadPedidos DESC;

-- Comprobar estado de los clientes
SELECT
    EstadoCliente,
    COUNT(DISTINCT CustomerID) AS CantidadClientes
FROM dbo.AnalisisVentas
GROUP BY
    EstadoCliente
ORDER BY
    CantidadClientes DESC;

