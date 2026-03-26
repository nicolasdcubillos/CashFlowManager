USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataIngresos.sql
  Descripcion  : Ingresos proyectados del flujo de caja semana a semana.
                 Clasifica los ingresos por tipo de cliente: nacionales,
                 Carvajal, exterior, reverse factoring, prestamos y otros.
  Autor        : CC Sistemas
  Fecha        : 2026-03-02
================================================================================

  FUNCION  dbo.CashflowDataIngresos (@SemanaInicial, @SemanaFinal, @Moneda)
  -------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  ingreso y por cada semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas con la fecha de inicio.
    - TRMSemana             : TRM vigente por semana consultada en MTCAMBIO.
    - Datos                 : cruza operaciones comerciales (TRADE) con el
                              maestro de clientes/proveedores (MTPROCLI),
                              convirtiendo los valores a COP o USD segun
                              @Moneda y la TRM de cada semana.
    - Agrupado              : agrupa por tipo de cliente (TIPOCLI) y
                              exterior para obtener totales por categoria.
  Retorna nueve conceptos de ingreso mediante UNION ALL.

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataIngresos'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataIngresos
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3),
    @FechaBase     DATE = NULL   -- NULL usa GETDATE() (llamada directa / retrocompatible)
)
RETURNS TABLE
AS
RETURN
(
    WITH Numeros AS
    (
        SELECT @SemanaInicial AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM Numeros
        WHERE Semana + 1 <= @SemanaFinal
    ),

    FechaSemana AS
    (
        SELECT 
            Semana,
            DATEADD(WEEK, Semana, ISNULL(@FechaBase, CAST(GETDATE() AS DATE))) AS FechaInicio
        FROM Numeros
    ),

    TRMSemana AS
    (
        SELECT 
            f.Semana,
            f.FechaInicio,
            (
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= f.FechaInicio
                ORDER BY c.FECHA DESC
            ) AS TRM
        FROM FechaSemana f
    ),

    Datos AS
    (
        SELECT 
            t.Semana,
            p.CashflowCategoryId,
            SUM(
                CASE 
                    WHEN @Moneda = 'COP' THEN
                        CASE 
                            WHEN tr.TIPOMONEDA = 'USD'
                                THEN ISNULL(tr.VALORPLAN,0) * t.TRM
                            ELSE ISNULL(tr.VALORPLAN,0)
                        END

                    WHEN @Moneda = 'USD' THEN
                        CASE 
                            WHEN tr.TIPOMONEDA = 'COP'
                                THEN ISNULL(tr.VALORPLAN,0) / NULLIF(t.TRM,0)
                            ELSE ISNULL(tr.VALORPLAN,0)
                        END
                END
            ) AS Valor
        FROM TRMSemana t
        LEFT JOIN TRADE tr
            ON tr.FECHA <= t.FechaInicio
        LEFT JOIN MTPROCLI p
            ON p.NIT = tr.NIT
        WHERE p.CashflowCategoryId IS NOT NULL
        GROUP BY 
            t.Semana,
            p.CashflowCategoryId
    )

    SELECT
        cat.ParentName     AS Concepto,
        cat.ItemOrder,
        n.Semana,
        ISNULL(d.Valor, 0) AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Numeros n
    LEFT JOIN Datos d ON d.CashflowCategoryId = cat.Id AND d.Semana = n.Semana
    WHERE cat.Category = 'INGRESOS'
)
GO