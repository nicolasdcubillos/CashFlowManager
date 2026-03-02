*===========================================================
*  Autor: Nicolas David Cubilloss
*  Proyecto: Flujo de Caja INTECPLAST
*  Descripción:
*  Generador de Flujo de Caja semanal dinámico basado en SQL.
*  La lógica financiera vive en SQL.
*  VFP solo dibuja estructura y fórmulas en Excel.
*===========================================================

*-----------------------------------------------------------
* FUNCIÓN PRINCIPAL
* Genera archivo Excel completo (USD y COP)
*-----------------------------------------------------------
FUNCTION GenerarCashFlowExcel
    LPARAMETERS tdFechaFinal, ;
                tnSemanasAtras, ;
                tnSemanasAdelante

    LOCAL loExcel, loLibro, loHojaUSD
    LOCAL ldFechaBase
    LOCAL lcErrorDetalle

    IF PCOUNT() < 3
        MESSAGEBOX("Debe enviar FechaFinal, SemanasAtras, SemanasAdelante",16,"Error")
        RETURN .F.
    ENDIF

    TRY

        * Ajustar fecha al lunes
        ldFechaBase = tdFechaFinal - (DOW(tdFechaFinal,2) - 1)

        loExcel = CREATEOBJECT("Excel.Application")
        loExcel.Visible = .T.
        loLibro = loExcel.Workbooks.Add

        *===========================================
        * HOJA 1 - USD
        *===========================================
        loHojaUSD = loLibro.Sheets(1)
        loHojaUSD.Name = "CF I Q-AJUSTADO USD"

        FormatearHojaBase(loHojaUSD)

        * 1) Encabezado (estructura semanas + TRM)
        ArmarEncabezadoCashFlow(loHojaUSD, ;
                                "USD", ;
                                tdFechaFinal, ;
                                ldFechaBase, ;
                                tnSemanasAtras, ;
                                tnSemanasAdelante)

        * 2-7) Data (SQL recibe semanas absolutas)
        ArmarDataCashFlow(loHojaUSD, ;
                          tnSemanasAtras, ;
                          tnSemanasAdelante, ;
                          "USD")

        *===========================================
        * HOJA 2 - COP
        *===========================================
        CrearHojaCashFlow(loLibro, ;
                          "COP", ;
                          tdFechaFinal, ;
                          ldFechaBase, ;
                          tnSemanasAtras, ;
                          tnSemanasAdelante)

    CATCH TO loError

        lcErrorDetalle = ;
            "ERROR GENERANDO EXCEL" + CHR(13)+CHR(10)+CHR(13)+CHR(10) + ;
            "Mensaje: " + loError.Message + CHR(13)+CHR(10) + ;
            "Error No: " + TRANSFORM(loError.ErrorNo) + CHR(13)+CHR(10) + ;
            "Procedimiento: " + loError.Procedure + CHR(13)+CHR(10) + ;
            "Línea: " + TRANSFORM(loError.LineNo)

        MESSAGEBOX(lcErrorDetalle,16,"Error Fatal")

    ENDTRY

    RETURN .T.
ENDFUNC


*-----------------------------------------------------------
* CREA HOJA ADICIONAL (COP)
*-----------------------------------------------------------
FUNCTION CrearHojaCashFlow
    LPARAMETERS loLibro, tcMoneda, ;
                tdFechaFinal, ldFechaBase, ;
                tnSemanasAtras, tnSemanasAdelante

    LOCAL loHoja

    loHoja = loLibro.Sheets.Add(, loLibro.Sheets(loLibro.Sheets.Count))
    loHoja.Name = "CF I Q-AJUSTADO " + tcMoneda

    FormatearHojaBase(loHoja)

    ArmarEncabezadoCashFlow(loHoja, ;
                            tcMoneda, ;
                            tdFechaFinal, ;
                            ldFechaBase, ;
                            tnSemanasAtras, ;
                            tnSemanasAdelante)

    ArmarDataCashFlow(loHoja, ;
                      -tnSemanasAtras, ;
                      tnSemanasAdelante, ;
                      tcMoneda)

ENDFUNC

*-----------------------------------------------------------
* 1) ARMA ENCABEZADO
* Dibuja título y estructura visual superior.
*-----------------------------------------------------------
FUNCTION ArmarEncabezadoCashFlow
    LPARAMETERS loHoja, tcMoneda, ;
                tdFechaFinal, ldFechaBase, ;
                tnSemanasAtras, tnSemanasAdelante

    LOCAL lnColumna, lnUltimaColumna
    LOCAL ldFechaSemana, lnSemana, lnTRM, i

    loHoja.Cells(1,1).Value = ;
        "Flujo de Caja INTECPLAST SAS " + ;
        DTOC(tdFechaFinal) + " (" + tcMoneda + ")"

    loHoja.Range("A1").Font.Bold = .T.
    loHoja.Range("A1").Font.Size = 14

    IF tcMoneda = "USD"
        loHoja.Cells(3,1).Value = "TRM"
        loHoja.Cells(3,1).Font.Bold = .T.
    ENDIF

    lnColumna = 2

    FOR i = -tnSemanasAtras TO tnSemanasAdelante

        ldFechaSemana = ldFechaBase + (i * 7)
        lnSemana = WEEK(ldFechaSemana, 2)

        IF tcMoneda = "USD"
            lnTRM = ObtenerTRM(ldFechaSemana)
            loHoja.Cells(3, lnColumna).Value = lnTRM
            loHoja.Cells(3, lnColumna).NumberFormat = "#,##0.00"
        ENDIF

        loHoja.Cells(5, lnColumna).Value = ;
            "SEMANA " + TRANSFORM(lnSemana)

        loHoja.Cells(6, lnColumna).Value = ldFechaSemana
        loHoja.Cells(6, lnColumna).NumberFormat = "dd-mmm"

        IF i = 0
            loHoja.Cells(4, lnColumna).Value = "ACTUAL"
            loHoja.Cells(4, lnColumna).Font.Bold = .T.
            loHoja.Cells(5, lnColumna).Font.Bold = .T.
        ENDIF

        lnColumna = lnColumna + 1

    ENDFOR

    lnUltimaColumna = lnColumna - 1

    loHoja.Cells(5,1).Value = "PERIODO"
    loHoja.Cells(5,1).Font.Bold = .T.

    loHoja.Range( ;
        loHoja.Cells(5,1), ;
        loHoja.Cells(6,lnUltimaColumna) ;
    ).HorizontalAlignment = -4108

    WITH loHoja.Range( ;
        loHoja.Cells(3,1), ;
        loHoja.Cells(6,lnUltimaColumna) ;
    ).Borders
        .LineStyle = 1
        .Weight = 2
    ENDWITH

ENDFUNC


*-----------------------------------------------------------
* 2-7) ARMA DATA COMPLETA
* Ejecuta vistas SQL y dibuja Ingresos, Egresos,
* Subtotales y Flujo Neto.
*-----------------------------------------------------------
FUNCTION ArmarDataCashFlow
    LPARAMETERS loHoja, ;
                tnSemanaInicial, ;
                tnSemanaFinal, ;
                tcMoneda

    LOCAL lnFilaActual
    LOCAL lnFilaInicioIngresos, lnFilaFinIngresos
    LOCAL lnFilaInicioEgresos, lnFilaFinEgresos
    LOCAL lcSQL, lnResult, laError[1]

    lnFilaActual = 8

    *========================================
    * 2) EJECUTAR VISTA INGRESOS
    *========================================
    loHoja.Cells(lnFilaActual,1).Value = "INGRESOS"
    loHoja.Cells(lnFilaActual,1).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioIngresos = lnFilaActual

    lcSQL = ;
        "SELECT * FROM CashflowViewIngresos(" + ;
        ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
        ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
        ALLTRIM(tcMoneda) + "')"

    lnResult = SQLEXEC(ON, lcSQL, "csrIngresos")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowViewIngresos:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 3) Dibujar ingresos
    lnFilaActual = DibujarCursor(loHoja, "csrIngresos", lnFilaActual)

    lnFilaFinIngresos = lnFilaActual - 1

    * 4) Subtotal ingresos
    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioIngresos, ;
                                   lnFilaFinIngresos, ;
                                   lnFilaActual, ;
                                   "TOTAL INGRESOS")

    lnFilaActual = lnFilaActual + 2

    *========================================
    * 5) EJECUTAR VISTA EGRESOS
    *========================================
    loHoja.Cells(lnFilaActual,1).Value = "EGRESOS"
    loHoja.Cells(lnFilaActual,1).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioEgresos = lnFilaActual

    lcSQL = ;
        "SELECT * FROM CashflowViewEgresos(" + ;
        ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
        ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
        ALLTRIM(tcMoneda) + "')"

    lnResult = SQLEXEC(ON, lcSQL, "csrEgresos")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowViewEgresos:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 6) Dibujar egresos
    lnFilaActual = DibujarCursor(loHoja, "csrEgresos", lnFilaActual)

    lnFilaFinEgresos = lnFilaActual - 1

    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioEgresos, ;
                                   lnFilaFinEgresos, ;
                                   lnFilaActual, ;
                                   "TOTAL EGRESOS")

    lnFilaActual = lnFilaActual + 2

    * 7) Flujo Neto
    DibujarFlujoNeto(loHoja, ;
                     lnFilaFinIngresos + 1, ;
                     lnFilaFinEgresos + 1, ;
                     lnFilaActual)

ENDFUNC


*-----------------------------------------------------------
* Dibuja cursor completo en Excel
*-----------------------------------------------------------
FUNCTION DibujarCursor
    LPARAMETERS loHoja, tcCursor, lnFilaActual

    LOCAL lnCol

    SELECT (tcCursor)
    GO TOP

    SCAN
        FOR lnCol = 1 TO FCOUNT()
            loHoja.Cells(lnFilaActual, lnCol).Value = ;
                EVALUATE(FIELD(lnCol))
        ENDFOR
        lnFilaActual = lnFilaActual + 1
    ENDSCAN

    RETURN lnFilaActual
ENDFUNC


*-----------------------------------------------------------
* Dibuja subtotal por columna usando fórmula SUM
*-----------------------------------------------------------
FUNCTION DibujarSubtotal
    LPARAMETERS loHoja, ;
                lnFilaInicio, ;
                lnFilaFin, ;
                lnFilaSubtotal, ;
                tcTitulo

    LOCAL lnCol, lcLetraCol
    LOCAL lnUltimaCol

    loHoja.Cells(lnFilaSubtotal,1).Value = tcTitulo
    loHoja.Cells(lnFilaSubtotal,1).Font.Bold = .T.

    lnUltimaCol = loHoja.Cells(lnFilaInicio, ;
                   loHoja.Columns.Count).End(-4159).Column

    FOR lnCol = 2 TO lnUltimaCol

        lcLetraCol = ColumnaLetra(lnCol)

        loHoja.Cells(lnFilaSubtotal,lnCol).Formula = ;
            "=SUM(" + ;
            lcLetraCol + TRANSFORM(lnFilaInicio) + ":" + ;
            lcLetraCol + TRANSFORM(lnFilaFin) + ")"

        loHoja.Cells(lnFilaSubtotal,lnCol).Font.Bold = .T.

    ENDFOR

    RETURN lnFilaSubtotal
ENDFUNC


*-----------------------------------------------------------
* Calcula Flujo Neto (Ingresos - Egresos)
*-----------------------------------------------------------
FUNCTION DibujarFlujoNeto
    LPARAMETERS loHoja, ;
                lnFilaTotalIngresos, ;
                lnFilaTotalEgresos, ;
                lnFilaActual

    LOCAL lnCol, lcLetraCol
    LOCAL lnUltimaCol

    loHoja.Cells(lnFilaActual,1).Value = "FLUJO NETO"
    loHoja.Cells(lnFilaActual,1).Font.Bold = .T.

    lnUltimaCol = loHoja.Cells(lnFilaActual-1, ;
                   loHoja.Columns.Count).End(-4159).Column

    FOR lnCol = 2 TO lnUltimaCol

        lcLetraCol = ColumnaLetra(lnCol)

        loHoja.Cells(lnFilaActual,lnCol).Formula = ;
            "=" + lcLetraCol + TRANSFORM(lnFilaTotalIngresos) + ;
            "-" + lcLetraCol + TRANSFORM(lnFilaTotalEgresos)

        loHoja.Cells(lnFilaActual,lnCol).Font.Bold = .T.

    ENDFOR

ENDFUNC


*-----------------------------------------------------------
* Convierte número de columna a letra (A,B,C,...,AA)
*-----------------------------------------------------------
FUNCTION ColumnaLetra
    LPARAMETERS lnCol

    LOCAL lcLetra
    lcLetra = ""

    DO WHILE lnCol > 0
        lnCol = lnCol - 1
        lcLetra = CHR((lnCol % 26) + 65) + lcLetra
        lnCol = INT(lnCol / 26)
    ENDDO

    RETURN lcLetra
ENDFUNC


*-----------------------------------------------------------
* Formato base hoja Excel
*-----------------------------------------------------------
FUNCTION FormatearHojaBase
    LPARAMETERS loHoja

    loHoja.Cells.Font.Name = "Calibri"
    loHoja.Cells.Font.Size = 11
    loHoja.Columns(1).ColumnWidth = 25

ENDFUNC

*-----------------------------------------------------------
* OBTENER TRM DESDE SQL SERVER
* Devuelve la TRM para una fecha específica.
*-----------------------------------------------------------
FUNCTION ObtenerTRM
    LPARAMETERS tdFecha

    LOCAL lcSQL, lnResultado, lnValor, lcFecha

    lnValor = 0
    lcFecha = DTOC(tdFecha, 1)

    lcSQL = ;
        "SELECT TOP 1 VALOR FROM MTCAMBIO " + ;
        "WHERE FECHA >= '" + lcFecha + "' " + ;
        "AND FECHA < DATEADD(DAY,1,'" + lcFecha + "') " + ;
        "ORDER BY FECHA DESC"

    lnResultado = SQLEXEC(ON, lcSQL, "curTRM")

    IF lnResultado > 0 AND RECCOUNT("curTRM") > 0
        SELECT curTRM
        lnValor = curTRM.VALOR
        USE IN curTRM
    ENDIF

    RETURN lnValor
ENDFUNC