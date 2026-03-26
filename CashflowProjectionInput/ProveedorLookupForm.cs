using System;
using System.Data;
using System.Data.Odbc;
using System.Windows.Forms;

namespace CashflowProjectionInput
{
    /// <summary>
    /// Popup de búsqueda de proveedor/cliente desde MTPROCLI.
    /// Uso: instanciar, llamar ShowDialog(), luego leer NitSeleccionado.
    /// </summary>
    public partial class ProveedorLookupForm : Form
    {
        // ────────────────────────────────────────────────────────────────
        // Resultado público
        // ────────────────────────────────────────────────────────────────
        public string NitSeleccionado { get; private set; }

        // ────────────────────────────────────────────────────────────────
        // Estado interno
        // ────────────────────────────────────────────────────────────────
        private readonly string      _connStr;
        private          DataTable   _allData;   // tabla completa, para filtrar
        private          BindingSource _bs = new BindingSource();

        private const string QuerySql =
            "SELECT m.NIT, RTRIM(LTRIM(m.NOMBRE)) AS NOMBRE, ISNULL(c.ParentName, '') AS ParentName " +
            "FROM dbo.MTPROCLI m " +
            "LEFT JOIN dbo.CashflowCategory c ON c.Id = m.CashflowCategoryId " +
            "ORDER BY m.NOMBRE";

        // ────────────────────────────────────────────────────────────────
        // Constructor
        // ────────────────────────────────────────────────────────────────
        public ProveedorLookupForm(string connStr)
        {
            _connStr = connStr;
            InitializeComponent();

            dgvProveedores.DataSource = _bs;
            CargarProveedores();
        }

        // ────────────────────────────────────────────────────────────────
        // Carga inicial de datos
        // ────────────────────────────────────────────────────────────────
        private void CargarProveedores()
        {
            try
            {
                using (var conn = new OdbcConnection(_connStr))
                {
                    conn.Open();
                    var adapter = new OdbcDataAdapter(QuerySql, conn);
                    _allData = new DataTable();
                    adapter.Fill(_allData);
                }

                _bs.DataSource = _allData;
                lblConteo.Text = $"{_allData.Rows.Count} registro(s)";
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "No se pudo cargar la lista de proveedores:\n\n" + ex.Message,
                    "Error de conexión",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }

        // ────────────────────────────────────────────────────────────────
        // Filtro en tiempo real mientras se escribe en el buscador
        // ────────────────────────────────────────────────────────────────
        private void txtBuscar_TextChanged(object sender, EventArgs e)
        {
            if (_allData == null) return;

            string filter = txtBuscar.Text.Trim().Replace("'", "''");

            if (string.IsNullOrEmpty(filter))
            {
                _allData.DefaultView.RowFilter = string.Empty;
            }
            else
            {
                _allData.DefaultView.RowFilter =
                    $"NIT LIKE '%{filter}%' OR " +
                    $"NOMBRE LIKE '%{filter}%' OR " +
                    $"ParentName LIKE '%{filter}%'";
            }

            lblConteo.Text = $"{_allData.DefaultView.Count} registro(s)";
        }

        // ────────────────────────────────────────────────────────────────
        // Selección: doble clic en fila
        // ────────────────────────────────────────────────────────────────
        private void dgvProveedores_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
                Seleccionar(e.RowIndex);
        }

        // ────────────────────────────────────────────────────────────────
        // Selección: Enter en la grilla
        // ────────────────────────────────────────────────────────────────
        private void dgvProveedores_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter && dgvProveedores.CurrentRow != null)
            {
                e.Handled = true;
                Seleccionar(dgvProveedores.CurrentRow.Index);
            }
        }

        // ────────────────────────────────────────────────────────────────
        // Enter en el buscador: bajar foco a la grilla
        // ────────────────────────────────────────────────────────────────
        private void txtBuscar_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter || e.KeyCode == Keys.Down)
            {
                e.Handled = true;
                dgvProveedores.Focus();
                if (dgvProveedores.Rows.Count > 0)
                    dgvProveedores.CurrentCell = dgvProveedores.Rows[0].Cells[0];
            }
            else if (e.KeyCode == Keys.Escape)
            {
                DialogResult = DialogResult.Cancel;
                Close();
            }
        }

        // ────────────────────────────────────────────────────────────────
        // Botón Seleccionar
        // ────────────────────────────────────────────────────────────────
        private void btnSeleccionar_Click(object sender, EventArgs e)
        {
            if (dgvProveedores.CurrentRow != null)
                Seleccionar(dgvProveedores.CurrentRow.Index);
        }

        // ────────────────────────────────────────────────────────────────
        // Botón Cancelar / Escape global
        // ────────────────────────────────────────────────────────────────
        private void btnCancelar_Click(object sender, EventArgs e)
        {
            DialogResult = DialogResult.Cancel;
            Close();
        }

        // ────────────────────────────────────────────────────────────────
        // Lógica central de selección
        // ────────────────────────────────────────────────────────────────
        private void Seleccionar(int rowIndex)
        {
            var cell = dgvProveedores.Rows[rowIndex].Cells["colPNIT"];
            if (cell?.Value == null || cell.Value == DBNull.Value) return;

            NitSeleccionado = cell.Value.ToString().Trim();
            DialogResult    = DialogResult.OK;
            Close();
        }
    }
}
