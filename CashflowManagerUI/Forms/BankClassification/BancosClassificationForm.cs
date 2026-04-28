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
    /// Pantalla para asignar la moneda (COP / USD) a cada banco (MTBANCOS).
    /// Las clasificaciones posibles están en dbo.CashflowBankClassification.
    /// </summary>
    public class BancosClassificationForm : BaseProjectionForm
    {
        private DataTable _clasificaciones;
        private TextBox   _txtFiltro;

        protected override string TituloVentana => "Bancos — Clasificación Moneda (COP / USD)";

        protected override string ConnStr =>
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        // NOTA: CODIGOCTA es la PK del banco en MTBANCOS
        protected override string SelectSql =>
            "SELECT b.CODIGOCTA, RTRIM(LTRIM(b.NOMBRE)) AS NOMBRE, b.CashflowBankClassificationId " +
            "FROM dbo.MTBANCOS b " +
            "ORDER BY b.NOMBRE";

        protected override string SaveSql =>
            "SELECT CODIGOCTA, NOMBRE, CashflowBankClassificationId FROM dbo.MTBANCOS";

        public BancosClassificationForm()
        {
            // No se crean ni eliminan bancos desde esta pantalla
            BtnNuevo.Visible    = false;
            BtnEliminar.Visible = false;

            BtnGuardar.Location    = new Point(14,  10);
            BtnActualizar.Location = new Point(118, 10);
            BtnActualizar.Anchor   = AnchorStyles.Top | AnchorStyles.Left;

            AgregarBarraFiltro();
        }

        protected override void ConfigurarColumnas()
        {
            CargarClasificaciones();

            var colBanco = new DataGridViewTextBoxColumn
            {
                DataPropertyName = "CODIGOCTA",
                HeaderText       = "Código",
                Name             = "colBanco",
                ReadOnly         = true,
                FillWeight       = 60,
                MinimumWidth     = 80
            };

            var colNombre = new DataGridViewTextBoxColumn
            {
                DataPropertyName = "NOMBRE",
                HeaderText       = "Nombre del banco",
                Name             = "colNombre",
                ReadOnly         = true,
                FillWeight       = 200,
                MinimumWidth     = 220
            };

            var colClasif = new DataGridViewComboBoxColumn
            {
                DataPropertyName = "CashflowBankClassificationId",
                HeaderText       = "Moneda",
                Name             = "colClasif",
                DataSource       = _clasificaciones,
                ValueMember      = "Id",
                DisplayMember    = "Display",
                FillWeight       = 100,
                MinimumWidth     = 140,
                FlatStyle        = FlatStyle.Flat,
                DisplayStyle     = DataGridViewComboBoxDisplayStyle.ComboBox,
                SortMode         = DataGridViewColumnSortMode.Automatic
            };

            Dgv.Columns.AddRange(colBanco, colNombre, colClasif);
            Dgv.EditMode = DataGridViewEditMode.EditOnEnter;
        }

        protected override DataTable ConstruirTablaVacia()
        {
            var dt = new DataTable();
            dt.Columns.Add("CODIGOCTA",                    typeof(string));
            dt.Columns.Add("NOMBRE",                       typeof(string));
            dt.Columns.Add("CashflowBankClassificationId", typeof(string));
            foreach (DataColumn col in dt.Columns) col.AllowDBNull = true;
            return dt;
        }

        protected override void ValidarFila(DataRow row, StringBuilder errores)
        {
            // La clasificación es opcional: puede quedar nula
        }

        // ── Barra de búsqueda ─────────────────────────────────────────

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
                Size        = new Size(220, 24)
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
            btnLimpiar.Click += (s, e) => _txtFiltro.Clear();

            var pnlFiltro = new Panel
            {
                BackColor = Color.FromArgb(240, 244, 248),
                Dock      = DockStyle.Top,
                Size      = new Size(780, 42)
            };
            pnlFiltro.Controls.Add(btnLimpiar);
            pnlFiltro.Controls.Add(_txtFiltro);
            pnlFiltro.Controls.Add(lblFiltro);

            Controls.Add(pnlFiltro);
            Controls.SetChildIndex(pnlFiltro, 1);
        }

        private void AplicarFiltro()
        {
            string q = _txtFiltro?.Text.Trim() ?? "";
            if (string.IsNullOrEmpty(q))
            {
                Bs.Filter = null;
                return;
            }
            string safe = q.Replace("'", "''");
            Bs.Filter = $"CODIGOCTA LIKE '%{safe}%' OR NOMBRE LIKE '%{safe}%'";
        }

        // ── Catálogo de clasificaciones ───────────────────────────────

        private void CargarClasificaciones()
        {
            _clasificaciones = new DataTable();
            _clasificaciones.Columns.Add("Id",      typeof(string));
            _clasificaciones.Columns.Add("Display", typeof(string));

            // Fila vacía para "Sin clasificación"
            var rowVacio = _clasificaciones.NewRow();
            rowVacio["Id"]      = DBNull.Value;
            rowVacio["Display"] = "(Sin clasificación)";
            _clasificaciones.Rows.Add(rowVacio);

            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new OdbcCommand(
                        "SELECT Id, Descripcion FROM dbo.CashflowBankClassification ORDER BY ItemOrder",
                        conn))
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var row = _clasificaciones.NewRow();
                            row["Id"]      = reader["Id"].ToString().Trim();
                            row["Display"] = $"{reader["Id"].ToString().Trim()} — {reader["Descripcion"].ToString().Trim()}";
                            _clasificaciones.Rows.Add(row);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowError("No se pudo cargar el catálogo de clasificaciones:\n\n" + ex.Message,
                          "Error de catálogo");
            }
        }
    }
}
