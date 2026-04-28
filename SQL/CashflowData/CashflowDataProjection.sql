USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataProjection.sql
  Descripcion  : Proyeccion COMBINADA del flujo de caja por semana.
                 Suma los resultados de dos fuentes independientes:
                   1) CashflowDataProjectionManual  → entrada manual via UI
                      (tabla CashflowProjection).
                   2) CashflowDataProjectionPedidos  → pedidos pendientes
                      de despacho (tabla PedidosPendientes, Puntoventa=0).
                 Cada fuente tiene su propia TVF que puede ejecutarse por
                 separado via CashflowPivot para troubleshooting.
  Autor        : CC Sistemas
  Fecha        : 2026-04-12
================================================================================

  SINONIMO  dbo.PedidosPendientes_Src
  ------------------------------------
  Abstrae la base de datos donde reside PedidosPendientes.
  Para apuntar a otra DB, ejecutar:
      DROP   SYNONYM dbo.PedidosPendientes_Src;
      CREATE SYNONYM dbo.PedidosPendientes_Src
             FOR [NuevaBaseDeDatos].[dbo].[PedidosPendientes];

  FUNCION  dbo.CashflowDataProjection (@FechaInicial, @FechaFinal, @Moneda)
  ---------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que combina ambas proyecciones.
  Invoca las dos TVFs hijas y suma los valores por (Category, Concepto,
  ItemOrder, Semana).

  Columnas de salida:
    Category   VARCHAR(20)    - INGRESOS / EGRESOS / FINANCIAMIENTO
    Concepto   VARCHAR(150)   - ParentName de CashflowCategory
    ItemOrder  INT            - orden de filas dentro de la seccion
    Semana     INT            - semana secuencial (1, 2, 3 ...)
    Valor      DECIMAL(18,2)  - suma de manual + pedidos (0 si ninguna tiene datos)

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataProjection'
         y @Category = 'INGRESOS' | 'EGRESOS' | 'FINANCIAMIENTO'.

  Para diagnostico individual:
    EXEC dbo.CashflowPivot 'CashflowDataProjectionManual',  ... , 'INGRESOS';
    EXEC dbo.CashflowPivot 'CashflowDataProjectionPedidos', ... , 'INGRESOS';
================================================================================
*/

-- ============================================================
-- Sinonimo: un solo lugar para cambiar la DB fuente
-- ============================================================
IF OBJECT_ID('dbo.PedidosPendientes_Src', 'SN') IS NOT NULL
    DROP SYNONYM dbo.PedidosPendientes_Src;
GO

CREATE SYNONYM dbo.PedidosPendientes_Src
    FOR [INTECPL].[dbo].[PedidosPendientes];
GO

-- ============================================================
-- Funcion TVF combinada: Manual + Pedidos
-- ============================================================
CREATE OR ALTER FUNCTION dbo.CashflowDataProjection
(
    @FechaInicial DATE,
    @FechaFinal   DATE,
    @Moneda       VARCHAR(3)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        Category,
        Concepto,
        ItemOrder,
        Semana,
        SUM(Valor) AS Valor
    FROM
    (
        SELECT Category, Concepto, ItemOrder, Semana, Valor
        FROM   dbo.CashflowDataProjectionManual(@FechaInicial, @FechaFinal, @Moneda)

        UNION ALL

        SELECT Category, Concepto, ItemOrder, Semana, Valor
        FROM   dbo.CashflowDataProjectionPedidos(@FechaInicial, @FechaFinal, @Moneda)
    ) AS combined
    GROUP BY Category, Concepto, ItemOrder, Semana
);
GO
