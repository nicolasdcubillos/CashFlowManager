USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowPivot.sql
  Descripcion  : SP generico que transpone cualquier funcion del flujo de
                 caja en una matriz donde cada columna es un numero de semana.
  Autor        : CC Sistemas
  Fecha        : 2026-03-26
================================================================================

  PROCEDIMIENTO  dbo.CashflowPivot
  ---------------------------------
  Parametros:
    @FunctionName  : nombre exacto de la funcion TVF a pivotar.
                     Solo se aceptan los valores de la lista blanca interna
                     para prevenir inyeccion SQL.
    @FechaInicial  : fecha de inicio del rango (DATE). Debe ser lunes.
    @FechaFinal    : fecha de fin del rango (DATE). Incluye hasta ese dia.
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
    EXEC dbo.CashflowPivot 'CashflowDataEgresos',   '2026-01-12', '2026-04-05', 'COP';
    EXEC dbo.CashflowPivot 'CashflowDataIngresos',   '2026-01-12', '2026-04-05', 'USD';
    EXEC dbo.CashflowPivot 'CashflowDataHeader',     '2026-01-12', '2026-04-05', 'COP';
    EXEC dbo.CashflowPivot 'CashflowDataProjection', '2026-03-30', '2026-04-05', 'USD', 'INGRESOS';
================================================================================
*/

CREATE OR ALTER PROCEDURE dbo.CashflowPivot
(
    @FunctionName  SYSNAME,
    @FechaInicial  DATE,
    @FechaFinal    DATE,
    @Moneda        VARCHAR(3),
    @Category      VARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lista blanca: unico punto de control contra SQL injection.
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

    IF @FechaInicial > @FechaFinal
        THROW 50003, '@FechaInicial no puede ser mayor que @FechaFinal.', 1;

    IF @Category IS NOT NULL AND @Category NOT IN ('INGRESOS', 'EGRESOS', 'FINANCIAMIENTO')
        THROW 50004, 'Categoria no valida. Use INGRESOS, EGRESOS o FINANCIAMIENTO.', 1;

    -- Calcular cuantas semanas hay en el rango y generar columnas [1],[2],...,[N]
    DECLARE @NumSemanas INT = DATEDIFF(WEEK, @FechaInicial, @FechaFinal) + 1;
    DECLARE @Columnas   NVARCHAR(MAX);
    DECLARE @SQL        NVARCHAR(MAX);
    DECLARE @Where      NVARCHAR(100) = '';

    ;WITH Numeros AS
    (
        SELECT 1 AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM   Numeros
        WHERE  Semana + 1 <= @NumSemanas
    )
    SELECT @Columnas = STRING_AGG(QUOTENAME('S' + CAST(Semana AS VARCHAR(10))), ',')
    FROM   Numeros
    OPTION (MAXRECURSION 1000);

    IF @Category IS NOT NULL
        SET @Where = ' WHERE Category = @pCategory';

    -- Fechas como strings seguros para SQL dinamico (DATE → no hay riesgo de inyeccion)
    DECLARE @FechaIniStr NVARCHAR(12) = '''' + CONVERT(VARCHAR(10), @FechaInicial, 120) + '''';
    DECLARE @FechaFinStr NVARCHAR(12) = '''' + CONVERT(VARCHAR(10), @FechaFinal,   120) + '''';

    SET @SQL = '
        SELECT *
        FROM
        (
            SELECT Concepto, ItemOrder,
                   ''S'' + CAST(Semana AS VARCHAR(10)) AS Semana,
                   Valor
            FROM dbo.' + QUOTENAME(@FunctionName) + '('
            + @FechaIniStr + ','
            + @FechaFinStr + ','''
            + @Moneda + ''')'
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
