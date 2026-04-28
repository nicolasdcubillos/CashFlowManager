using System;
using System.Data;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using CashflowDataGenerator.Data;
using Excel = Microsoft.Office.Interop.Excel;

namespace CashflowDataGenerator.Services
{
    /// <summary>
    /// Genera el archivo Excel de Flujo de Caja.
    /// Migración directa de cashflowmanagerdata.prg (VFP).
    /// </summary>
    internal class ExcelCashFlowBuilder : IDisposable
    {
        // ── Paleta de colores ───────────────────────────────────────
        private const int ColorBlanco      = 16777215; // RGB(255,255,255)
        private const int ColorTituloFuente = 0;       // RGB(0,0,0)
        private const int ColorHeaderFondo = 12419407;  // #4F81BD
        private const int ColorFilaPar     = 15853019;  // #DBE5F1
        private const int ColorFilaImpar   = 16777215;  // blanco
        private const int ColorTotales     = 14341079;  // #D7D3DA

        private static readonly string[] Meses =
        {
            "", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
        };

        private const string NumFmt = "#.##0";

        private Excel.Application _app;
        private Excel.Workbook _libro;
        private bool _disposed;

        // ── Parámetros del flujo ────────────────────────────────────
        private readonly DateTime _fechaFinal;
        private readonly int _semanasAtras;
        private readonly int _semanasAdelante;
        private readonly DateTime _fechaBase;
        private readonly DateTime _fechaInicial;
        private readonly DateTime _fechaFinalRango;

        /// <summary>Evento para reportar progreso al formulario.</summary>
        public event Action<string> OnProgress;

        public ExcelCashFlowBuilder(DateTime fechaFinal)
        {
            _fechaFinal = fechaFinal;
            _semanasAtras = int.Parse(CashFlowRepository.ReadConfig("SemanasAtras", "6"));
            _semanasAdelante = int.Parse(CashFlowRepository.ReadConfig("SemanasAdelante", "6"));

            // Lunes de la semana de fechaFinal
            int dow = ((int)fechaFinal.DayOfWeek + 6) % 7; // 0=lun
            _fechaBase = fechaFinal.AddDays(-dow);

            _fechaInicial = _fechaBase.AddDays(-_semanasAtras * 7);
            _fechaFinalRango = _fechaBase.AddDays(_semanasAdelante * 7 + 6);
        }

        /// <summary>
        /// Genera el archivo Excel completo (hoja USD + hoja COP).
        /// Retorna la ruta del archivo guardado.
        /// </summary>
        public string Generar()
        {
            Report("Inicializando generación de Flujo de Caja...");

            string nombreArchivo = $"FlujoDeCaja_Intecplast_{Meses[_fechaFinal.Month]}{_fechaFinal.Year}.xlsx";
            string ruta = Path.Combine(Directory.GetCurrentDirectory(), nombreArchivo);

            _app = new Excel.Application { Visible = true };
            _libro = _app.Workbooks.Add();

            // ─── Hoja 1: USD ────────────────────────────────────────
            Report("Construyendo hoja USD...");
            var hojaUSD = (Excel.Worksheet)_libro.Sheets[1];
            hojaUSD.Name = "CF I Q-AJUSTADO USD";
            ConstruirHoja(hojaUSD, "USD");

            // ─── Hoja 2: COP ────────────────────────────────────────
            Report("Construyendo hoja COP...");
            var hojaCOP = (Excel.Worksheet)_libro.Sheets.Add(After: _libro.Sheets[_libro.Sheets.Count]);
            hojaCOP.Name = "CF I Q-AJUSTADO COP";
            ConstruirHoja(hojaCOP, "COP");

            // Guardar
            //Report($"Guardando {nombreArchivo}...");
            //_libro.SaveAs(ruta, Excel.XlFileFormat.xlOpenXMLWorkbook);
            Report("Flujo de Caja generado exitosamente.");

            return ruta;
        }

        // ═════════════════════════════════════════════════════════════
        //  CONSTRUCCIÓN DE UNA HOJA COMPLETA
        // ═════════════════════════════════════════════════════════════

        private void ConstruirHoja(Excel.Worksheet hoja, string moneda)
        {
            FormatearHojaBase(hoja);
            ArmarEncabezado(hoja, moneda);
            ArmarData(hoja, moneda);
        }

        // ─── Formato base ───────────────────────────────────────────

        private void FormatearHojaBase(Excel.Worksheet hoja)
        {
            hoja.Cells.Font.Name = "Calibri";
            hoja.Cells.Font.Size = 11;
            ((Excel.Range)hoja.Columns[1]).ColumnWidth = 3;
            hoja.Cells.Interior.Color = ColorBlanco;

            hoja.Activate();
            _app.ActiveWindow.DisplayGridlines = false;

            _app.ActiveWindow.FreezePanes = false;
            ((Excel.Range)hoja.Cells[8, 3]).Select();
            _app.ActiveWindow.FreezePanes = true;
        }

        // ─── Encabezado (filas 2-6) ────────────────────────────────

        private void ArmarEncabezado(Excel.Worksheet hoja, string moneda)
        {
            Report($"Armando encabezado {moneda}...");

            string mes = Meses[_fechaFinal.Month];
            hoja.Cells[2, 2] = $"Flujo de Caja {mes} {_fechaFinal.Year} - Intecplast SAS";
            var rB2 = (Excel.Range)hoja.Range["B2"];
            rB2.Font.Name = "Calibri";
            rB2.Font.Size = 14;
            rB2.Font.Bold = true;
            rB2.Font.Italic = true;

            if (moneda == "USD")
            {
                hoja.Cells[3, 2] = "TRM";
                ((Excel.Range)hoja.Cells[3, 2]).Font.Bold = true;
            }

            int col = 3;
            for (int i = -_semanasAtras; i <= _semanasAdelante; i++)
            {
                DateTime fechaSemana = _fechaBase.AddDays(i * 7);
                int isoWeek = GetIsoWeek(fechaSemana);

                if (moneda == "USD")
                {
                    decimal trm = CashFlowRepository.GetTRM(fechaSemana);
                    hoja.Cells[3, col] = (double)trm;
                    ((Excel.Range)hoja.Cells[3, col]).NumberFormat = "#,##0.00";
                }

                hoja.Cells[5, col] = $"SEMANA {isoWeek}";
                hoja.Cells[6, col] = fechaSemana;
                ((Excel.Range)hoja.Cells[6, col]).NumberFormat = "dd-mmm";

                if (i == 0)
                {
                    hoja.Cells[4, col] = "ACTUAL";
                    ((Excel.Range)hoja.Cells[4, col]).Font.Bold = true;
                    ((Excel.Range)hoja.Cells[5, col]).Font.Bold = true;
                }

                col++;
            }

            int ultimaCol = col - 1;

            hoja.Cells[5, 2] = "PERIODO";
            ((Excel.Range)hoja.Cells[5, 2]).Font.Bold = true;

            var rPeriodo = hoja.Range[hoja.Cells[5, 2], hoja.Cells[6, ultimaCol]];
            rPeriodo.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

            // Fila 5: header azul
            var rF5 = hoja.Range[hoja.Cells[5, 2], hoja.Cells[5, ultimaCol]];
            rF5.Font.Name = "Calibri";
            rF5.Font.Size = 11;
            rF5.Font.Bold = true;
            rF5.Font.Color = ColorTituloFuente;
            rF5.Interior.Color = ColorHeaderFondo;

            // Fila 6: fechas gris
            var rF6 = hoja.Range[hoja.Cells[6, 2], hoja.Cells[6, ultimaCol]];
            rF6.Interior.Color = ColorFilaPar;
            rF6.Font.Color = ColorTituloFuente;

            // Bordes header
            hoja.Range[hoja.Cells[5, 2], hoja.Cells[6, ultimaCol]].Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            hoja.Range[hoja.Cells[5, 2], hoja.Cells[6, ultimaCol]].Borders.Weight = Excel.XlBorderWeight.xlThin;
        }

        // ─── Data: header + ingresos + egresos + flujo económico ───

        private void ArmarData(Excel.Worksheet hoja, string moneda)
        {
            string fechaIni = _fechaInicial.ToString("yyyy-MM-dd");
            string fechaFin = _fechaFinalRango.ToString("yyyy-MM-dd");

            // Columna donde empieza la proyección (semanas futuras)
            int colProy = 3 + _semanasAtras + 1;

            // Rango solo-proyección: lunes de la primera semana futura → fin
            DateTime fechaIniProy = _fechaInicial.AddDays((_semanasAtras + 1) * 7);
            string fechaIniProy_s = fechaIniProy.ToString("yyyy-MM-dd");

            // ── 1) Header financiero (labels hard-coded, sin consulta DB) ─
            const int filaHdrCOP     = 8;
            const int filaHdrUSD     = 9;
            const int filaCredicorp  = 10;
            const int filaDispBancos = 11;
            int fila = 12;

            // Última columna de datos = col 3 + semanas pasadas + semanas futuras
            int ultimaColHdr = 3 + _semanasAtras + _semanasAdelante;

            hoja.Cells[filaHdrCOP,     2] = "Saldo inicial COP";
            hoja.Cells[filaHdrUSD,     2] = "Saldo inicial USD";
            hoja.Cells[filaCredicorp,  2] = "PA Credicorp - Excedentes";
            hoja.Cells[filaDispBancos, 2] = "Disponible Bancos";

            // Estilo filas de datos del header (igual que DibujarDataTable: color alterno + bordes + NumFmt en rango)
            foreach (int r in new[] { filaHdrCOP, filaHdrUSD, filaCredicorp, filaDispBancos })
            {
                var rFila = hoja.Range[hoja.Cells[r, 2], hoja.Cells[r, ultimaColHdr]];
                rFila.Interior.Color = ColorAlternar(r);
                rFila.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                rFila.Borders.Weight    = Excel.XlBorderWeight.xlThin;
                hoja.Range[hoja.Cells[r, 3], hoja.Cells[r, ultimaColHdr]].NumberFormat = NumFmt;
            }

            // Disponible Bancos = Saldo inicial COP + Saldo inicial USD + PA Credicorp - Excedentes
            for (int c = 3; c <= ultimaColHdr; c++)
            {
                string cl = ColumnaLetra(c);
                ((Excel.Range)hoja.Cells[filaDispBancos, c]).Formula =
                    $"={cl}{filaHdrCOP}+{cl}{filaHdrUSD}+{cl}{filaCredicorp}";
                ((Excel.Range)hoja.Cells[filaDispBancos, c]).NumberFormat = NumFmt;
            }

            if (moneda == "USD")
            {
                // Row 9: USD bank balance — DB call per week (lunes - 1 día)
                Report("Cargando Saldo inicial USD (banco)...");
                for (int c = 3; c <= ultimaColHdr; c++)
                {
                    DateTime weekDate = _fechaInicial.AddDays((c - 3) * 7);
                    decimal usd = CashFlowRepository.GetBankBalanceTotal(weekDate.AddDays(-1), "USD");
                    hoja.Cells[filaHdrUSD, c] = (double)usd;
                    ((Excel.Range)hoja.Cells[filaHdrUSD, c]).NumberFormat = NumFmt;
                }

                // Row 8, col 3: COP bank balance ÷ TRM → expresado en USD
                Report("Cargando Saldo inicial COP (semana 1, en USD)...");
                decimal copRaw = CashFlowRepository.GetBankBalanceTotal(_fechaInicial.AddDays(-1), "COP");
                decimal trm1   = CashFlowRepository.GetTRM(_fechaInicial);
                hoja.Cells[filaHdrCOP, 3] = trm1 > 0 ? (double)(copRaw / trm1) : 0.0;
                ((Excel.Range)hoja.Cells[filaHdrCOP, 3]).NumberFormat = NumFmt;

                // Row 10, col 3: PA Credicorp - Excedentes ÷ TRM → expresado en USD (solo semana 1)
                Report("Cargando PA Credicorp - Excedentes (semana 1, en USD)...");
                decimal pcaRaw = CashFlowRepository.GetBankBalanceTotal(_fechaInicial.AddDays(-1), "PCA");
                hoja.Cells[filaCredicorp, 3] = trm1 > 0 ? (double)(pcaRaw / trm1) : 0.0;
                ((Excel.Range)hoja.Cells[filaCredicorp, 3]).NumberFormat = NumFmt;
                for (int c = 4; c <= ultimaColHdr; c++)
                {
                    hoja.Cells[filaCredicorp, c] = 0;
                    ((Excel.Range)hoja.Cells[filaCredicorp, c]).NumberFormat = NumFmt;
                }
            }
            else // COP: todo se deriva de la hoja USD — cero llamadas a BD
            {
                // Row 9: USD balance × TRM → COP
                // Row 8, col 3: (COP/TRM) × TRM → COP  (invierte la conversión de la hoja USD)
                Report("Aplicando fórmulas de saldo de bancos desde hoja USD...");
                for (int c = 3; c <= ultimaColHdr; c++)
                {
                    string cl = ColumnaLetra(c);
                    ((Excel.Range)hoja.Cells[filaHdrUSD, c]).Formula =
                        $"='CF I Q-AJUSTADO USD'!{cl}{filaHdrUSD}*'CF I Q-AJUSTADO USD'!{cl}3";
                    ((Excel.Range)hoja.Cells[filaHdrUSD, c]).NumberFormat = NumFmt;
                }
                string c3 = ColumnaLetra(3);
                ((Excel.Range)hoja.Cells[filaHdrCOP, 3]).Formula =
                    $"='CF I Q-AJUSTADO USD'!{c3}{filaHdrCOP}*'CF I Q-AJUSTADO USD'!{c3}3";
                ((Excel.Range)hoja.Cells[filaHdrCOP, 3]).NumberFormat = NumFmt;

                // Row 10, col 3: PA Credicorp - Excedentes — invierte TRM desde hoja USD
                ((Excel.Range)hoja.Cells[filaCredicorp, 3]).Formula =
                    $"='CF I Q-AJUSTADO USD'!{c3}{filaCredicorp}*'CF I Q-AJUSTADO USD'!{c3}3";
                ((Excel.Range)hoja.Cells[filaCredicorp, 3]).NumberFormat = NumFmt;
                for (int c = 4; c <= ultimaColHdr; c++)
                {
                    hoja.Cells[filaCredicorp, c] = 0;
                    ((Excel.Range)hoja.Cells[filaCredicorp, c]).NumberFormat = NumFmt;
                }
            }

            // ── 2) Ingresos ─────────────────────────────────────────
            Report($"Consultando Ingresos {moneda}...");
            fila = DibujarTituloSeccion(hoja, fila, "Ingresos");
            int filaInicioIng = fila;

            fila = DibujarSeccionPivot(hoja, fila, "CashflowDataIngresos",
                fechaIni, fechaFin, moneda, label: null);

            if (_semanasAdelante > 0)
                SumarProyeccion(hoja, filaInicioIng, colProy,
                    "CashflowDataProjection", fechaIniProy_s, fechaFin, moneda, "INGRESOS");

            int filaFinIng = fila - 1;
            fila = DibujarSubtotal(hoja, filaInicioIng, filaFinIng, fila, "Total ingresos");
            fila += 1;

            // ── 3) Egresos ──────────────────────────────────────────
            Report($"Consultando Egresos {moneda}...");
            fila = DibujarTituloSeccion(hoja, fila, "Egresos");
            int filaInicioEgr = fila;

            fila = DibujarSeccionPivot(hoja, fila, "CashflowDataEgresos",
                fechaIni, fechaFin, moneda, label: null);

            if (_semanasAdelante > 0)
                SumarProyeccion(hoja, filaInicioEgr, colProy,
                    "CashflowDataProjection", fechaIniProy_s, fechaFin, moneda, "EGRESOS");

            int filaFinEgr = fila - 1;
            fila = DibujarSubtotal(hoja, filaInicioEgr, filaFinEgr, fila, "Total egresos");
            fila += 1;

            // ── 4) Flujo Económico ──────────────────────────────────
            Report($"Consultando Flujo Económico {moneda}...");
            fila = DibujarTituloSeccion(hoja, fila, "Flujo Economico");
            int filaInicioFE = fila;

            fila = DibujarSeccionPivot(hoja, fila, "CashflowDataFlujoEconomico",
                fechaIni, fechaFin, moneda, label: null);

            if (_semanasAdelante > 0)
                SumarProyeccion(hoja, filaInicioFE, colProy,
                    "CashflowDataProjection", fechaIniProy_s, fechaFin, moneda, "FINANCIAMIENTO");

            int filaFinFE = fila - 1;
            fila = DibujarSubtotal(hoja, filaInicioFE, filaFinFE, fila, "Total Financiamiento");
            fila += 1;

            // ── 5) Flujo de Caja Financiero (fila en 0) ────────────
            int ultimaColData = GetUltimaColumna(hoja, fila - 1);
            int filaFCF = fila;
            fila = DibujarFlujoCajaFinanciero(hoja, fila, ultimaColData);
            fila += 2;

            // Saldo inicial COP cols 4+: = FCF[col anterior] - USD[col actual]
            for (int c = 4; c <= ultimaColHdr; c++)
            {
                string prevCol = ColumnaLetra(c - 1);
                string currCol = ColumnaLetra(c);
                ((Excel.Range)hoja.Cells[filaHdrCOP, c]).Formula =
                    $"={prevCol}{filaFCF}-{currCol}{filaHdrUSD}";
                ((Excel.Range)hoja.Cells[filaHdrCOP, c]).NumberFormat = NumFmt;
            }

            // ── 6) Totales ──────────────────────────────────────────
            Report($"Dibujando Totales {moneda}...");
            DibujarTotales(hoja, fila, ultimaColData, filaHdrCOP, filaHdrUSD);

            // AutoFit columna B
            ((Excel.Range)hoja.Columns[2]).AutoFit();
        }

        // ═════════════════════════════════════════════════════════════
        //  MÉTODOS DE DIBUJO
        // ═════════════════════════════════════════════════════════════

        /// <summary>
        /// Ejecuta CashflowPivot y dibuja las filas resultantes.
        /// Retorna la fila siguiente disponible.
        /// </summary>
        private int DibujarSeccionPivot(Excel.Worksheet hoja, int fila,
            string functionName, string fechaIni, string fechaFin,
            string moneda, string label)
        {
            var dt = CashFlowRepository.ExecutePivot(functionName,
                DateTime.Parse(fechaIni), DateTime.Parse(fechaFin), moneda);
            return DibujarDataTable(hoja, dt, fila);
        }

        /// <summary>
        /// Dibuja un DataTable en Excel omitiendo ItemOrder.
        /// Retorna la fila siguiente disponible.
        /// </summary>
        private int DibujarDataTable(Excel.Worksheet hoja, DataTable dt, int fila)
        {
            foreach (DataRow row in dt.Rows)
            {
                int excelCol = 2;
                int lastExcelCol = 2;

                // Contar columnas visibles (sin ItemOrder)
                foreach (DataColumn dc in dt.Columns)
                    if (!dc.ColumnName.Equals("ItemOrder", StringComparison.OrdinalIgnoreCase))
                        lastExcelCol++;
                lastExcelCol--; // ajuste

                // Color alterno en toda la fila
                hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, lastExcelCol]]
                    .Interior.Color = ColorAlternar(fila);

                // Escribir valores
                excelCol = 2;
                foreach (DataColumn dc in dt.Columns)
                {
                    if (dc.ColumnName.Equals("ItemOrder", StringComparison.OrdinalIgnoreCase))
                        continue;
                    hoja.Cells[fila, excelCol] = row[dc] == DBNull.Value ? (object)0 : row[dc];
                    excelCol++;
                }

                // Formato numérico en columnas de datos (col 3+)
                if (lastExcelCol > 2)
                    hoja.Range[hoja.Cells[fila, 3], hoja.Cells[fila, lastExcelCol]]
                        .NumberFormat = NumFmt;

                // Bordes
                var rBorde = hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, lastExcelCol]];
                rBorde.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                rBorde.Borders.Weight = Excel.XlBorderWeight.xlThin;

                fila++;
            }

            return fila;
        }

        /// <summary>
        /// Suma valores de proyección sobre las celdas existentes (no sobreescribe).
        /// </summary>
        private void SumarProyeccion(Excel.Worksheet hoja, int filaInicio, int colInicio,
            string functionName, string fechaIni, string fechaFin,
            string moneda, string category)
        {
            Report($"Proyección {category} {moneda}...");
            var dt = CashFlowRepository.ExecutePivot(functionName,
                DateTime.Parse(fechaIni), DateTime.Parse(fechaFin), moneda, category);

            int filaActual = filaInicio;
            foreach (DataRow row in dt.Rows)
            {
                int excelCol = colInicio;
                foreach (DataColumn dc in dt.Columns)
                {
                    string name = dc.ColumnName.ToUpperInvariant();
                    if (name == "CONCEPTO" || name == "ITEMORDER")
                        continue;

                    decimal valorProy = row[dc] == DBNull.Value ? 0m
                        : Convert.ToDecimal(row[dc]);

                    if (valorProy != 0m)
                    {
                        object existing = ((Excel.Range)hoja.Cells[filaActual, excelCol]).Value2;
                        decimal valorExist = existing == null ? 0m
                            : Convert.ToDecimal(existing);
                        hoja.Cells[filaActual, excelCol] = (double)(valorExist + valorProy);
                    }

                    excelCol++;
                }

                if (excelCol > colInicio)
                {
                    var rango = hoja.Range[hoja.Cells[filaActual, colInicio],
                        hoja.Cells[filaActual, excelCol - 1]];
                    rango.NumberFormat = NumFmt;
                    rango.Interior.Color = ColorAlternar(filaActual);
                    rango.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                    rango.Borders.Weight = Excel.XlBorderWeight.xlThin;
                }

                filaActual++;
            }
        }

        /// <summary>
        /// Dibuja título de sección (Ingresos, Egresos, etc.) con formato bold.
        /// </summary>
        private int DibujarTituloSeccion(Excel.Worksheet hoja, int fila, string titulo)
        {
            int ultimaCol = GetUltimaColumna(hoja, fila - 1);
            if (ultimaCol < 10) ultimaCol = 10;

            hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, ultimaCol]]
                .Interior.Color = ColorAlternar(fila);
            hoja.Cells[fila, 2] = titulo;
            ((Excel.Range)hoja.Cells[fila, 2]).Font.Bold = true;

            return fila + 1;
        }

        /// <summary>
        /// Dibuja subtotal con fórmulas SUM por columna.
        /// </summary>
        private int DibujarSubtotal(Excel.Worksheet hoja, int filaInicio,
            int filaFin, int filaSubtotal, string titulo)
        {
            hoja.Cells[filaSubtotal, 2] = titulo;
            ((Excel.Range)hoja.Cells[filaSubtotal, 2]).Font.Bold = true;

            int ultimaCol = GetUltimaColumna(hoja, filaInicio);

            hoja.Range[hoja.Cells[filaSubtotal, 2], hoja.Cells[filaSubtotal, ultimaCol]]
                .Interior.Color = ColorAlternar(filaSubtotal);

            for (int c = 3; c <= ultimaCol; c++)
            {
                string letra = ColumnaLetra(c);
                string formula = $"=SUM({letra}{filaInicio}:{letra}{filaFin})";

                ((Excel.Range)hoja.Cells[filaSubtotal, c]).Formula = formula;
                ((Excel.Range)hoja.Cells[filaSubtotal, c]).Font.Bold = true;
            }

            hoja.Range[hoja.Cells[filaSubtotal, 3], hoja.Cells[filaSubtotal, ultimaCol]]
                .NumberFormat = NumFmt;

            var rBorde = hoja.Range[hoja.Cells[filaSubtotal, 2], hoja.Cells[filaSubtotal, ultimaCol]];
            rBorde.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            rBorde.Borders.Weight = Excel.XlBorderWeight.xlThin;

            return filaSubtotal;
        }

        /// <summary>
        /// Fila "Flujo de Caja Financiero" en 0.
        /// </summary>
        private int DibujarFlujoCajaFinanciero(Excel.Worksheet hoja, int fila, int ultimaCol)
        {
            hoja.Cells[fila, 2] = "Flujo de Caja Financiero";
            ((Excel.Range)hoja.Cells[fila, 2]).Font.Bold = true;
            hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, ultimaCol]]
                .Interior.Color = ColorAlternar(fila);

            for (int c = 3; c <= ultimaCol; c++)
            {
                hoja.Cells[fila, c] = 0;
                ((Excel.Range)hoja.Cells[fila, c]).Font.Bold = true;
            }

            hoja.Range[hoja.Cells[fila, 3], hoja.Cells[fila, ultimaCol]]
                .NumberFormat = NumFmt;

            var rBorde = hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, ultimaCol]];
            rBorde.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            rBorde.Borders.Weight = Excel.XlBorderWeight.xlThin;

            return fila + 1;
        }

        /// <summary>
        /// Sección de totales: 7 conceptos fijos con color #D7D3DA.
        /// "Disponible Bancos" = fórmula: Saldo inicial COP + Saldo inicial USD
        /// referenciando las filas del header (filaHdrCOP y filaHdrUSD).
        /// </summary>
        private void DibujarTotales(Excel.Worksheet hoja, int filaInicio, int ultimaCol,
            int filaHdrCOP, int filaHdrUSD)
        {
            string[] titulos =
            {
                "PA Credicorp - Caja Retenida Reserva Credito (83237)",
                "PA Credicorp - Caja Retenida Pago Cuota Trimestral (83238)",
                "FIC Credicorp - Provision Impuesto al Plastico",
                "Disponible Bancos",
                "TOTAL 30 NOV 2025",
                "TOTAL CONTABILIDAD",
                "DIFERENCIA"
            };

            int fila = filaInicio;
            foreach (string t in titulos)
            {
                hoja.Cells[fila, 2] = t;
                hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, ultimaCol]]
                    .Interior.Color = ColorTotales;

                bool esDisponible = t == "Disponible Bancos";

                for (int c = 3; c <= ultimaCol; c++)
                {
                    if (esDisponible)
                    {
                        // = Saldo inicial COP[col] + Saldo inicial USD[col] + PA Credicorp Excedentes[col]
                        string col = ColumnaLetra(c);
                        ((Excel.Range)hoja.Cells[fila, c]).Formula =
                            $"={col}{filaHdrCOP}+{col}{filaHdrUSD}+{col}{filaHdrCOP + 2}";
                    }
                    else
                        hoja.Cells[fila, c] = 0;
                }

                hoja.Range[hoja.Cells[fila, 3], hoja.Cells[fila, ultimaCol]]
                    .NumberFormat = NumFmt;

                var rBorde = hoja.Range[hoja.Cells[fila, 2], hoja.Cells[fila, ultimaCol]];
                rBorde.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                rBorde.Borders.Weight = Excel.XlBorderWeight.xlThin;

                fila++;
            }
        }



        // ═════════════════════════════════════════════════════════════
        //  UTILIDADES
        // ═════════════════════════════════════════════════════════════

        private static int ColorAlternar(int fila) =>
            fila % 2 == 0 ? ColorFilaPar : ColorFilaImpar;

        private static string ColumnaLetra(int col)
        {
            string result = "";
            while (col > 0)
            {
                col--;
                result = (char)('A' + col % 26) + result;
                col /= 26;
            }
            return result;
        }

        private static int GetIsoWeek(DateTime date)
        {
            var cal = System.Globalization.CultureInfo.InvariantCulture.Calendar;
            return cal.GetWeekOfYear(date,
                System.Globalization.CalendarWeekRule.FirstFourDayWeek,
                DayOfWeek.Monday);
        }

        private int GetUltimaColumna(Excel.Worksheet hoja, int fila)
        {
            int col = ((Excel.Range)hoja.Cells[fila, hoja.Columns.Count])
                .End[Excel.XlDirection.xlToLeft].Column;
            return col < 3 ? 10 : col;
        }

        private void Report(string msg) => OnProgress?.Invoke(msg);

        // ── Dispose ─────────────────────────────────────────────────

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;

            if (_libro != null) Marshal.ReleaseComObject(_libro);
            if (_app != null) Marshal.ReleaseComObject(_app);
        }
    }
}
