using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;
using System.Globalization;

namespace CashflowDataGenerator.Data
{
    /// <summary>
    /// Acceso a datos: ejecuta las TVFs y SPs del cashflow contra SQL Server.
    /// </summary>
    internal static class CashFlowRepository
    {
        private static string ConnStr =>
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        /// <summary>
        /// Cadena de conexion a la base de datos fuente de PedidosPendientes.
        /// Configurada en App.config bajo "PedidosPendientesDB".
        /// Actualmente apunta al mismo servidor/DB que CashflowDB;
        /// actualizar solo el App.config cuando la tabla migre.
        /// </summary>
        public static string PedidosConnStr =>
            ConfigurationManager.ConnectionStrings["PedidosPendientesDB"].ConnectionString;

        /// <summary>
        /// Lee un valor de CashflowManagerConfig. Retorna defaultValue si no existe.
        /// </summary>
        public static string ReadConfig(string key, string defaultValue)
        {
            const string sql = "SELECT Value FROM dbo.CashflowManagerConfig WHERE Config = ?";
            using (var cn = new OdbcConnection(ConnStr))
            using (var cmd = new OdbcCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@p", key);
                cn.Open();
                var result = cmd.ExecuteScalar();
                if (result == null || result == DBNull.Value)
                    return defaultValue;
                var val = result.ToString().Trim();
                return string.IsNullOrEmpty(val) ? defaultValue : val;
            }
        }

        /// <summary>
        /// Ejecuta CashflowPivot y retorna el DataTable resultante.
        /// </summary>
        public static DataTable ExecutePivot(string functionName, DateTime fechaInicial,
            DateTime fechaFinal, string moneda, string category = null)
        {
            string sql = category == null
                ? "EXEC dbo.CashflowPivot ?, ?, ?, ?"
                : "EXEC dbo.CashflowPivot ?, ?, ?, ?, ?";

            using (var cn = new OdbcConnection(ConnStr))
            using (var cmd = new OdbcCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@fn", functionName);
                cmd.Parameters.AddWithValue("@fi", fechaInicial.ToString("yyyy-MM-dd"));
                cmd.Parameters.AddWithValue("@ff", fechaFinal.ToString("yyyy-MM-dd"));
                cmd.Parameters.AddWithValue("@m", moneda);
                if (category != null)
                    cmd.Parameters.AddWithValue("@c", category);

                cn.Open();
                var dt = new DataTable();
                using (var da = new OdbcDataAdapter(cmd))
                    da.Fill(dt);
                ConvertStringColumnsToDouble(dt);
                return dt;
            }
        }

        /// <summary>
        /// Obtiene la TRM para una fecha específica.
        /// </summary>
        public static decimal GetTRM(DateTime fecha)
        {
            const string sql =
                "SELECT TOP 1 VALOR FROM MTCAMBIO " +
                "WHERE FECHA >= ? AND FECHA < DATEADD(DAY,1,?) " +
                "ORDER BY FECHA DESC";

            using (var cn = new OdbcConnection(ConnStr))
            using (var cmd = new OdbcCommand(sql, cn))
            {
                var f = fecha.ToString("yyyy-MM-dd");
                cmd.Parameters.AddWithValue("@f1", f);
                cmd.Parameters.AddWithValue("@f2", f);
                cn.Open();
                var result = cmd.ExecuteScalar();
                return result != null && result != DBNull.Value
                    ? Convert.ToDecimal(result)
                    : 0m;
            }
        }

        /// <summary>
        /// Suma los saldos bancarios a una fecha de corte (inclusive) para las cuentas
        /// clasificadas con <paramref name="moneda"/> (COP o USD).
        /// Reutiliza dbo.fnvOF_ReporteMVBancos_Saldos pasando la misma fecha como
        /// @FechaInicial y @FechaFinal: Saldo_Final incluye todos los movimientos
        /// hasta esa fecha. El filtro de moneda se aplica con JOIN a MTBANCOS.
        /// </summary>
        public static decimal GetBankBalanceTotal(DateTime fecha, string moneda)
        {
            const string sql =
                "SELECT SUM(s.Saldo_Final) " +
                "FROM dbo.fnvOF_ReporteMVBancos_Saldos(?, ?) s " +
                "INNER JOIN dbo.MTBANCOS b ON RTRIM(b.CODIGOCTA) = RTRIM(s.Banco) " +
                "WHERE b.CashflowBankClassificationId = ?";

            var f = fecha.ToString("yyyy-MM-dd");
            using (var cn = new OdbcConnection(ConnStr))
            using (var cmd = new OdbcCommand(sql, cn))
            {
                cmd.Parameters.AddWithValue("@fi",     f);
                cmd.Parameters.AddWithValue("@ff",     f);
                cmd.Parameters.AddWithValue("@moneda", moneda);
                cn.Open();
                var result = cmd.ExecuteScalar();
                return result != null && result != DBNull.Value
                    ? Convert.ToDecimal(result)
                    : 0m;
            }
        }

        /// <summary>
        /// ODBC devuelve columnas dinámicas del PIVOT como string.
        /// Convierte esas columnas a double para que Excel las trate como número.
        /// </summary>
        private static void ConvertStringColumnsToDouble(DataTable dt)
        {
            // Identificar columnas string que contengan números (saltar Concepto)
            for (int i = dt.Columns.Count - 1; i >= 0; i--)
            {
                var col = dt.Columns[i];
                if (col.DataType != typeof(string))
                    continue;

                string name = col.ColumnName.ToUpperInvariant();
                if (name == "CONCEPTO" || name == "ITEMORDER")
                    continue;

                // Verificar si la primera fila no-nula es numérica
                bool isNumeric = false;
                foreach (DataRow row in dt.Rows)
                {
                    if (row[col] == DBNull.Value) continue;
                    string s = row[col].ToString().Trim();
                    if (string.IsNullOrEmpty(s)) continue;
                    isNumeric = double.TryParse(s, NumberStyles.Any,
                        CultureInfo.CurrentCulture, out _);
                    break;
                }

                if (!isNumeric) continue;

                // Crear columna double de reemplazo
                string tmpName = col.ColumnName + "_tmp";
                var newCol = new DataColumn(tmpName, typeof(double));
                newCol.DefaultValue = 0.0;
                dt.Columns.Add(newCol);
                newCol.SetOrdinal(col.Ordinal);

                foreach (DataRow row in dt.Rows)
                {
                    if (row[col] == DBNull.Value) { row[newCol] = 0.0; continue; }
                    string s = row[col].ToString().Trim();
                    if (double.TryParse(s, NumberStyles.Any,
                            CultureInfo.CurrentCulture, out double val))
                        row[newCol] = val;
                    else
                        row[newCol] = 0.0;
                }

                dt.Columns.Remove(col);
                newCol.ColumnName = newCol.ColumnName.Replace("_tmp", "");
            }
        }
    }
}
