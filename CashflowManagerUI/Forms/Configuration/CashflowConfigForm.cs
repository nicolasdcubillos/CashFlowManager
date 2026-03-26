using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;
using System.Text;
using System.Windows.Forms;

namespace CashFlowManager.UI
{
    /// <summary>
    /// CRUD completo para la tabla dbo.CashflowManagerConfig (Config / Value).
    /// Permite agregar, editar y eliminar parámetros de configuración del sistema.
    /// </summary>
    public class CashflowConfigForm : BaseProjectionForm
    {
        protected override string TituloVentana => "Configuración — CashFlow Manager";

        protected override string ConnStr =>
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        protected override string SelectSql =>
            "SELECT Config, Value FROM dbo.CashflowManagerConfig ORDER BY Config";

        // Requerido por la clase base; la lógica de guardado se sobreescribe abajo.
        protected override string SaveSql =>
            "SELECT Config, Value FROM dbo.CashflowManagerConfig";

        // ── Configuración de columnas ─────────────────────────────────

        protected override void ConfigurarColumnas()
        {
            var colConfig = new DataGridViewTextBoxColumn
            {
                DataPropertyName = "Config",
                HeaderText       = "Clave de configuración",
                Name             = "colConfig",
                FillWeight       = 130,
                MinimumWidth     = 180
            };

            var colValue = new DataGridViewTextBoxColumn
            {
                DataPropertyName = "Value",
                HeaderText       = "Valor",
                Name             = "colValue",
                FillWeight       = 220,
                MinimumWidth     = 200
            };

            Dgv.Columns.AddRange(colConfig, colValue);
            Dgv.EditMode = DataGridViewEditMode.EditOnEnter;
        }

        protected override DataTable ConstruirTablaVacia()
        {
            var dt = new DataTable();
            dt.Columns.Add("Config", typeof(string));
            dt.Columns.Add("Value",  typeof(string));
            foreach (DataColumn col in dt.Columns)
                col.AllowDBNull = true;
            return dt;
        }

        // ── Validación ────────────────────────────────────────────────

        protected override void ValidarFila(DataRow row, StringBuilder errores)
        {
            if (row["Config"] == DBNull.Value ||
                string.IsNullOrWhiteSpace(row["Config"]?.ToString()))
                errores.AppendLine("• La clave de configuración (Config) no puede estar vacía.");
        }

        // ── Guardar: INSERT / UPDATE / DELETE explícitos con parámetros ──

        protected override void OnGuardar()
        {
            Dgv.EndEdit();
            Bs.EndEdit();

            if (Table == null || Table.GetChanges() == null)
            {
                SetStatus("Sin cambios pendientes.");
                return;
            }

            // Validar todas las filas no eliminadas
            var errores = new StringBuilder();
            foreach (DataRow row in Table.Rows)
            {
                if (row.RowState == DataRowState.Deleted) continue;
                ValidarFila(row, errores);
            }

            if (errores.Length > 0)
            {
                ShowError("Corrija los siguientes errores antes de guardar:\n\n" + errores,
                          "Validación");
                return;
            }

            SetStatus("Guardando cambios...");
            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    foreach (DataRow row in Table.Rows)
                    {
                        switch (row.RowState)
                        {
                            case DataRowState.Added:
                                using (var cmd = conn.CreateCommand())
                                {
                                    cmd.CommandText =
                                        "INSERT INTO dbo.CashflowManagerConfig (Config, Value) " +
                                        "VALUES (?, ?)";
                                    cmd.Parameters.Add("@Config", OdbcType.NVarChar, 100).Value =
                                        row["Config"];
                                    cmd.Parameters.Add("@Value", OdbcType.NVarChar, -1).Value =
                                        row["Value"] ?? (object)DBNull.Value;
                                    cmd.ExecuteNonQuery();
                                }
                                break;

                            case DataRowState.Modified:
                                using (var cmd = conn.CreateCommand())
                                {
                                    cmd.CommandText =
                                        "UPDATE dbo.CashflowManagerConfig " +
                                        "SET Value = ? WHERE Config = ?";
                                    cmd.Parameters.Add("@Value", OdbcType.NVarChar, -1).Value =
                                        row["Value"] ?? (object)DBNull.Value;
                                    cmd.Parameters.Add("@Config", OdbcType.NVarChar, 100).Value =
                                        row["Config", DataRowVersion.Original];
                                    cmd.ExecuteNonQuery();
                                }
                                break;

                            case DataRowState.Deleted:
                                using (var cmd = conn.CreateCommand())
                                {
                                    cmd.CommandText =
                                        "DELETE FROM dbo.CashflowManagerConfig WHERE Config = ?";
                                    cmd.Parameters.Add("@Config", OdbcType.NVarChar, 100).Value =
                                        row["Config", DataRowVersion.Original];
                                    cmd.ExecuteNonQuery();
                                }
                                break;
                        }
                    }
                }

                Table.AcceptChanges();
                SetStatus("Cambios guardados correctamente.");
            }
            catch (Exception ex)
            {
                SetStatus("Error al guardar.");
                ShowError("No se pudieron guardar los cambios:\n\n" + ex.Message,
                          "Error al guardar");
            }
        }
    }
}
