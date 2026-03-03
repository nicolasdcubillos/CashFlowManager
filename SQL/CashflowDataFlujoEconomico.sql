/*
================================================================================
  Archivo      : CashflowDataFlujoEconomico.sql
  Descripcion  : Flujo de caja economico (financiamiento) semana a semana.
                 Incluye prestamos, leasing, tarjetas, factoring e intereses.
                 Por ahora todos los conceptos retornan $0 por semana;
                 la implementacion a detalle se realiza en una fase posterior.
  Autor        : CC Sistemas
  Fecha        : 2026-03-02
================================================================================

  FUNCION  dbo.CashflowDataFlujoEconomico (@SemanaInicial, @SemanaFinal, @Moneda)
  ---------------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  financiamiento y por cada semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas con la fecha de inicio de
                              cada una (base dinamica: GETDATE()).
  Retorna siete conceptos, todos con Valor = 0 hasta implementacion.
  El total "Total Financiamiento" se calcula en VFP (no en SQL).

  PROCEDIMIENTO  dbo.CashflowDataFlujoEconomicoPivot (@SemanaInicial, @SemanaFinal, @Moneda)
  -------------------------------------------------------------------------------------------
  Stored Procedure que transpone la salida de la funcion en una matriz
  donde cada columna es un numero de semana. Construye dinamicamente la
  lista de columnas con STRING_AGG/QUOTENAME y ejecuta un PIVOT con
  SUM(Valor) FOR Semana mediante sp_executesql.

  Ejemplo de uso:
    EXEC dbo.CashflowDataFlujoEconomicoPivot
         @SemanaInicial = -5,
         @SemanaFinal   = 0,
         @Moneda        = 'COP';
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataFlujoEconomico
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
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
            DATEADD(WEEK, Semana, CAST(GETDATE() AS DATE)) AS FechaInicio
        FROM Numeros
    )

    -- TODO: implementar logica real por concepto usando @Moneda y TRM

    SELECT 'Prestamos Corto Plazo'                    AS Concepto, Semana, CAST(0 AS DECIMAL(18,2)) AS Valor FROM FechaSemana
    UNION ALL
    SELECT 'Retencion Cuota Trimestral - Sindicado LT', Semana, CAST(0 AS DECIMAL(18,2))            FROM FechaSemana
    UNION ALL
    SELECT 'Tarjetas de Credito',                       Semana, CAST(0 AS DECIMAL(18,2))            FROM FechaSemana
    UNION ALL
    SELECT 'Leasing Financiero',                        Semana, CAST(0 AS DECIMAL(18,2))            FROM FechaSemana
    UNION ALL
    SELECT 'Confirming Factoring with vendors',         Semana, CAST(0 AS DECIMAL(18,2))            FROM FechaSemana
    UNION ALL
    SELECT 'Intereses Creditos',                        Semana, CAST(0 AS DECIMAL(18,2))            FROM FechaSemana
    UNION ALL
    SELECT 'Retoma Creditos',                           Semana, CAST(0 AS DECIMAL(18,2))            FROM FechaSemana
);
GO

CREATE OR ALTER PROCEDURE dbo.CashflowDataFlujoEconomicoPivot
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Columnas NVARCHAR(MAX);
    DECLARE @SQL      NVARCHAR(MAX);

    ;WITH Numeros AS
    (
        SELECT @SemanaInicial AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM Numeros
        WHERE Semana + 1 <= @SemanaFinal
    )
    SELECT @Columnas = STRING_AGG(QUOTENAME(Semana), ',')
    FROM Numeros
    OPTION (MAXRECURSION 1000);

    SET @SQL = '
        SELECT *
        FROM
        (
            SELECT Concepto, Semana, Valor
            FROM dbo.CashflowDataFlujoEconomico('
            + CAST(@SemanaInicial AS VARCHAR(10)) + ','
            + CAST(@SemanaFinal   AS VARCHAR(10)) + ','''
            + @Moneda + ''')
        ) AS src
        PIVOT
        (
            SUM(Valor)
            FOR Semana IN (' + @Columnas + ')
        ) AS p
        ORDER BY
            CASE Concepto
                WHEN ''Prestamos Corto Plazo''                    THEN 1
                WHEN ''Retencion Cuota Trimestral - Sindicado LT'' THEN 2
                WHEN ''Tarjetas de Credito''                       THEN 3
                WHEN ''Leasing Financiero''                        THEN 4
                WHEN ''Confirming Factoring with vendors''         THEN 5
                WHEN ''Intereses Creditos''                        THEN 6
                WHEN ''Retoma Creditos''                           THEN 7
                ELSE 99
            END;
    ';

    EXEC sp_executesql @SQL;
END;
GO
