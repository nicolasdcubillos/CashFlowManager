using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;
using System.Windows.Forms;

namespace CashflowProjectionInput
{
    public partial class Form1 : Form
    {
        // ────────────────────────────────────────────────────────────────
        // Cadena de conexion leída desde App.config (<connectionStrings>)
        // ────────────────────────────────────────────────────────────────
        private static readonly string ConnStr =
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        private const string SelectSql =
            "SELECT NIT, [Year], [Week], TotalProjected " +
            "FROM dbo.CashflowProjection " +
            "ORDER BY NIT, [Year], [Week]";

        // ────────────────────────────────────────────────────────────────
        // Estado
        // ────────────────────────────────────────────────────────────────
        private DataTable     _table         = null;
        private BindingSource _bindingSource = new BindingSource();

        // ────────────────────────────────────────────────────────────────
        // Constructor
        // ────────────────────────────────────────────────────────────────
        public Form1()
        {
            InitializeComponent();
            dgvProjection.DataSource  = _bindingSource;
            dgvProjection.DataError  += dgvProjection_DataError;
            dgvProjection.EditMode    = DataGridViewEditMode.EditOnEnter;
        }

        // ────────────────────────────────────────────────────────────────
        // Interceptar Enter a nivel de Form, antes de que el grid lo consuma
        // ────────────────────────────────────────────────────────────────
        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.Enter && dgvProjection.Focused || 
                keyData == Keys.Enter && dgvProjection.IsCurrentCellInEditMode)
            {
                if (dgvProjection.CurrentCell == null)
                    return base.ProcessCmdKey(ref msg, keyData);

                // Si es celda NIT y está vacía → popup
                if (dgvProjection.CurrentCell.OwningColumn.Name == "colNIT")
                {
                    string texto = "";
                    if (dgvProjection.IsCurrentCellInEditMode && dgvProjection.EditingControl != null)
                        texto = dgvProjection.EditingControl.Text?.Trim() ?? "";
                    else
                        texto = dgvProjection.CurrentCell.Value?.ToString()?.Trim() ?? "";

                    if (string.IsNullOrEmpty(texto))
                    {
                        dgvProjection.EndEdit();
                        using (var popup = new ProveedorLookupForm(ConnStr))
                        {
                            if (popup.ShowDialog(this) == DialogResult.OK)
                            {
                                dgvProjection.CurrentCell.Value = popup.NitSeleccionado;
                            }
                        }
                    }
                }

                MoverSiguienteCelda();
                return true;  // marcar como procesado
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void MoverSiguienteCelda()
        {
            dgvProjection.EndEdit();
            int col = dgvProjection.CurrentCell.ColumnIndex;
            int row = dgvProjection.CurrentCell.RowIndex;

            if (col + 1 < dgvProjection.ColumnCount)
            {
                dgvProjection.CurrentCell = dgvProjection.Rows[row].Cells[col + 1];
            }
            else if (row + 1 < dgvProjection.Rows.Count)
            {
                dgvProjection.CurrentCell = dgvProjection.Rows[row + 1].Cells[0];
            }
        }

        // ────────────────────────────────────────────────────────────────
        // CARGAR — trae todos los registros de la BD
        // ────────────────────────────────────────────────────────────────
        private void btnCargar_Click(object sender, EventArgs e)
        {
            SetStatus("Conectando a la base de datos...");
            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    SetStatus("Cargando datos...");

                    var adapter = new OdbcDataAdapter(SelectSql, conn);
                    var dt      = new DataTable();
                    adapter.Fill(dt);

                    // Relajar restricciones NOT NULL en el cliente;
                    // la BD las sigue aplicando al guardar.
                    foreach (DataColumn col in dt.Columns)
                        col.AllowDBNull = true;

                    _table = dt;
                    _bindingSource.DataSource = _table;
                }

                SetStatus($"{_table.Rows.Count} registro(s) cargado(s).");
            }
            catch (Exception ex)
            {
                SetStatus("Error al cargar datos.");
                ShowError("No se pudieron cargar los datos:\n\n" + ex.Message, "Error de conexión");
            }
        }

        // ────────────────────────────────────────────────────────────────
        // NUEVO — agrega una fila en blanco para editar
        // ────────────────────────────────────────────────────────────────
        private void btnNuevo_Click(object sender, EventArgs e)
        {
            if (_table == null)
            {
                _table                    = BuildEmptyTable();
                _bindingSource.DataSource = _table;
            }

            _bindingSource.AddNew();
            SetStatus("Complete el nuevo registro y presione Guardar.");

            int newRowIdx = dgvProjection.Rows.Count - 1;
            if (newRowIdx >= 0)
            {
                dgvProjection.CurrentCell = dgvProjection.Rows[newRowIdx].Cells["colNIT"];
                dgvProjection.BeginEdit(true);
            }
        }

        // ────────────────────────────────────────────────────────────────
        // GUARDAR — persiste todos los cambios pendientes en la BD
        // ────────────────────────────────────────────────────────────────
        private void btnGuardar_Click(object sender, EventArgs e)
        {
            dgvProjection.EndEdit();
            _bindingSource.EndEdit();

            if (_table == null || _table.GetChanges() == null)
            {
                SetStatus("Sin cambios pendientes.");
                return;
            }

            // ─ Validar filas modificadas/nuevas antes de enviar a BD ─
            var errores = new System.Text.StringBuilder();
            foreach (DataRow row in _table.Rows)
            {
                if (row.RowState == DataRowState.Deleted) continue;

                // Año
                if (row["Year"] == DBNull.Value ||
                    !short.TryParse(row["Year"].ToString(), out short anio) ||
                    anio < 2000 || anio > 3000)
                {
                    errores.AppendLine($"  • NIT '{row["NIT"]}': Año '{row["Year"]}' inválido (debe estar entre 2000 y 3000).");
                }

                // Semana
                if (row["Week"] == DBNull.Value ||
                    !byte.TryParse(row["Week"].ToString(), out byte semana))
                {
                    errores.AppendLine($"  • NIT '{row["NIT"]}': Semana inválida.");
                }
                else if (row["Year"] != DBNull.Value &&
                         short.TryParse(row["Year"].ToString(), out short anioSem) &&
                         anioSem >= 2000 && anioSem <= 3000)
                {
                    int maxSemana = IsoWeeksInYear(anioSem);
                    if (semana < 1 || semana > maxSemana)
                        errores.AppendLine($"  • NIT '{row["NIT"]}': Semana {semana} inválida para el año {anioSem} (máx. {maxSemana}).");
                }
            }

            if (errores.Length > 0)
            {
                ShowError("Corrija los siguientes errores antes de guardar:\n\n" + errores, "Validación");
                return;
            }

            SetStatus("Guardando cambios...");
            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();

                    const string saveSql =
                        "SELECT NIT, [Year], [Week], TotalProjected " +
                        "FROM dbo.CashflowProjection";

                    var adapter = new OdbcDataAdapter(saveSql, conn);
                    var builder = new OdbcCommandBuilder(adapter)
                    {
                        QuotePrefix     = "[",
                        QuoteSuffix     = "]",
                        ConflictOption  = ConflictOption.OverwriteChanges
                    };

                    adapter.Update(_table);
                }

                _table.AcceptChanges();
                SetStatus("Cambios guardados correctamente.");
            }
            catch (Exception ex)
            {
                SetStatus("Error al guardar.");
                ShowError("No se pudieron guardar los cambios:\n\n" + ex.Message, "Error al guardar");
            }
        }

        // ────────────────────────────────────────────────────────────────
        // ELIMINAR — marca la fila seleccionada para borrado
        // ────────────────────────────────────────────────────────────────
        private void btnEliminar_Click(object sender, EventArgs e)
        {
            if (_bindingSource.Current == null) return;

            var confirm = MessageBox.Show(
                "¿Desea eliminar el registro seleccionado?\n" +
                "La eliminación se aplicará al presionar Guardar.",
                "Confirmar eliminación",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning,
                MessageBoxDefaultButton.Button2);

            if (confirm != DialogResult.Yes) return;

            if (_bindingSource.Current is DataRowView drv)
            {
                drv.Row.Delete();
                SetStatus("Registro marcado para eliminar. Presione Guardar para confirmar.");
            }
        }

        // ────────────────────────────────────────────────────────────────
        // Helpers
        // ────────────────────────────────────────────────────────────────
        // Evita que errores de validación interim (null en fila incompleta)
        // muestren un dialog al usuario mientras todavía está editando.
        private void dgvProjection_DataError(object sender, DataGridViewDataErrorEventArgs e)
        {
            e.ThrowException = false;
        }

        private void SetStatus(string message)
        {
            lblStatus.Text = message;
            lblStatus.Refresh();
        }

        private static void ShowError(string message, string title)
        {
            MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        // Un año ISO tiene 53 semanas si el 1 de enero o el 31 de diciembre cae en jueves.
        private static int IsoWeeksInYear(int year)
        {
            var jan1 = new DateTime(year, 1, 1);
            var dec31 = new DateTime(year, 12, 31);
            return (jan1.DayOfWeek == DayOfWeek.Thursday || dec31.DayOfWeek == DayOfWeek.Thursday)
                ? 53 : 52;
        }

        private static DataTable BuildEmptyTable()
        {
            var dt = new DataTable();
            dt.Columns.Add("NIT",            typeof(string));
            dt.Columns.Add("Year",           typeof(short));
            dt.Columns.Add("Week",           typeof(byte));
            dt.Columns.Add("TotalProjected", typeof(decimal));

            foreach (DataColumn col in dt.Columns)
                col.AllowDBNull = true;

            return dt;
        }
    }
}
