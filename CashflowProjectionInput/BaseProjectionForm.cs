using System;
using System.Data;
using System.Data.Odbc;
using System.Drawing;
using System.Windows.Forms;

namespace CashflowProjectionInput
{
    /// <summary>
    /// Formulario base reutilizable.
    /// Provee la estética corporativa (header / toolbar / grid / footer)
    /// y el esqueleto CRUD completo.
    /// Cada pantalla hereda y solo implementa su contrato de datos.
    /// </summary>
    public abstract class BaseProjectionForm : Form
    {
        // ── UI compartida ─────────────────────────────────────────────
        protected readonly Panel        PnlHeader     = new Panel();
        protected readonly Panel        PnlAccent     = new Panel();
        protected readonly Label        LblTitle      = new Label();
        protected readonly Label        LblCompany    = new Label();
        protected readonly Panel        PnlToolbar    = new Panel();
        protected readonly Button       BtnNuevo      = new Button();
        protected readonly Button       BtnGuardar    = new Button();
        protected readonly Button       BtnEliminar   = new Button();
        protected readonly Button       BtnActualizar = new Button();
        protected readonly Label        LblStatus     = new Label();
        protected readonly Panel        PnlGrid       = new Panel();
        protected readonly DataGridView Dgv           = new DataGridView();
        protected readonly Panel        PnlFooter     = new Panel();
        protected readonly Label        LblFooter     = new Label();

        // ── Estado ────────────────────────────────────────────────────
        protected DataTable     Table;
        protected BindingSource Bs = new BindingSource();

        // ── Contrato que cada pantalla debe implementar ───────────────
        protected abstract string    TituloVentana    { get; }
        protected abstract string    ConnStr          { get; }
        protected abstract string    SelectSql        { get; }
        protected abstract string    SaveSql          { get; }
        protected abstract void      ConfigurarColumnas();
        protected abstract DataTable ConstruirTablaVacia();

        /// <summary>
        /// Hook de validación por fila antes de guardar.
        /// La subclase agrega mensajes al StringBuilder si hay errores.
        /// </summary>
        protected virtual void ValidarFila(DataRow row, System.Text.StringBuilder errores) { }

        // ── Constructor ───────────────────────────────────────────────
        protected BaseProjectionForm()
        {
            BuildUI();

            BtnNuevo.Click      += (s, e) => OnNuevo();
            BtnGuardar.Click    += (s, e) => OnGuardar();
            BtnEliminar.Click   += (s, e) => OnEliminar();
            BtnActualizar.Click += (s, e) => CargarDatos();
            Dgv.DataError       += (s, e) => e.ThrowException = false;
            Dgv.DataSource       = Bs;

            // Se inicializa en Load para que la subclase esté completamente construida
            Load += (s, e) =>
            {
                LblTitle.Text = TituloVentana;
                Text          = TituloVentana;
                ConfigurarColumnas();
                CargarDatos();
            };
        }

        // ── Construcción de UI ────────────────────────────────────────
        private void BuildUI()
        {
            SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)Dgv).BeginInit();

            // Accent strip
            PnlAccent.BackColor = Color.FromArgb(30, 58, 95);
            PnlAccent.Dock      = DockStyle.Left;
            PnlAccent.Size      = new Size(5, 64);

            // Company label
            LblCompany.AutoSize  = false;
            LblCompany.Dock      = DockStyle.Right;
            LblCompany.Font      = new Font("Segoe UI", 8.25F);
            LblCompany.ForeColor = Color.FromArgb(156, 163, 175);
            LblCompany.Padding   = new Padding(0, 0, 20, 0);
            LblCompany.Size      = new Size(200, 64);
            LblCompany.Text      = "INTECPLAST S.A.S.";
            LblCompany.TextAlign = ContentAlignment.MiddleRight;

            // Title label (text set on Load, once subclass is ready)
            LblTitle.AutoSize  = false;
            LblTitle.Dock      = DockStyle.Fill;
            LblTitle.Font      = new Font("Segoe UI Semibold", 14F);
            LblTitle.ForeColor = Color.FromArgb(17, 24, 39);
            LblTitle.Padding   = new Padding(16, 0, 0, 0);
            LblTitle.TextAlign = ContentAlignment.MiddleLeft;

            // Header panel
            PnlHeader.BackColor = Color.White;
            PnlHeader.Dock      = DockStyle.Top;
            PnlHeader.Size      = new Size(780, 64);
            PnlHeader.Controls.Add(LblTitle);
            PnlHeader.Controls.Add(LblCompany);
            PnlHeader.Controls.Add(PnlAccent);

            // Toolbar buttons
            StyleButton(BtnNuevo,      "Nuevo",      Color.FromArgb(30, 58, 95),  14);
            StyleButton(BtnGuardar,    "Guardar",    Color.FromArgb(4, 120, 87),  118);
            StyleButton(BtnEliminar,   "Eliminar",   Color.FromArgb(185, 28, 28), 222);
            StyleButton(BtnActualizar, "Actualizar", Color.FromArgb(30, 58, 95),  670);
            BtnActualizar.Anchor = AnchorStyles.Top | AnchorStyles.Right;

            // Status label
            LblStatus.AutoSize  = false;
            LblStatus.Anchor    = AnchorStyles.Top | AnchorStyles.Right;
            LblStatus.Font      = new Font("Segoe UI", 8.25F);
            LblStatus.ForeColor = Color.FromArgb(107, 114, 128);
            LblStatus.Location  = new Point(380, 0);
            LblStatus.Size      = new Size(280, 50);
            LblStatus.Text      = "Listo";
            LblStatus.TextAlign = ContentAlignment.MiddleRight;

            // Toolbar panel
            PnlToolbar.BackColor = Color.FromArgb(249, 250, 251);
            PnlToolbar.Dock      = DockStyle.Top;
            PnlToolbar.Size      = new Size(780, 50);
            PnlToolbar.Controls.Add(BtnActualizar);
            PnlToolbar.Controls.Add(LblStatus);
            PnlToolbar.Controls.Add(BtnEliminar);
            PnlToolbar.Controls.Add(BtnGuardar);
            PnlToolbar.Controls.Add(BtnNuevo);

            // DataGridView styles
            var headerStyle = new DataGridViewCellStyle
            {
                Alignment  = DataGridViewContentAlignment.MiddleCenter,
                BackColor  = Color.FromArgb(243, 244, 246),
                Font       = new Font("Segoe UI Semibold", 8.75F),
                ForeColor  = Color.FromArgb(55, 65, 81),
                Padding    = new Padding(4)
            };
            var cellStyle = new DataGridViewCellStyle
            {
                BackColor          = Color.White,
                Font               = new Font("Segoe UI", 9F),
                ForeColor          = Color.FromArgb(31, 41, 55),
                SelectionBackColor = Color.FromArgb(219, 234, 254),
                SelectionForeColor = Color.FromArgb(17, 24, 39)
            };
            var altRowStyle = new DataGridViewCellStyle
            {
                BackColor          = Color.FromArgb(249, 250, 251),
                SelectionBackColor = Color.FromArgb(219, 234, 254),
                SelectionForeColor = Color.FromArgb(17, 24, 39)
            };

            Dgv.AllowUserToAddRows              = false;
            Dgv.AllowUserToDeleteRows           = false;
            Dgv.AlternatingRowsDefaultCellStyle = altRowStyle;
            Dgv.AutoGenerateColumns             = false;
            Dgv.AutoSizeColumnsMode             = DataGridViewAutoSizeColumnsMode.Fill;
            Dgv.BackgroundColor                 = Color.White;
            Dgv.BorderStyle                     = BorderStyle.None;
            Dgv.CellBorderStyle                 = DataGridViewCellBorderStyle.SingleHorizontal;
            Dgv.ColumnHeadersBorderStyle        = DataGridViewHeaderBorderStyle.None;
            Dgv.ColumnHeadersDefaultCellStyle   = headerStyle;
            Dgv.ColumnHeadersHeight             = 36;
            Dgv.ColumnHeadersHeightSizeMode     = DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            Dgv.DefaultCellStyle                = cellStyle;
            Dgv.Dock                            = DockStyle.Fill;
            Dgv.EditMode                        = DataGridViewEditMode.EditOnEnter;
            Dgv.EnableHeadersVisualStyles       = false;
            Dgv.GridColor                       = Color.FromArgb(229, 231, 235);
            Dgv.MultiSelect                     = false;
            Dgv.RowHeadersVisible               = false;
            Dgv.RowTemplate.Height              = 30;
            Dgv.SelectionMode                   = DataGridViewSelectionMode.FullRowSelect;

            // Grid panel
            PnlGrid.BackColor = Color.White;
            PnlGrid.Dock      = DockStyle.Fill;
            PnlGrid.Padding   = new Padding(16, 8, 16, 8);
            PnlGrid.Controls.Add(Dgv);

            // Footer
            LblFooter.AutoSize  = false;
            LblFooter.Dock      = DockStyle.Fill;
            LblFooter.Font      = new Font("Segoe UI", 8F);
            LblFooter.ForeColor = Color.FromArgb(156, 163, 175);
            LblFooter.Text      = "CashFlow Manager  \u2022  INTECPLAST S.A.S.  \u2022  v1.0";
            LblFooter.TextAlign = ContentAlignment.MiddleCenter;

            PnlFooter.BackColor = Color.FromArgb(249, 250, 251);
            PnlFooter.Dock      = DockStyle.Bottom;
            PnlFooter.Size      = new Size(780, 28);
            PnlFooter.Controls.Add(LblFooter);

            // Form
            AutoScaleDimensions = new SizeF(6F, 13F);
            AutoScaleMode       = AutoScaleMode.Font;
            BackColor           = Color.White;
            ClientSize          = new Size(780, 500);
            Font                = new Font("Segoe UI", 9F);
            MinimumSize         = new Size(600, 400);
            StartPosition       = FormStartPosition.CenterScreen;

            // Orden de Controls.Add: Fill primero, luego Bottom, luego Top (inverso al visual)
            Controls.Add(PnlGrid);
            Controls.Add(PnlFooter);
            Controls.Add(PnlToolbar);
            Controls.Add(PnlHeader);

            ((System.ComponentModel.ISupportInitialize)Dgv).EndInit();
            ResumeLayout(false);
        }

        private static void StyleButton(Button btn, string text, Color back, int x)
        {
            btn.BackColor                 = back;
            btn.Cursor                    = Cursors.Hand;
            btn.FlatAppearance.BorderSize = 0;
            btn.FlatStyle                 = FlatStyle.Flat;
            btn.Font                      = new Font("Segoe UI", 8.75F);
            btn.ForeColor                 = Color.White;
            btn.Location                  = new Point(x, 10);
            btn.Size                      = new Size(96, 30);
            btn.Text                      = text;
            btn.UseVisualStyleBackColor   = false;
        }

        // ── CRUD base ─────────────────────────────────────────────────

        protected void CargarDatos()
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
                    foreach (DataColumn col in dt.Columns)
                        col.AllowDBNull = true;
                    Table         = dt;
                    Bs.DataSource = Table;
                }
                SetStatus($"{Table.Rows.Count} registro(s) cargado(s).");
            }
            catch (Exception ex)
            {
                SetStatus("Error al cargar datos.");
                ShowError("No se pudieron cargar los datos:\n\n" + ex.Message, "Error de conexión");
            }
        }

        protected virtual void OnNuevo()
        {
            if (Table == null)
            {
                Table         = ConstruirTablaVacia();
                Bs.DataSource = Table;
            }
            Bs.AddNew();
            SetStatus("Complete el nuevo registro y presione Guardar.");
            int idx = Dgv.Rows.Count - 1;
            if (idx >= 0 && Dgv.Columns.Count > 0)
            {
                Dgv.CurrentCell = Dgv.Rows[idx].Cells[0];
                Dgv.BeginEdit(true);
            }
        }

        protected virtual void OnGuardar()
        {
            Dgv.EndEdit();
            Bs.EndEdit();

            if (Table == null || Table.GetChanges() == null)
            {
                SetStatus("Sin cambios pendientes.");
                return;
            }

            var errores = new System.Text.StringBuilder();
            foreach (DataRow row in Table.Rows)
            {
                if (row.RowState == DataRowState.Deleted) continue;
                ValidarFila(row, errores);
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
                    var adapter = new OdbcDataAdapter(SaveSql, conn);
                    var builder = new OdbcCommandBuilder(adapter)
                    {
                        QuotePrefix    = "[",
                        QuoteSuffix    = "]",
                        ConflictOption = ConflictOption.OverwriteChanges
                    };
                    adapter.Update(Table);
                }
                Table.AcceptChanges();
                SetStatus("Cambios guardados correctamente.");
            }
            catch (Exception ex)
            {
                SetStatus("Error al guardar.");
                ShowError("No se pudieron guardar los cambios:\n\n" + ex.Message, "Error al guardar");
            }
        }

        protected virtual void OnEliminar()
        {
            if (Bs.Current == null) return;

            var confirm = MessageBox.Show(
                "¿Desea eliminar el registro seleccionado?\n" +
                "La eliminación se aplicará al presionar Guardar.",
                "Confirmar eliminación",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning,
                MessageBoxDefaultButton.Button2);

            if (confirm != DialogResult.Yes) return;

            if (Bs.Current is DataRowView drv)
            {
                drv.Row.Delete();
                SetStatus("Registro marcado para eliminar. Presione Guardar para confirmar.");
            }
        }

        // ── Helpers ───────────────────────────────────────────────────

        protected void SetStatus(string message)
        {
            LblStatus.Text = message;
            LblStatus.Refresh();
        }

        protected static void ShowError(string message, string title) =>
            MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
}
