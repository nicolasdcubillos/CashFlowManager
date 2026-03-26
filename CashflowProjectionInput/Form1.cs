using System;
using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;
using System.Text;
using System.Windows.Forms;

namespace CashflowProjectionInput
{
    public partial class Form1 : Form
    {
        // ── Configuración ──────────────────────────────────────────────
        private string ConnStr =>
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        private const string SelectSql =
            "SELECT NIT, [Year], [Week], TotalProjected " +
            "FROM dbo.CashflowProjection " +
            "ORDER BY NIT, [Year], [Week]";

        private const string SaveSql =
            "SELECT NIT, [Year], [Week], TotalProjected FROM dbo.CashflowProjection";

        // ── Estado interno ─────────────────────────────────────────────
        private DataTable _dt;
        private OdbcDataAdapter _adapter;

        public Form1()
        {
            InitializeComponent();
            _dt = ConstruirTablaVacia();
            dgvProjection.DataSource = _dt;

            // Inicializar filtro al año e ISO semana actuales sin disparar recargas dobles
            nudAno.ValueChanged    -= nudAno_ValueChanged;
            nudSemana.ValueChanged -= nudSemana_ValueChanged;
            nudAno.Value    = DateTime.Today.Year;
            nudSemana.Value = GetIsoWeek(DateTime.Today);
            nudAno.ValueChanged    += nudAno_ValueChanged;
            nudSemana.ValueChanged += nudSemana_ValueChanged;

            CargarDatos();
        }

        // ── Carga de datos ─────────────────────────────────────────────
        private void CargarDatos()
        {
            bool anoBlanco    = string.IsNullOrWhiteSpace(nudAno.Text);
            bool semanaBlanca = string.IsNullOrWhiteSpace(nudSemana.Text);
            int  year         = anoBlanco    ? 0 : (int)nudAno.Value;
            int  week         = semanaBlanca ? 0 : (int)nudSemana.Value;
            bool filter       = year > 0 && week > 0;

            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();

                    if (filter)
                    {
                        string sql =
                            "SELECT NIT, [Year], [Week], TotalProjected " +
                            "FROM dbo.CashflowProjection " +
                            "WHERE [Year] = ? AND [Week] = ? " +
                            "ORDER BY NIT";
                        var cmd = new OdbcCommand(sql, conn);
                        var pYear = new OdbcParameter("Year", OdbcType.SmallInt) { Value = (short)year };
                        var pWeek = new OdbcParameter("Week", OdbcType.TinyInt)  { Value = (byte)week  };
                        cmd.Parameters.Add(pYear);
                        cmd.Parameters.Add(pWeek);
                        _adapter = new OdbcDataAdapter(cmd);
                    }
                    else
                    {
                        _adapter = new OdbcDataAdapter(SelectSql, conn);
                    }

                    _dt = ConstruirTablaVacia();
                    _adapter.Fill(_dt);
                    dgvProjection.DataSource = _dt;
                }
                lblStatus.Text = $"{_dt.Rows.Count} registro(s) cargados";
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Error al cargar datos:\n\n" + ex.Message,
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void nudAno_ValueChanged(object sender, EventArgs e)    => CargarDatos();
        private void nudSemana_ValueChanged(object sender, EventArgs e) => CargarDatos();

        private void nudAno_TextChanged(object sender, EventArgs e)    { if (string.IsNullOrWhiteSpace(nudAno.Text))    CargarDatos(); }
        private void nudSemana_TextChanged(object sender, EventArgs e) { if (string.IsNullOrWhiteSpace(nudSemana.Text)) CargarDatos(); }

        // ── Guardar ────────────────────────────────────────────────────
        private void GuardarDatos()
        {
            dgvProjection.EndEdit();

            var errores = new StringBuilder();
            foreach (DataRow row in _dt.Rows)
            {
                if (row.RowState == DataRowState.Deleted) continue;
                ValidarFila(row, errores);
            }

            if (errores.Length > 0)
            {
                MessageBox.Show(
                    "Corrija los siguientes errores antes de guardar:\n\n" + errores,
                    "Validación", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    using (var adapter = new OdbcDataAdapter(SaveSql, conn))
                    {
                        var cb = new OdbcCommandBuilder(adapter);
                        adapter.Update(_dt);
                    }
                }
                _dt.AcceptChanges();
                lblStatus.Text = "Datos guardados correctamente";
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Error al guardar:\n\n" + ex.Message,
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        // ── Event Handlers de botones ──────────────────────────────────
        private void btnCargar_Click(object sender, EventArgs e)
        {
            CargarDatos();
        }

        private void btnNuevo_Click(object sender, EventArgs e)
        {
            _dt.Rows.Add(_dt.NewRow());
            if (dgvProjection.Rows.Count > 0)
            {
                dgvProjection.ClearSelection();
                dgvProjection.CurrentCell =
                    dgvProjection.Rows[dgvProjection.Rows.Count - 1].Cells[0];
            }
            lblStatus.Text = "Nueva fila agregada";
        }

        private void btnGuardar_Click(object sender, EventArgs e)
        {
            GuardarDatos();
        }

        private void btnEliminar_Click(object sender, EventArgs e)
        {
            if (dgvProjection.CurrentRow == null) return;

            var result = MessageBox.Show(
                "¿Desea eliminar la fila seleccionada?",
                "Confirmar eliminación",
                MessageBoxButtons.YesNo, MessageBoxIcon.Question);

            if (result == DialogResult.Yes)
            {
                int idx = dgvProjection.CurrentRow.Index;
                if (idx >= 0 && idx < _dt.Rows.Count)
                {
                    _dt.Rows[idx].Delete();
                    lblStatus.Text = "Fila eliminada (guarde para confirmar)";
                }
            }
        }

        // ── Tabla vacía ────────────────────────────────────────────────
        private DataTable ConstruirTablaVacia()
        {
            var dt = new DataTable();
            dt.Columns.Add("NIT",            typeof(string));
            dt.Columns.Add("Year",           typeof(short));
            dt.Columns.Add("Week",           typeof(byte));
            dt.Columns.Add("TotalProjected", typeof(decimal));
            foreach (DataColumn col in dt.Columns) col.AllowDBNull = true;
            return dt;
        }

        // ── Validación ─────────────────────────────────────────────────
        private void ValidarFila(DataRow row, StringBuilder errores)
        {
            if (row["Year"] == DBNull.Value ||
                !short.TryParse(row["Year"].ToString(), out short anio) ||
                anio < 2000 || anio > 3000)
            {
                errores.AppendLine($"  \u2022 NIT '{row["NIT"]}': A\u00f1o '{row["Year"]}' inv\u00e1lido (debe estar entre 2000 y 3000).");
            }

            if (row["Week"] == DBNull.Value ||
                !byte.TryParse(row["Week"].ToString(), out byte semana))
            {
                errores.AppendLine($"  \u2022 NIT '{row["NIT"]}': Semana inv\u00e1lida.");
            }
            else if (row["Year"] != DBNull.Value &&
                     short.TryParse(row["Year"].ToString(), out short anioSem) &&
                     anioSem >= 2000 && anioSem <= 3000)
            {
                int max = IsoWeeksInYear(anioSem);
                if (semana < 1 || semana > max)
                    errores.AppendLine($"  \u2022 NIT '{row["NIT"]}': Semana {semana} inv\u00e1lida para el a\u00f1o {anioSem} (m\u00e1x. {max}).");
            }
        }

        // ── Popup NIT al presionar Enter en celda vacía ────────────────
        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.Enter && (dgvProjection.Focused || dgvProjection.IsCurrentCellInEditMode))
            {
                if (dgvProjection.CurrentCell == null)
                    return base.ProcessCmdKey(ref msg, keyData);

                if (dgvProjection.CurrentCell.OwningColumn.Name == "colNIT")
                {
                    string texto = dgvProjection.IsCurrentCellInEditMode && dgvProjection.EditingControl != null
                        ? dgvProjection.EditingControl.Text?.Trim() ?? ""
                        : dgvProjection.CurrentCell.Value?.ToString()?.Trim() ?? "";

                    if (string.IsNullOrEmpty(texto))
                    {
                        dgvProjection.EndEdit();
                        using (var popup = new ProveedorLookupForm(ConnStr))
                        {
                            if (popup.ShowDialog(this) == DialogResult.OK)
                                dgvProjection.CurrentCell.Value = popup.NitSeleccionado;
                        }
                    }
                }

                MoverSiguienteCelda();
                return true;
            }
            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void MoverSiguienteCelda()
        {
            dgvProjection.EndEdit();
            int col = dgvProjection.CurrentCell.ColumnIndex;
            int row = dgvProjection.CurrentCell.RowIndex;

            if (col + 1 < dgvProjection.ColumnCount)
                dgvProjection.CurrentCell = dgvProjection.Rows[row].Cells[col + 1];
            else if (row + 1 < dgvProjection.Rows.Count)
                dgvProjection.CurrentCell = dgvProjection.Rows[row + 1].Cells[0];
        }

        private static int IsoWeeksInYear(int year)
        {
            var jan1  = new DateTime(year, 1, 1);
            var dec31 = new DateTime(year, 12, 31);
            return (jan1.DayOfWeek == DayOfWeek.Thursday || dec31.DayOfWeek == DayOfWeek.Thursday)
                ? 53 : 52;
        }

        private static int GetIsoWeek(DateTime date) =>
            System.Globalization.CultureInfo.InvariantCulture.Calendar
                .GetWeekOfYear(date,
                    System.Globalization.CalendarWeekRule.FirstFourDayWeek,
                    DayOfWeek.Monday);
    }
}
