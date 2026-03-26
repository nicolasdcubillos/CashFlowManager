using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;

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
    }
}
