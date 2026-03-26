using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace CashFlowManager.UI
{
    /// <summary>
    /// Pantalla para asignar la categoría de cashflow a cada proveedor/cliente.
    /// Hereda BaseProjectionForm para reutilizar estética y CRUD base.
    /// </summary>
    public class ProveedorCategoryForm : BaseProjectionForm
    {
        private DataTable _categories;
        private DataTable _categoriesEgresos;
        private DataTable _categoriesIngresos;
        private TextBox   _txtFiltro;
        private ComboBox  _cmbTipo;

        protected override string TituloVentana => "Proveedores — Categoría Flujo de Caja";

        protected override string ConnStr =>
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        protected override string SelectSql =>
            "SELECT p.NIT, RTRIM(LTRIM(p.NOMBRE)) AS NOMBRE, p.ESPROVEE, p.ESCLIENTE, p.CashflowCategoryId " +
            "FROM dbo.MTPROCLI p " +
            "ORDER BY p.NOMBRE";

        protected override string SaveSql =>
            "SELECT NIT, NOMBRE, CashflowCategoryId FROM dbo.MTPROCLI";

        public ProveedorCategoryForm()
        {
            // Ocultar botones que no aplican (no se crea ni elimina proveedores aquí)
            BtnNuevo.Visible    = false;
            BtnEliminar.Visible = false;

            // Mover Guardar y Actualizar a la izquierda
            BtnGuardar.Location    = new Point(14,  10);
            BtnActualizar.Location = new Point(118, 10);
            BtnActualizar.Anchor   = AnchorStyles.Top | AnchorStyles.Left;

            // Barra de filtro
            AgregarBarraFiltro();

            // Trim nombres después de que el Load base cargue los datos
            Load += (s, e) => TrimNombres();
        }

        protected override void ConfigurarColumnas()
        {
            CargarCategorias();
            PopularComboTipo();

            // NIT — readonly
            var colNit = new DataGridViewTextBoxColumn
            {
                DataPropertyName = "NIT",
                HeaderText       = "NIT",
                Name             = "colNIT",
                ReadOnly         = true,
                FillWeight       = 80,
                MinimumWidth     = 100
            };

            // NOMBRE — readonly
            var colNombre = new DataGridViewTextBoxColumn
            {
                DataPropertyName = "NOMBRE",
                HeaderText       = "Nombre",
                Name             = "colNombre",
                ReadOnly         = true,
                FillWeight       = 160,
                MinimumWidth     = 180
            };

            // Categoría — ComboBox editable
            var colCategoria = new DataGridViewComboBoxColumn
            {
                DataPropertyName    = "CashflowCategoryId",
                HeaderText          = "Categoría Flujo de Caja",
                Name                = "colCategoria",
                DataSource          = _categories,
                ValueMember         = "Id",
                DisplayMember       = "Display",
                FillWeight          = 160,
                MinimumWidth        = 200,
                FlatStyle           = FlatStyle.Flat,
                DisplayStyle        = DataGridViewComboBoxDisplayStyle.ComboBox,
                SortMode            = DataGridViewColumnSortMode.Automatic
            };

            Dgv.Columns.AddRange(colNit, colNombre, colCategoria);
            Dgv.EditMode = DataGridViewEditMode.EditOnEnter;
            Dgv.EditingControlShowing += Dgv_EditingControlShowing;
        }

        protected override DataTable ConstruirTablaVacia()
        {
            var dt = new DataTable();
            dt.Columns.Add("NIT",                 typeof(string));
            dt.Columns.Add("NOMBRE",              typeof(string));
            dt.Columns.Add("ESPROVEE",            typeof(string));
            dt.Columns.Add("ESCLIENTE",           typeof(string));
            dt.Columns.Add("CashflowCategoryId",  typeof(string));
            foreach (DataColumn col in dt.Columns) col.AllowDBNull = true;
            return dt;
        }

        protected override void ValidarFila(DataRow row, StringBuilder errores)
        {
            // No hay validación obligatoria: la categoría puede quedar nula
        }

        private void AgregarBarraFiltro()
        {
            var lblFiltro = new Label
            {
                AutoSize  = true,
                Font      = new Font("Segoe UI", 8.75F),
                ForeColor = Color.FromArgb(107, 114, 128),
                Location  = new Point(16, 13),
                Text      = "Buscar:"
            };

            _txtFiltro = new TextBox
            {
                BorderStyle = BorderStyle.FixedSingle,
                Font        = new Font("Segoe UI", 9.5F),
                Location    = new Point(65, 9),
                Size        = new Size(220, 24),
            };
            _txtFiltro.TextChanged += (s, e) => AplicarFiltro();

            var btnLimpiar = new Button
            {
                BackColor               = Color.FromArgb(107, 114, 128),
                Cursor                  = Cursors.Hand,
                FlatStyle               = FlatStyle.Flat,
                Font                    = new Font("Segoe UI", 8.25F),
                ForeColor               = Color.White,
                Location                = new Point(293, 8),
                Size                    = new Size(70, 26),
                Text                    = "Limpiar",
                UseVisualStyleBackColor = false
            };
            btnLimpiar.FlatAppearance.BorderSize = 0;
            btnLimpiar.Click += (s, e) =>
            {
                _txtFiltro.Clear();
                if (_cmbTipo != null) _cmbTipo.SelectedIndex = 0;
            };

            var lblTipo = new Label
            {
                AutoSize  = true,
                Font      = new Font("Segoe UI", 8.75F),
                ForeColor = Color.FromArgb(107, 114, 128),
                Location  = new Point(378, 13),
                Text      = "Tipo:"
            };

            _cmbTipo = new ComboBox
            {
                DropDownStyle = ComboBoxStyle.DropDownList,
                FlatStyle     = FlatStyle.Flat,
                Font          = new Font("Segoe UI", 9F),
                Location      = new Point(415, 9),
                Size          = new Size(280, 24)
            };
            _cmbTipo.SelectedIndexChanged += (s, e) => AplicarFiltro();

            var pnlFiltro = new Panel
            {
                BackColor = Color.FromArgb(240, 244, 248),
                Dock      = DockStyle.Top,
                Size      = new Size(780, 42)
            };
            pnlFiltro.Controls.Add(_cmbTipo);
            pnlFiltro.Controls.Add(lblTipo);
            pnlFiltro.Controls.Add(btnLimpiar);
            pnlFiltro.Controls.Add(_txtFiltro);
            pnlFiltro.Controls.Add(lblFiltro);

            Controls.Add(pnlFiltro);
            Controls.SetChildIndex(pnlFiltro, 1);
        }

        private void PopularComboTipo()
        {
            _cmbTipo.Items.Clear();
            _cmbTipo.Items.Add(new ComboItem(null, "(Todos)"));
            _cmbTipo.Items.Add(new ComboItem("", "(Sin categoría)"));
            foreach (DataRow row in _categories.Rows)
            {
                string id = row["Id"] == DBNull.Value ? null : row["Id"].ToString();
                if (id == null) continue;  // saltar la fila vacía ya agregada
                _cmbTipo.Items.Add(new ComboItem(id, row["Display"].ToString()));
            }
            _cmbTipo.SelectedIndex = 0;
        }

        // Par clave-valor para el ComboBox de tipo
        private sealed class ComboItem
        {
            public string Id      { get; }
            public string Display { get; }
            public ComboItem(string id, string display) { Id = id; Display = display; }
            public override string ToString() => Display;
        }

        private void AplicarFiltro()
        {
            var parts = new System.Collections.Generic.List<string>();

            // Filtro texto libre (NIT o nombre)
            string q = _txtFiltro?.Text.Trim() ?? "";
            if (!string.IsNullOrEmpty(q))
            {
                string safe = q.Replace("'", "''");
                parts.Add($"(NIT LIKE '%{safe}%' OR NOMBRE LIKE '%{safe}%')");
            }

            // Filtro por tipo
            if (_cmbTipo?.SelectedItem is ComboItem item && item.Id != null)
            {
                if (item.Id == "")   // (Sin categoría)
                    parts.Add("CashflowCategoryId IS NULL");
                else
                    parts.Add($"CashflowCategoryId = '{item.Id}'");
            }

            Bs.Filter = parts.Count > 0 ? string.Join(" AND ", parts) : null;
        }

        private void TrimNombres()
        {
            if (Table == null) return;
            foreach (DataRow row in Table.Rows)
            {
                if (row["NOMBRE"] != DBNull.Value)
                    row["NOMBRE"] = row["NOMBRE"].ToString().Trim();
            }
            Table.AcceptChanges();
        }

        private void Dgv_EditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs e)
        {
            if (Dgv.CurrentCell?.OwningColumn?.Name != "colCategoria") return;
            if (!(e.Control is ComboBox cmb)) return;

            var drv = Dgv.CurrentRow?.DataBoundItem as DataRowView;
            if (drv == null) return;

            string esProvee  = drv.Row["ESPROVEE"]?.ToString().Trim().ToUpper() ?? "";
            string esCliente = drv.Row["ESCLIENTE"]?.ToString().Trim().ToUpper() ?? "";

            DataTable source;
            if (esProvee == "S" && esCliente == "S")
                source = _categories;
            else if (esProvee == "S")
                source = _categoriesEgresos;
            else
                source = _categoriesIngresos;

            object currentValue = Dgv.CurrentCell.Value;
            cmb.DataSource    = source;
            cmb.ValueMember   = "Id";
            cmb.DisplayMember = "Display";

            if (currentValue != null && currentValue != DBNull.Value)
                cmb.SelectedValue = currentValue;
        }

        private void CargarCategorias()
        {
            _categories         = CrearTablaCategorias();
            _categoriesEgresos  = CrearTablaCategorias();
            _categoriesIngresos = CrearTablaCategorias();

            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new OdbcCommand(
                        "SELECT Id, Category, ParentName " +
                        "FROM dbo.CashflowCategory " +
                        "ORDER BY Category, ItemOrder", conn))
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string id      = reader["Id"].ToString().Trim();
                            string cat     = reader["Category"].ToString().Trim();
                            string parent  = reader["ParentName"].ToString().Trim();
                            string display = $"{cat} — {parent}";

                            _categories.Rows.Add(id, display);

                            if (cat == "EGRESOS")
                                _categoriesEgresos.Rows.Add(id, display);
                            else if (cat == "INGRESOS")
                                _categoriesIngresos.Rows.Add(id, display);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowError("Error al cargar categorías:\n\n" + ex.Message, "Error");
            }
        }

        private static DataTable CrearTablaCategorias()
        {
            var dt = new DataTable();
            dt.Columns.Add("Id",      typeof(string));
            dt.Columns.Add("Display", typeof(string));
            dt.Rows.Add(DBNull.Value, "(Sin categoría)");
            return dt;
        }
    }
}
