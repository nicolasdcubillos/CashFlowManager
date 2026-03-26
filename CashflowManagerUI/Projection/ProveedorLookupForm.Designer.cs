namespace CashFlowManager.UI
{
    partial class ProveedorLookupForm
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
                components.Dispose();
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        private void InitializeComponent()
        {
            this.pnlHeader       = new System.Windows.Forms.Panel();
            this.pnlAccent       = new System.Windows.Forms.Panel();
            this.lblTitulo       = new System.Windows.Forms.Label();
            this.pnlSearch       = new System.Windows.Forms.Panel();
            this.lblBuscar       = new System.Windows.Forms.Label();
            this.txtBuscar       = new System.Windows.Forms.TextBox();
            this.lblConteo       = new System.Windows.Forms.Label();
            this.pnlGrid         = new System.Windows.Forms.Panel();
            this.dgvProveedores  = new System.Windows.Forms.DataGridView();
            this.pnlFooter       = new System.Windows.Forms.Panel();
            this.btnCancelar     = new System.Windows.Forms.Button();
            this.btnSeleccionar  = new System.Windows.Forms.Button();
            this.colPNIT         = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.colPNombre      = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.colPTipoCli     = new System.Windows.Forms.DataGridViewTextBoxColumn();

            this.pnlHeader.SuspendLayout();
            this.pnlSearch.SuspendLayout();
            this.pnlGrid.SuspendLayout();
            this.pnlFooter.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvProveedores)).BeginInit();
            this.SuspendLayout();

            // ── pnlAccent ──────────────────────────────────────────────
            this.pnlAccent.BackColor = System.Drawing.Color.FromArgb(59, 108, 164);
            this.pnlAccent.Dock      = System.Windows.Forms.DockStyle.Left;
            this.pnlAccent.Size      = new System.Drawing.Size(8, 56);
            this.pnlAccent.TabIndex  = 0;

            // ── lblTitulo ──────────────────────────────────────────────
            this.lblTitulo.AutoSize  = false;
            this.lblTitulo.Dock      = System.Windows.Forms.DockStyle.Fill;
            this.lblTitulo.Font      = new System.Drawing.Font("Segoe UI", 13F, System.Drawing.FontStyle.Bold);
            this.lblTitulo.ForeColor = System.Drawing.Color.FromArgb(22, 54, 92);
            this.lblTitulo.Padding   = new System.Windows.Forms.Padding(14, 0, 0, 0);
            this.lblTitulo.TabIndex  = 1;
            this.lblTitulo.Text      = "Búsqueda de Proveedor / Cliente";
            this.lblTitulo.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;

            // ── pnlHeader ─────────────────────────────────────────────
            this.pnlHeader.BackColor = System.Drawing.Color.FromArgb(183, 211, 234);
            this.pnlHeader.Controls.Add(this.lblTitulo);
            this.pnlHeader.Controls.Add(this.pnlAccent);
            this.pnlHeader.Dock      = System.Windows.Forms.DockStyle.Top;
            this.pnlHeader.Size      = new System.Drawing.Size(680, 56);
            this.pnlHeader.TabIndex  = 0;

            // ── lblBuscar ─────────────────────────────────────────────
            this.lblBuscar.AutoSize  = true;
            this.lblBuscar.Font      = new System.Drawing.Font("Segoe UI", 8.75F);
            this.lblBuscar.ForeColor = System.Drawing.Color.FromArgb(107, 114, 128);
            this.lblBuscar.Location  = new System.Drawing.Point(14, 14);
            this.lblBuscar.TabIndex  = 0;
            this.lblBuscar.Text      = "Buscar:";

            // ── txtBuscar ─────────────────────────────────────────────
            this.txtBuscar.BorderStyle        = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtBuscar.Font               = new System.Drawing.Font("Segoe UI", 9.5F);
            this.txtBuscar.ForeColor          = System.Drawing.Color.FromArgb(31, 41, 55);
            this.txtBuscar.Location           = new System.Drawing.Point(72, 10);
            this.txtBuscar.Name               = "txtBuscar";
            this.txtBuscar.Size               = new System.Drawing.Size(380, 26);
            this.txtBuscar.TabIndex           = 1;
            this.txtBuscar.TextChanged       += new System.EventHandler(this.txtBuscar_TextChanged);
            this.txtBuscar.KeyDown           += new System.Windows.Forms.KeyEventHandler(this.txtBuscar_KeyDown);

            // ── lblConteo ─────────────────────────────────────────────
            this.lblConteo.AutoSize  = false;
            this.lblConteo.Font      = new System.Drawing.Font("Segoe UI", 8.25F);
            this.lblConteo.ForeColor = System.Drawing.Color.FromArgb(156, 163, 175);
            this.lblConteo.Location  = new System.Drawing.Point(464, 13);
            this.lblConteo.Size      = new System.Drawing.Size(190, 24);
            this.lblConteo.TabIndex  = 2;
            this.lblConteo.Text      = "";
            this.lblConteo.TextAlign = System.Drawing.ContentAlignment.MiddleRight;

            // ── pnlSearch ─────────────────────────────────────────────
            this.pnlSearch.BackColor = System.Drawing.Color.FromArgb(249, 250, 251);
            this.pnlSearch.Controls.Add(this.lblConteo);
            this.pnlSearch.Controls.Add(this.txtBuscar);
            this.pnlSearch.Controls.Add(this.lblBuscar);
            this.pnlSearch.Dock      = System.Windows.Forms.DockStyle.Top;
            this.pnlSearch.Size      = new System.Drawing.Size(680, 48);
            this.pnlSearch.TabIndex  = 1;

            // ── Estilos grilla ────────────────────────────────────────
            var headerStyle = new System.Windows.Forms.DataGridViewCellStyle();
            headerStyle.Alignment  = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            headerStyle.BackColor  = System.Drawing.Color.FromArgb(243, 244, 246);
            headerStyle.Font       = new System.Drawing.Font("Segoe UI Semibold", 8.75F);
            headerStyle.ForeColor  = System.Drawing.Color.FromArgb(55, 65, 81);
            headerStyle.Padding    = new System.Windows.Forms.Padding(6, 0, 0, 0);

            var cellStyle = new System.Windows.Forms.DataGridViewCellStyle();
            cellStyle.BackColor          = System.Drawing.Color.White;
            cellStyle.Font               = new System.Drawing.Font("Segoe UI", 9F);
            cellStyle.ForeColor          = System.Drawing.Color.FromArgb(31, 41, 55);
            cellStyle.SelectionBackColor = System.Drawing.Color.FromArgb(219, 234, 254);
            cellStyle.SelectionForeColor = System.Drawing.Color.FromArgb(17, 24, 39);

            var altRowStyle = new System.Windows.Forms.DataGridViewCellStyle();
            altRowStyle.BackColor          = System.Drawing.Color.FromArgb(249, 250, 251);
            altRowStyle.SelectionBackColor = System.Drawing.Color.FromArgb(219, 234, 254);
            altRowStyle.SelectionForeColor = System.Drawing.Color.FromArgb(17, 24, 39);

            // ── Columnas ──────────────────────────────────────────────
            // colPNIT
            this.colPNIT.DataPropertyName = "NIT";
            this.colPNIT.FillWeight       = 100F;
            this.colPNIT.HeaderText       = "NIT";
            this.colPNIT.MinimumWidth     = 100;
            this.colPNIT.Name             = "colPNIT";
            this.colPNIT.ReadOnly         = true;

            // colPNombre
            this.colPNombre.DataPropertyName = "NOMBRE";
            this.colPNombre.FillWeight       = 260F;
            this.colPNombre.HeaderText       = "Nombre";
            this.colPNombre.MinimumWidth     = 200;
            this.colPNombre.Name             = "colPNombre";
            this.colPNombre.ReadOnly         = true;

            // colPTipoCli
            this.colPTipoCli.DataPropertyName = "ParentName";
            this.colPTipoCli.FillWeight       = 200F;
            this.colPTipoCli.HeaderText       = "Categoría";
            this.colPTipoCli.MinimumWidth     = 140;
            this.colPTipoCli.Name             = "colPTipoCli";
            this.colPTipoCli.ReadOnly         = true;

            // ── dgvProveedores ────────────────────────────────────────
            this.dgvProveedores.AllowUserToAddRows              = false;
            this.dgvProveedores.AllowUserToDeleteRows           = false;
            this.dgvProveedores.AllowUserToResizeRows           = false;
            this.dgvProveedores.AlternatingRowsDefaultCellStyle = altRowStyle;
            this.dgvProveedores.AutoGenerateColumns             = false;
            this.dgvProveedores.AutoSizeColumnsMode             = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill;
            this.dgvProveedores.BackgroundColor                 = System.Drawing.Color.White;
            this.dgvProveedores.BorderStyle                     = System.Windows.Forms.BorderStyle.None;
            this.dgvProveedores.CellBorderStyle                 = System.Windows.Forms.DataGridViewCellBorderStyle.SingleHorizontal;
            this.dgvProveedores.ColumnHeadersBorderStyle        = System.Windows.Forms.DataGridViewHeaderBorderStyle.None;
            this.dgvProveedores.ColumnHeadersDefaultCellStyle   = headerStyle;
            this.dgvProveedores.ColumnHeadersHeight             = 34;
            this.dgvProveedores.ColumnHeadersHeightSizeMode     = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            this.dgvProveedores.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[]
            {
                this.colPNIT, this.colPNombre, this.colPTipoCli
            });
            this.dgvProveedores.DefaultCellStyle            = cellStyle;
            this.dgvProveedores.Dock                        = System.Windows.Forms.DockStyle.Fill;
            this.dgvProveedores.EnableHeadersVisualStyles   = false;
            this.dgvProveedores.GridColor                   = System.Drawing.Color.FromArgb(229, 231, 235);
            this.dgvProveedores.MultiSelect                 = false;
            this.dgvProveedores.Name                        = "dgvProveedores";
            this.dgvProveedores.ReadOnly                    = true;
            this.dgvProveedores.RowHeadersVisible           = false;
            this.dgvProveedores.RowTemplate.Height          = 28;
            this.dgvProveedores.SelectionMode               = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvProveedores.TabIndex                    = 0;
            this.dgvProveedores.CellDoubleClick            += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvProveedores_CellDoubleClick);
            this.dgvProveedores.KeyDown                    += new System.Windows.Forms.KeyEventHandler(this.dgvProveedores_KeyDown);

            // ── pnlGrid ───────────────────────────────────────────────
            this.pnlGrid.BackColor = System.Drawing.Color.White;
            this.pnlGrid.Controls.Add(this.dgvProveedores);
            this.pnlGrid.Dock      = System.Windows.Forms.DockStyle.Fill;
            this.pnlGrid.Padding   = new System.Windows.Forms.Padding(12, 6, 12, 6);
            this.pnlGrid.TabIndex  = 2;

            // ── btnSeleccionar ────────────────────────────────────────
            this.btnSeleccionar.Anchor                        = System.Windows.Forms.AnchorStyles.Right;
            this.btnSeleccionar.BackColor                     = System.Drawing.Color.FromArgb(30, 58, 95);
            this.btnSeleccionar.Cursor                        = System.Windows.Forms.Cursors.Hand;
            this.btnSeleccionar.FlatAppearance.BorderSize     = 0;
            this.btnSeleccionar.FlatStyle                     = System.Windows.Forms.FlatStyle.Flat;
            this.btnSeleccionar.Font                          = new System.Drawing.Font("Segoe UI", 8.75F);
            this.btnSeleccionar.ForeColor                     = System.Drawing.Color.White;
            this.btnSeleccionar.Location                      = new System.Drawing.Point(458, 11);
            this.btnSeleccionar.Name                          = "btnSeleccionar";
            this.btnSeleccionar.Size                          = new System.Drawing.Size(100, 28);
            this.btnSeleccionar.TabIndex                      = 0;
            this.btnSeleccionar.Text                          = "Seleccionar";
            this.btnSeleccionar.UseVisualStyleBackColor       = false;
            this.btnSeleccionar.Click                        += new System.EventHandler(this.btnSeleccionar_Click);

            // ── btnCancelar ───────────────────────────────────────────
            this.btnCancelar.Anchor                        = System.Windows.Forms.AnchorStyles.Right;
            this.btnCancelar.BackColor                     = System.Drawing.Color.FromArgb(229, 231, 235);
            this.btnCancelar.Cursor                        = System.Windows.Forms.Cursors.Hand;
            this.btnCancelar.FlatAppearance.BorderSize     = 0;
            this.btnCancelar.FlatStyle                     = System.Windows.Forms.FlatStyle.Flat;
            this.btnCancelar.Font                          = new System.Drawing.Font("Segoe UI", 8.75F);
            this.btnCancelar.ForeColor                     = System.Drawing.Color.FromArgb(55, 65, 81);
            this.btnCancelar.Location                      = new System.Drawing.Point(566, 11);
            this.btnCancelar.Name                          = "btnCancelar";
            this.btnCancelar.Size                          = new System.Drawing.Size(96, 28);
            this.btnCancelar.TabIndex                      = 1;
            this.btnCancelar.Text                          = "Cancelar";
            this.btnCancelar.UseVisualStyleBackColor       = false;
            this.btnCancelar.Click                        += new System.EventHandler(this.btnCancelar_Click);

            // ── pnlFooter ─────────────────────────────────────────────
            this.pnlFooter.BackColor = System.Drawing.Color.FromArgb(249, 250, 251);
            this.pnlFooter.Controls.Add(this.btnSeleccionar);
            this.pnlFooter.Controls.Add(this.btnCancelar);
            this.pnlFooter.Dock      = System.Windows.Forms.DockStyle.Bottom;
            this.pnlFooter.Size      = new System.Drawing.Size(680, 48);
            this.pnlFooter.TabIndex  = 3;

            // ── Form ──────────────────────────────────────────────────
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode       = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor           = System.Drawing.Color.White;
            this.ClientSize          = new System.Drawing.Size(680, 500);
            this.Controls.Add(this.pnlGrid);
            this.Controls.Add(this.pnlFooter);
            this.Controls.Add(this.pnlSearch);
            this.Controls.Add(this.pnlHeader);
            this.Font            = new System.Drawing.Font("Segoe UI", 9F);
            this.KeyPreview      = true;
            this.MinimumSize     = new System.Drawing.Size(580, 420);
            this.Name            = "ProveedorLookupForm";
            this.StartPosition   = System.Windows.Forms.FormStartPosition.CenterParent;
            this.Text            = "Seleccionar Proveedor / Cliente";

            this.pnlHeader.ResumeLayout(false);
            this.pnlSearch.ResumeLayout(false);
            this.pnlSearch.PerformLayout();
            this.pnlGrid.ResumeLayout(false);
            this.pnlFooter.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvProveedores)).EndInit();
            this.ResumeLayout(false);

            // El foco inicial va al buscador
            this.ActiveControl = this.txtBuscar;
        }

        #endregion

        private System.Windows.Forms.Panel                     pnlHeader;
        private System.Windows.Forms.Panel                     pnlAccent;
        private System.Windows.Forms.Label                     lblTitulo;
        private System.Windows.Forms.Panel                     pnlSearch;
        private System.Windows.Forms.Label                     lblBuscar;
        private System.Windows.Forms.TextBox                   txtBuscar;
        private System.Windows.Forms.Label                     lblConteo;
        private System.Windows.Forms.Panel                     pnlGrid;
        private System.Windows.Forms.DataGridView              dgvProveedores;
        private System.Windows.Forms.Panel                     pnlFooter;
        private System.Windows.Forms.Button                    btnSeleccionar;
        private System.Windows.Forms.Button                    btnCancelar;
        private System.Windows.Forms.DataGridViewTextBoxColumn colPNIT;
        private System.Windows.Forms.DataGridViewTextBoxColumn colPNombre;
        private System.Windows.Forms.DataGridViewTextBoxColumn colPTipoCli;
    }
}
