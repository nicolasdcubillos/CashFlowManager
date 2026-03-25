using System;
using System.Data;
using System.Data.Odbc;
using System.Windows.Forms;

namespace CashflowProjectionInput
{
    public partial class Form1 : Form
    {
        // ────────────────────────────────────────────────────────────────
        // Cadena de conexion ODBC
        // ────────────────────────────────────────────────────────────────
        private const string ConnStr =
            "Driver={ODBC Driver 17 for SQL Server};" +
            "Server=NICOLASD\\SQL2025;" +
            "Database=INTECPL;" +
            "Trusted_Connection=Yes;" +
            "TrustServerCertificate=Yes;";

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
            dgvProjection.DataSource = _bindingSource;
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

                    dt.PrimaryKey = new DataColumn[]
                    {
                        dt.Columns["NIT"],
                        dt.Columns["Year"],
                        dt.Columns["Week"]
                    };

                    _table                    = dt;
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
        private void SetStatus(string message)
        {
            lblStatus.Text = message;
            lblStatus.Refresh();
        }

        private static void ShowError(string message, string title)
        {
            MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        private static DataTable BuildEmptyTable()
        {
            var dt = new DataTable();
            dt.Columns.Add("NIT",            typeof(string));
            dt.Columns.Add("Year",           typeof(short));
            dt.Columns.Add("Week",           typeof(byte));
            dt.Columns.Add("TotalProjected", typeof(decimal));
            dt.PrimaryKey = new DataColumn[]
            {
                dt.Columns["NIT"],
                dt.Columns["Year"],
                dt.Columns["Week"]
            };
            return dt;
        }
    }
}
