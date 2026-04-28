USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataHeader.sql
  Descripcion  : Saldo bancario inicial por semana para el encabezado
                 del flujo de caja. Cuentas COP y USD desde MVBANCOS/
                 MTBANCOS; cuentas de excedentes Credicorp separadas.
  Autor        : CC Sistemas
  Fecha        : 2026-03-26
================================================================================

  FUNCION  dbo.CashflowDataHeader (@FechaInicial, @FechaFinal, @Moneda)
  -----------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  saldo y por cada semana del rango indicado. Internamente construye:
    - Semanas       : genera semanas (lunes a domingo) desde
                      @FechaInicial hasta @FechaFinal.
    - TRM           : consulta la tasa de cambio vigente en MTCAMBIO
                      para la fecha de inicio de cada semana.
    - SaldoBancos   : cuentas regulares (excedentes excluidas). Calcula
                      SaldoCOP (OTRAMON='N') y SaldoUSD (OTRAMON='S')
                      como SALINICIAL + movimientos acumulados hasta
                      el lunes de cada semana.
    - Excedentes    : cuentas Credicorp identificadas por CODIGOCTA
                      especificos (ver TODO en el CTE). Saldo en COP.
                      Nota: MVBANCOS.VALOR se asume firmado.
  Retorna cuatro conceptos:
    1. Saldo inicial COP     (OTRAMON='N', cuentas en pesos)
    2. Saldo inicial USD     (OTRAMON='S', cuentas en otra moneda)
    3. PA Credicorp - Excedentes (CODIGOCTA fijo, cuentas prestamos)
    4. Disponible Bancos     (COP + USD*TRM + Excedentes)

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataHeader'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataHeader
(
    @FechaInicial DATE,
    @FechaFinal   DATE,
    @Moneda       VARCHAR(3)
)
RETURNS TABLE
AS
RETURN
(
    WITH Semanas AS
    (
        SELECT
            1 AS Semana,
            @FechaInicial AS LunesSemana
        UNION ALL
        SELECT
            Semana + 1,
            DATEADD(WEEK, 1, LunesSemana)
        FROM Semanas
        WHERE DATEADD(WEEK, 1, LunesSemana) <= @FechaFinal
    ),

    TRM AS
    (
        SELECT 
            s.Semana,
            s.LunesSemana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO
                WHERE FECHA <= s.LunesSemana
                ORDER BY FECHA DESC
            ),1) AS TRM
        FROM Semanas s
    ),

    SaldoBancos AS
    (
        -- Cuentas regulares (no excedentes): separa COP y USD.
        -- SaldoCOP: cuentas OTRAMON='N' (pesos).
        -- SaldoUSD: cuentas OTRAMON='S' (dolares), en unidades USD.
        -- El saldo = SALINICIAL configurado + movimientos hasta LunesSemana.
        SELECT
            s.Semana,
            t.TRM,
            SUM(CASE WHEN RTRIM(b.OTRAMON) = 'N'
                     THEN ISNULL(b.SALINICIAL, 0) + ISNULL(mv.TotalMov, 0)
                     ELSE 0 END) AS SaldoCOP,
            SUM(CASE WHEN RTRIM(b.OTRAMON) = 'S'
                     THEN ISNULL(b.SALINICIAL, 0) + ISNULL(mv.TotalMov, 0)
                     ELSE 0 END) AS SaldoUSD
        FROM Semanas s

        INNER JOIN TRM t ON t.Semana = s.Semana

        CROSS JOIN MTBANCOS b

        OUTER APPLY (
            SELECT SUM(mv.VALOR) AS TotalMov
            FROM MVBANCOS mv
            WHERE mv.CODIGOCTA = b.CODIGOCTA
              AND CAST(mv.FECHA AS DATE) <= s.LunesSemana
        ) mv

        -- TODO: excluir los CODIGOCTA de cuentas Credicorp excedentes
        WHERE b.CODIGOCTA NOT IN (
            'TODO_CREDICORP_1',
            'TODO_CREDICORP_2'
        )

        GROUP BY s.Semana, t.TRM
    ),

    Excedentes AS
    (
        -- Cuentas PA Credicorp - Excedentes identificadas por CODIGOCTA fijo.
        -- TODO: reemplazar los valores con los CODIGOCTA reales.
        SELECT
            s.Semana,
            t.TRM,
            SUM(
                ISNULL(b.SALINICIAL, 0)
                + ISNULL(mv.TotalMov, 0)
            ) AS SaldoExcedentes
        FROM Semanas s

        INNER JOIN TRM t ON t.Semana = s.Semana

        CROSS JOIN MTBANCOS b

        OUTER APPLY (
            SELECT SUM(mv.VALOR) AS TotalMov
            FROM MVBANCOS mv
            WHERE mv.CODIGOCTA = b.CODIGOCTA
              AND CAST(mv.FECHA AS DATE) <= s.LunesSemana
        ) mv

        WHERE b.CODIGOCTA IN (
            'TODO_CREDICORP_1',
            'TODO_CREDICORP_2'
        )

        GROUP BY s.Semana, t.TRM
    )

    -- 1. Saldo inicial COP (cuentas en pesos, OTRAMON='N')
    SELECT 'Saldo inicial COP' AS Concepto,
           1                   AS ItemOrder,
           sb.Semana,
           CASE WHEN @Moneda = 'USD'
                THEN sb.SaldoCOP / NULLIF(sb.TRM, 0)
                ELSE sb.SaldoCOP
           END AS Valor
    FROM SaldoBancos sb

    UNION ALL

    -- 2. Saldo inicial USD (cuentas en otra moneda, OTRAMON='S')
    SELECT 'Saldo inicial USD',
           2,
           sb.Semana,
           CASE WHEN @Moneda = 'USD'
                THEN sb.SaldoUSD
                ELSE sb.SaldoUSD * sb.TRM
           END
    FROM SaldoBancos sb

    UNION ALL

    -- 3. PA Credicorp - Excedentes
    SELECT 'PA Credicorp - Excedentes',
           3,
           e.Semana,
           CASE WHEN @Moneda = 'USD'
                THEN e.SaldoExcedentes / NULLIF(e.TRM, 0)
                ELSE e.SaldoExcedentes
           END
    FROM Excedentes e

    UNION ALL

    -- 4. Disponible Bancos = COP + USD*TRM + Excedentes (todo en moneda solicitada)
    SELECT 'Disponible Bancos',
           4,
           sb.Semana,
           CASE WHEN @Moneda = 'USD'
                THEN (sb.SaldoCOP + sb.SaldoUSD * sb.TRM + ISNULL(e.SaldoExcedentes, 0))
                     / NULLIF(sb.TRM, 0)
                ELSE sb.SaldoCOP + sb.SaldoUSD * sb.TRM + ISNULL(e.SaldoExcedentes, 0)
           END
    FROM SaldoBancos sb
    LEFT JOIN Excedentes e ON e.Semana = sb.Semana
)
GO