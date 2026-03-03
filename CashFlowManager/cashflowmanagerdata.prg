*===========================================================
*  Autor: Nicolas David Cubillos
*  Proyecto: Flujo de Caja INTECPLAST
*  Descripci�n:
*  Generador de Flujo de Caja semanal din�mico basado en SQL.
*  La l�gica financiera vive en SQL.
*  VFP solo dibuja estructura y f�rmulas en Excel.
*===========================================================
*-----------------------------------------------------------
* PALETA DE COLORES
*-----------------------------------------------------------
#DEFINE COLOR_BLANCO         16777215   && RGB(255,255,255) - fondo hoja
#DEFINE COLOR_TITULO_FUENTE         0   && RGB(  0,  0,  0) - negro, letras header y data
#DEFINE COLOR_HEADER_FONDO   12419407   && RGB( 79,129,189) - azul #4F81BD, fila PERIODO
#DEFINE COLOR_FILA_PAR       15853019   && RGB(219,229,241) - gris claro #DBE5F1, filas pares
#DEFINE COLOR_FILA_IMPAR     16777215   && RGB(255,255,255) - blanco, filas impares
*-----------------------------------------------------------
* FUNCI�N PRINCIPAL
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

        WAIT WINDOW "Inicializando generaci�n de Flujo de Caja..." NOWAIT  && NUEVO

        * Ajustar fecha al lunes
        ldFechaBase = tdFechaFinal - (DOW(tdFechaFinal,2) - 1)

        loExcel = CREATEOBJECT("Excel.Application")
        loExcel.Visible = .T.
        loLibro = loExcel.Workbooks.Add

        *===========================================
        * HOJA 1 - USD
        *===========================================
        WAIT WINDOW "Construyendo hoja USD..." NOWAIT  && NUEVO

        loHojaUSD = loLibro.Sheets(1)
        loHojaUSD.Name = "CF I Q-AJUSTADO USD"

        FormatearHojaBase(loHojaUSD)

        WAIT WINDOW "Armando encabezado USD..." NOWAIT  && NUEVO

        ArmarEncabezadoCashFlow(loHojaUSD, ;
                                "USD", ;
                                tdFechaFinal, ;
                                ldFechaBase, ;
                                tnSemanasAtras, ;
                                tnSemanasAdelante)

        WAIT WINDOW "Consultando y dibujando datos USD..." NOWAIT  && NUEVO

        * SQL historico: desde -tnSemanasAtras hasta la semana actual (0)
        ArmarDataCashFlowHistorico(loHojaUSD, ;
                                   -tnSemanasAtras, ;
                                   0, ;
                                   "USD")

        *===========================================
        * HOJA 2 - COP
        *===========================================
        WAIT WINDOW "Construyendo hoja COP..." NOWAIT  && NUEVO

        CrearHojaCashFlow(loLibro, ;
                          "COP", ;
                          tdFechaFinal, ;
                          ldFechaBase, ;
                          tnSemanasAtras, ;
                          tnSemanasAdelante)

        WAIT CLEAR  && NUEVO
        WAIT WINDOW "Flujo de Caja generado correctamente." TIMEOUT 2  && NUEVO

    CATCH TO loError

        lcErrorDetalle = ;
            "ERROR GENERANDO EXCEL" + CHR(13)+CHR(10)+CHR(13)+CHR(10) + ;
            "Mensaje: " + loError.Message + CHR(13)+CHR(10) + ;
            "Error No: " + TRANSFORM(loError.ErrorNo) + CHR(13)+CHR(10) + ;
            "Procedimiento: " + loError.Procedure + CHR(13)+CHR(10) + ;
            "L�nea: " + TRANSFORM(loError.LineNo)

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

    WAIT WINDOW "Creando hoja " + tcMoneda + "..." NOWAIT

    loHoja = loLibro.Sheets.Add(, loLibro.Sheets(loLibro.Sheets.Count))
    loHoja.Name = "CF I Q-AJUSTADO " + tcMoneda

    WAIT WINDOW "Formateando hoja " + tcMoneda + "..." NOWAIT
    FormatearHojaBase(loHoja)

    WAIT WINDOW "Armando encabezado " + tcMoneda + "..." NOWAIT
    ArmarEncabezadoCashFlow(loHoja, ;
                            tcMoneda, ;
                            tdFechaFinal, ;
                            ldFechaBase, ;
                            tnSemanasAtras, ;
                            tnSemanasAdelante)

    WAIT WINDOW "Consultando y dibujando datos " + tcMoneda + "..." NOWAIT
    * SQL historico: desde -tnSemanasAtras hasta la semana actual (0)
    ArmarDataCashFlowHistorico(loHoja, ;
                               -tnSemanasAtras, ;
                               0, ;
                               tcMoneda)

ENDFUNC

*-----------------------------------------------------------
* 1) ARMA ENCABEZADO
* Dibuja t�tulo y estructura visual superior.
*-----------------------------------------------------------
FUNCTION ArmarEncabezadoCashFlow
    LPARAMETERS loHoja, tcMoneda, ;
                tdFechaFinal, ldFechaBase, ;
                tnSemanasAtras, tnSemanasAdelante

    LOCAL lnColumna, lnUltimaColumna
    LOCAL ldFechaSemana, lnSemana, lnTRM, i
    LOCAL lcMes
    LOCAL ARRAY laMeses[12]
    laMeses[1]  = "Enero"
    laMeses[2]  = "Febrero"
    laMeses[3]  = "Marzo"
    laMeses[4]  = "Abril"
    laMeses[5]  = "Mayo"
    laMeses[6]  = "Junio"
    laMeses[7]  = "Julio"
    laMeses[8]  = "Agosto"
    laMeses[9]  = "Septiembre"
    laMeses[10] = "Octubre"
    laMeses[11] = "Noviembre"
    laMeses[12] = "Diciembre"
    lcMes = laMeses[MONTH(tdFechaFinal)]

    loHoja.Cells(2,2).Value = ;
        "Flujo de Caja " + lcMes + " " + ;
        TRANSFORM(YEAR(tdFechaFinal)) + " - Intecplast SAS"

    loHoja.Range("B2").Font.Name   = "Calibri"
    loHoja.Range("B2").Font.Size   = 14
    loHoja.Range("B2").Font.Bold   = .T.
    loHoja.Range("B2").Font.Italic = .T.

    IF tcMoneda = "USD"
        loHoja.Cells(3,2).Value = "TRM"
        loHoja.Cells(3,2).Font.Bold = .T.
    ENDIF

    lnColumna = 3

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

    loHoja.Cells(5,2).Value = "PERIODO"
    loHoja.Cells(5,2).Font.Bold = .T.

    loHoja.Range( ;
        loHoja.Cells(5,2), ;
        loHoja.Cells(6,lnUltimaColumna) ;
    ).HorizontalAlignment = -4108

    * Fila 5: PERIODO / SEMANA - fondo azul #4F81BD, letra negra, negrilla
    WITH loHoja.Range(loHoja.Cells(5,2), loHoja.Cells(5,lnUltimaColumna))
        .Font.Name      = "Calibri"
        .Font.Size      = 11
        .Font.Bold      = .T.
        .Font.Color     = COLOR_TITULO_FUENTE  && negro
        .Interior.Color = COLOR_HEADER_FONDO   && azul #4F81BD
    ENDWITH

    * Fila 6: fechas - fondo gris claro #DBE5F1, letra negra
    WITH loHoja.Range(loHoja.Cells(6,2), loHoja.Cells(6,lnUltimaColumna))
        .Interior.Color = COLOR_FILA_PAR       && gris claro #DBE5F1
        .Font.Color     = COLOR_TITULO_FUENTE  && negro
    ENDWITH

    * Bordes finos en el bloque del header (filas 5-6)
    WITH loHoja.Range(loHoja.Cells(5,2), loHoja.Cells(6,lnUltimaColumna)).Borders
        .LineStyle = 1   && xlContinuous
        .Weight    = 2   && xlThin
    ENDWITH

ENDFUNC


*-----------------------------------------------------------
* 2-7) ARMA DATA HISTORICA
* Ejecuta vistas SQL (solo historico) y dibuja Header,
* Ingresos, Egresos, Subtotales y Flujo Neto.
* tnSemanaInicial : numero negativo (ej. -5 = 5 semanas atras)
* tnSemanaFinal   : 0 = semana actual (no consulta futuro)
*-----------------------------------------------------------
FUNCTION ArmarDataCashFlowHistorico
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
	* 1) HEADER FINANCIERO (ANTES DE INGRESOS)
	*========================================
	WAIT WINDOW "Dibujando header financiero " + tcMoneda + "..." NOWAIT
	lnFilaActual = DibujarCashflowHeader(loHoja, ;
	                                     tnSemanaInicial, ;
	                                     tnSemanaFinal, ;
	                                     tcMoneda)

    *========================================
    * 2) EJECUTAR VISTA INGRESOS
    *========================================
    WAIT WINDOW "Ejecutando consulta de Ingresos " + tcMoneda + "..." NOWAIT
    LOCAL lnColsec
    lnColsec = loHoja.Cells(lnFilaActual-1, loHoja.Columns.Count).End(-4159).Column
    IF lnColsec < 2
        lnColsec = 10
    ENDIF
    loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnColsec)).Interior.Color = ColorFilaAlternar(lnFilaActual)
    loHoja.Cells(lnFilaActual,2).Value = "Ingresos"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioIngresos = lnFilaActual

    lcSQL = ;
	    "EXEC dbo.CashflowDataIngresosPivot " + ;
	    ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
	    ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
	    ALLTRIM(tcMoneda) + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrIngresos")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataIngresosPivot:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 3) Dibujar ingresos
    WAIT WINDOW "Dibujando Ingresos en Excel " + tcMoneda + "..." NOWAIT
    lnFilaActual = DibujarCursor(loHoja, "csrIngresos", lnFilaActual)

    lnFilaFinIngresos = lnFilaActual - 1

    * 4) Subtotal ingresos
    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioIngresos, ;
                                   lnFilaFinIngresos, ;
                                   lnFilaActual, ;
                                   "Total ingresos")

    lnFilaActual = lnFilaActual + 1

    *========================================
    * 5) EJECUTAR VISTA EGRESOS
    *========================================
    WAIT WINDOW "Ejecutando consulta de Egresos " + tcMoneda + "..." NOWAIT
    LOCAL lnColsec2
    lnColsec2 = loHoja.Cells(lnFilaActual-1, loHoja.Columns.Count).End(-4159).Column
    IF lnColsec2 < 2
        lnColsec2 = 10
    ENDIF
    loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnColsec2)).Interior.Color = ColorFilaAlternar(lnFilaActual)
    loHoja.Cells(lnFilaActual,2).Value = "Egresos"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioEgresos = lnFilaActual
    
    lcSQL = ;
	    "EXEC dbo.CashflowDataEgresosPivot " + ;
	    ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
	    ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
	    ALLTRIM(tcMoneda) + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrEgresos")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataEgresosPivot:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 6) Dibujar egresos
    WAIT WINDOW "Dibujando Egresos en Excel " + tcMoneda + "..." NOWAIT
    lnFilaActual = DibujarCursor(loHoja, "csrEgresos", lnFilaActual)

    lnFilaFinEgresos = lnFilaActual - 1

    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioEgresos, ;
                                   lnFilaFinEgresos, ;
                                   lnFilaActual, ;
                                   "Total egresos")

    lnFilaActual = lnFilaActual + 2

    * 7) Flujo Neto
    WAIT WINDOW "Calculando Flujo Neto " + tcMoneda + "..." NOWAIT
    DibujarFlujoNeto(loHoja, ;
                     lnFilaFinIngresos + 1, ;
                     lnFilaFinEgresos + 1, ;
                     lnFilaActual)

ENDFUNC


*-----------------------------------------------------------
* ARMA DATA FUTURA (pendiente de implementar)
* Dibujara proyecciones en las columnas futuras a partir
* de tnSemanaInicial=1 hasta tnSemanaFinal=tnSemanasAdelante.
* Por ahora NO se invoca desde GenerarCashFlowExcel.
*-----------------------------------------------------------
FUNCTION ArmarDataCashFlowFuturo
    LPARAMETERS loHoja, ;
                tnSemanaInicial, ;
                tnSemanaFinal, ;
                tcMoneda

    * TODO: implementar consulta y dibujo de semanas futuras

ENDFUNC


*-----------------------------------------------------------
* DIBUJA HEADER FINANCIERO (ANTES DE INGRESOS)
*-----------------------------------------------------------
FUNCTION DibujarCashflowHeader
    LPARAMETERS loHoja, ;
                tnSemanaInicial, ;
                tnSemanaFinal, ;
                tcMoneda

    LOCAL lcSQL, lnResult, laError[1]
    LOCAL lnFilaActual

    lnFilaActual = 8

    WAIT WINDOW "Ejecutando consulta Header " + tcMoneda + "..." NOWAIT

    lcSQL = ;
	    "EXEC dbo.CashflowDataHeaderPivot " + ;
	    ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
	    ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
	    tcMoneda + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrHeader")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataHeaderPivot:" + CHR(13) + laError[2])
        RETURN lnFilaActual
    ENDIF

    * Dibujar cursor completo
    lnFilaActual = DibujarCursor(loHoja, "csrHeader", lnFilaActual)

    RETURN lnFilaActual
ENDFUNC

*-----------------------------------------------------------
* Dibuja cursor completo en Excel
*-----------------------------------------------------------
FUNCTION DibujarCursor
    LPARAMETERS loHoja, tcCursor, lnFilaActual

    LOCAL lnCol, lnTotalCols

    SELECT (tcCursor)
    GO TOP

    SCAN
        lnTotalCols = FCOUNT()
        loHoja.Range( ;
            loHoja.Cells(lnFilaActual, 2), ;
            loHoja.Cells(lnFilaActual, lnTotalCols + 1) ;
        ).Interior.Color = ColorFilaAlternar(lnFilaActual)

        FOR lnCol = 1 TO lnTotalCols
            loHoja.Cells(lnFilaActual, lnCol + 1).Value = ;
                EVALUATE(FIELD(lnCol))
        ENDFOR

        * Formato numerico en columnas de datos (col 3 en adelante)
        IF lnTotalCols > 1
            loHoja.Range( ;
                loHoja.Cells(lnFilaActual, 3), ;
                loHoja.Cells(lnFilaActual, lnTotalCols + 1) ;
            ).NumberFormat = "#,##0"
        ENDIF

        * Borde fino en la fila de datos
        WITH loHoja.Range( ;
            loHoja.Cells(lnFilaActual, 2), ;
            loHoja.Cells(lnFilaActual, lnTotalCols + 1) ;
        ).Borders
            .LineStyle = 1
            .Weight    = 2
        ENDWITH

        lnFilaActual = lnFilaActual + 1
    ENDSCAN

    RETURN lnFilaActual
ENDFUNC


*-----------------------------------------------------------
* Dibuja subtotal por columna usando f�rmula SUM
*-----------------------------------------------------------
FUNCTION DibujarSubtotal
    LPARAMETERS loHoja, ;
                lnFilaInicio, ;
                lnFilaFin, ;
                lnFilaSubtotal, ;
                tcTitulo

    LOCAL lnCol, lcLetraCol
    LOCAL lnUltimaCol

    loHoja.Cells(lnFilaSubtotal,2).Value = tcTitulo
    loHoja.Cells(lnFilaSubtotal,2).Font.Bold = .T.

    lnUltimaCol = loHoja.Cells(lnFilaInicio, ;
                   loHoja.Columns.Count).End(-4159).Column

    loHoja.Range( ;
        loHoja.Cells(lnFilaSubtotal, 2), ;
        loHoja.Cells(lnFilaSubtotal, lnUltimaCol) ;
    ).Interior.Color = ColorFilaAlternar(lnFilaSubtotal)

    FOR lnCol = 3 TO lnUltimaCol

        lcLetraCol = ColumnaLetra(lnCol)

        loHoja.Cells(lnFilaSubtotal,lnCol).Formula = ;
            "=SUM(" + ;
            lcLetraCol + TRANSFORM(lnFilaInicio) + ":" + ;
            lcLetraCol + TRANSFORM(lnFilaFin) + ")"

        loHoja.Cells(lnFilaSubtotal,lnCol).Font.Bold = .T.
        loHoja.Cells(lnFilaSubtotal,lnCol).NumberFormat = "#,##0"

    ENDFOR

    * Borde fino en la fila de subtotal
    WITH loHoja.Range( ;
        loHoja.Cells(lnFilaSubtotal, 2), ;
        loHoja.Cells(lnFilaSubtotal, lnUltimaCol) ;
    ).Borders
        .LineStyle = 1
        .Weight    = 2
    ENDWITH

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

    loHoja.Cells(lnFilaActual,2).Value = "FLUJO NETO"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.

    lnUltimaCol = loHoja.Cells(lnFilaActual-1, ;
                   loHoja.Columns.Count).End(-4159).Column

    loHoja.Range( ;
        loHoja.Cells(lnFilaActual, 2), ;
        loHoja.Cells(lnFilaActual, lnUltimaCol) ;
    ).Interior.Color = ColorFilaAlternar(lnFilaActual)

    FOR lnCol = 3 TO lnUltimaCol

        lcLetraCol = ColumnaLetra(lnCol)

        loHoja.Cells(lnFilaActual,lnCol).Formula = ;
            "=" + lcLetraCol + TRANSFORM(lnFilaTotalIngresos) + ;
            "-" + lcLetraCol + TRANSFORM(lnFilaTotalEgresos)

        loHoja.Cells(lnFilaActual,lnCol).Font.Bold = .T.
        loHoja.Cells(lnFilaActual,lnCol).NumberFormat = "#,##0"

    ENDFOR

    * Borde fino en la fila de flujo neto
    WITH loHoja.Range( ;
        loHoja.Cells(lnFilaActual, 2), ;
        loHoja.Cells(lnFilaActual, lnUltimaCol) ;
    ).Borders
        .LineStyle = 1
        .Weight    = 2
    ENDWITH

ENDFUNC


*-----------------------------------------------------------
* Retorna color alterno: azul pastel o gris muy claro
*-----------------------------------------------------------
FUNCTION ColorFilaAlternar
    LPARAMETERS lnFila
    IF lnFila % 2 = 0
        RETURN COLOR_FILA_PAR    && azul pastel
    ELSE
        RETURN COLOR_FILA_IMPAR  && gris claro
    ENDIF
ENDFUNC


*-----------------------------------------------------------
* Convierte n�mero de columna a letra (A,B,C,...,AA)
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
    loHoja.Columns(1).ColumnWidth = 3    && col A vacia delgada (formato)
    loHoja.Columns(2).ColumnWidth = 25   && col B etiquetas

    * Fondo blanco toda la hoja
    loHoja.Cells.Interior.Color = COLOR_BLANCO  && fondo blanco toda la hoja

    * Sin lineas de cuadricula
    loHoja.Activate()
    loHoja.Parent.Parent.ActiveWindow.DisplayGridlines = .F.

ENDFUNC

*-----------------------------------------------------------
* OBTENER TRM DESDE SQL SERVER
* Devuelve la TRM para una fecha espec�fica.
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