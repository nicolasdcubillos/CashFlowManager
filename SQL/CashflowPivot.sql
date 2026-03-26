USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowPivot.sql
  Descripcion  : SP generico que transpone cualquier funcion del flujo de
                 caja en una matriz donde cada columna es un numero de semana.
  Autor        : CC Sistemas
  Fecha        : 2026-03-25
================================================================================

  PROCEDIMIENTO  dbo.CashflowPivot
  ---------------------------------
  Parametros:
    @FunctionName  : nombre exacto de la funcion TVF a pivotar.
                     Solo se aceptan los valores de la lista blanca interna
                     para prevenir inyeccion SQL.
    @SemanaInicial : numero de semana relativo al inicio del rango.
    @SemanaFinal   : numero de semana relativo al fin del rango.
    @Moneda        : 'COP' o 'USD'.
    @Category      : (opcional) filtra por Category cuando la funcion
                     retorna varias categorias (ej. CashflowDataProjection).
                     Valores: 'INGRESOS', 'EGRESOS', 'FINANCIAMIENTO' o NULL.

  Funciones aceptadas:
    - CashflowDataHeader
    - CashflowDataIngresos
    - CashflowDataEgresos
    - CashflowDataFlujoEconomico
    - CashflowDataProjection

  Todas las funciones deben retornar las columnas:
    Concepto  NVARCHAR / VARCHAR
    ItemOrder INT
    Semana    INT
    Valor     DECIMAL(18,2)

  El resultado se ordena por ItemOrder (orden definido en CashflowCategory
  o, para Header, por orden hardcodeado en la propia funcion).

  Ejemplo de uso:
    EXEC dbo.CashflowPivot 'CashflowDataEgresos',   1,  6, 'COP';
    EXEC dbo.CashflowPivot 'CashflowDataIngresos', -3,  3, 'USD';
    EXEC dbo.CashflowPivot 'CashflowDataHeader',    0,  5, 'COP';
    EXEC dbo.CashflowPivot 'CashflowDataProjection', 1, 6, 'USD', 'INGRESOS';
================================================================================
*/

CREATE OR ALTER PROCEDURE dbo.CashflowPivot
(
    @FunctionName  SYSNAME,
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3),
    @Category      VARCHAR(20) = NULL,
    @FechaBase     DATE        = NULL   -- NULL → los TVFs usan GETDATE() internamente
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lista blanca: unico punto de control contra SQL injection.
    -- Agregar aqui cualquier nueva funcion antes de usarla.
    IF @FunctionName NOT IN (
        'CashflowDataHeader',
        'CashflowDataIngresos',
        'CashflowDataEgresos',
        'CashflowDataFlujoEconomico',
        'CashflowDataProjection'
    )
        THROW 50001, 'Funcion no reconocida. Verifique @FunctionName.', 1;

    IF @Moneda NOT IN ('COP', 'USD')
        THROW 50002, 'Moneda no valida. Use COP o USD.', 1;

    IF @SemanaInicial > @SemanaFinal
        THROW 50003, '@SemanaInicial no puede ser mayor que @SemanaFinal.', 1;

    IF @Category IS NOT NULL AND @Category NOT IN ('INGRESOS', 'EGRESOS', 'FINANCIAMIENTO')
        THROW 50004, 'Categoria no valida. Use INGRESOS, EGRESOS o FINANCIAMIENTO.', 1;

    DECLARE @Columnas     NVARCHAR(MAX);
    DECLARE @SQL          NVARCHAR(MAX);
    DECLARE @Where        NVARCHAR(100) = '';
    -- @FechaBase es DATE → CONVERT es seguro, sin riesgo de inyeccion
    DECLARE @FechaBaseStr NVARCHAR(14) =
        CASE WHEN @FechaBase IS NOT NULL
             THEN '''' + CONVERT(VARCHAR(10), @FechaBase, 120) + ''''
             ELSE 'NULL'
        END;

    ;WITH Numeros AS
    (
        SELECT @SemanaInicial AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM   Numeros
        WHERE  Semana + 1 <= @SemanaFinal
    )
    SELECT @Columnas = STRING_AGG(QUOTENAME(Semana), ',')
    FROM   Numeros
    OPTION (MAXRECURSION 1000);

    IF @Category IS NOT NULL
        SET @Where = ' WHERE Category = @pCategory';

    SET @SQL = '
        SELECT *
        FROM
        (
            SELECT Concepto, ItemOrder, Semana, Valor
            FROM dbo.' + QUOTENAME(@FunctionName) + '('
            + CAST(@SemanaInicial AS VARCHAR(10)) + ','
            + CAST(@SemanaFinal   AS VARCHAR(10)) + ','''
            + @Moneda + ''','
            + @FechaBaseStr + ')'
            + @Where + '
        ) AS src
        PIVOT
        (
            SUM(Valor)
            FOR Semana IN (' + @Columnas + ')
        ) AS p
        ORDER BY ItemOrder;
    ';

    EXEC sp_executesql @SQL, N'@pCategory VARCHAR(20)', @pCategory = @Category;
END;
GO
