[README.md](https://github.com/user-attachments/files/34954823/README.md)
# Análisis Comercial y Operativo – SalesAnalyticsDB

Español | [English](README.en.md)

Proyecto de **Data Analytics & Business Intelligence** que integra y transforma datos transaccionales de ventas mediante SQL Server y Power BI. El dashboard permite evaluar la evolución de la facturación, el comportamiento y recencia de los clientes (RFM) y la eficiencia logística de los despachos.

![Dashboard Comercial]

## Problema de negocio

La información de ventas, clientes, inventarios y envíos de una empresa del sector Alimentos y Bebidas se encuentra distribuida en múltiples tablas relacionales. No era posible tener una visión integrada que respondiera rápidamente a preguntas sobre la evolución de las ventas, qué clientes están en riesgo de fuga o qué tan eficientes están siendo los tiempos de entrega.

**Pregunta central:** ¿Cómo transformar datos transaccionales dispersos en métricas centralizadas que faciliten el seguimiento de las ventas, la retención de clientes y la mejora de los tiempos logísticos?

## Resultados clave

| Indicador | Valor |
|---|---|
| Ventas totales | **S/ 1,265,793.04** |
| Pedidos totales analizados | 830 (en un periodo de casi 3 años) |
| Ticket promedio | **S/ 1,525.05** |
| Eficiencia de despacho (Bueno/Óptimo) | **73.9%** (≤ 9 días) |
| Estado de clientes | 45 Activos / 22 En riesgo / 22 Inactivos |

## Principales hallazgos

- **El año 2024 concentra el mayor volumen operativo y de facturación**, representando el 48.75 % de las ventas totales (S/ 617,085.20) y 408 pedidos.
- **La categoría *Beverages* lidera las ventas** con S/ 267,868.18 acumulados, mientras que *Côte de Blaye* es el producto individual con mayor facturación.
- **Hay una alta concentración de pedidos de tamaño mediano**, los cuales representan casi la mitad de los despachos (49.28 %).
- **El 49.4 % de los clientes con compras se encuentra "En riesgo" o "Inactivo"** (superando los 23 días de recencia desde su última compra).
- **El tiempo promedio general de despacho es de 8 días**, pero existen 79 pedidos en estado "Crítico" (más de 18 días) y 21 pedidos sin fecha de envío registrada.

## Recomendaciones

1. **Implementar campañas de fidelización y reactivación** centradas en los 44 clientes que se encuentran inactivos o en riesgo, priorizando a aquellos con mayor ticket promedio de compra.
2. **Evaluar estrategias de venta cruzada (cross-selling)** orientadas a los pedidos de tamaño mediano y chico, con el objetivo de elevar el ticket promedio general.
3. **Auditar la cadena logística de los 79 pedidos críticos**, analizando los cuellos de botella por empleado, país de destino o transportista para reducir el umbral máximo de entrega.
4. **Crear un indicador operativo de pendientes** para monitorear en tiempo real los pedidos que ingresan al sistema y se quedan sin registrar fecha de despacho (`ShippedDate`).

## Dashboard

| Overview Comercial | Análisis de Clientes / Operaciones |
|---|---|
|**[Vista_General](img/sales_page-0001.jpg)** |**[Vista_Detalle](img/sales_page-0001.jpg)**|

## Solución técnica

- **Exploración y modelado SQL:** Análisis de 14 tablas relacionales, identificando llaves primarias/foráneas y evaluando la calidad de datos (valores nulos, fechas anómalas).
- **Desarrollo de 25 consultas T-SQL:** Uso intensivo de `JOIN`, funciones de agregación (`SUM`, `AVG`, `COUNT`), funciones de fecha (`YEAR`, `MONTH`, `DATEDIFF`), cláusulas `CASE` para segmentación condicional (estado de cliente/despacho) y subconsultas para calcular tickets promedio y variables operativas.
- **Capa analítica consolidada:** Creación de la tabla transaccional enriquecida `dbo.Analisis_Ventas`, unificando dimensiones y hechos a nivel pedido para conectar directamente con Power BI.
- **Modelo de datos en Power BI:** Integración de la capa analítica con una tabla `Calendario` para habilitar inteligencia de tiempo e interacciones multiplataforma en el dashboard.

![Modelo de datos]

```sql
-- Ejemplo: Creación de variable derivadas (Estado de Despacho)
SELECT 
    OrderID,
    DATEDIFF(day, OrderDate, ShippedDate) AS DiasDespacho,
    CASE 
        WHEN DATEDIFF(day, OrderDate, ShippedDate) BETWEEN 1 AND 4 THEN 'Óptimo'
        WHEN DATEDIFF(day, OrderDate, ShippedDate) BETWEEN 5 AND 9 THEN 'Bueno'
        WHEN DATEDIFF(day, OrderDate, ShippedDate) BETWEEN 10 AND 18 THEN 'Regular'
        WHEN DATEDIFF(day, OrderDate, ShippedDate) > 18 THEN 'Crítico'
        ELSE 'Por definir'
    END AS EstadoDespacho
FROM Orders;
```

## Herramientas

SQL Server (T-SQL) · Power BI · Modelado Dimensional · Power Query · DAX · Visualización de datos

## Estructura del repositorio

```
├── README.md                 Este documento
├── README.en.md              Versión en inglés
├── docs/Informe_Ventas.pdf   Informe completo del análisis y hallazgos
├── sql/consultas_ventas.sql  Scripts con las 25 consultas T-SQL desarrolladas
├── img/                      Capturas del dashboard y del modelo relacional
└── (archivo .pbix y .bak)
```

**[Ver informe completo (PDF)](docs/Proyecto2.pdf)**

## Notas

Datos basados en la estructura relacional *SalesAnalyticsDB* (escenario simulado de operaciones internacionales). Fuera del alcance inicial de este dashboard quedan los cálculos de rentabilidad y margen, a la espera de la incorporación de costos logísticos y de producción.

## Autor

**Sergio Aguilar Dinis** – Data Analyst | Business Intelligence
[LinkedIn](https://www.linkedin.com/in/sergio-aguilar-dinis-4766b858) · [Portafolio](https://fancy-coyote-67e.notion.site/PORTFOLIO-ES-b44f7f51a593839abe7b0196b748def2)
