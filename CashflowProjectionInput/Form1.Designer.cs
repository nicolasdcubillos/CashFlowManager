namespace CashflowProjectionInput
{
    partial class Form1
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
            this.pnlHeader     = new System.Windows.Forms.Panel();
            this.pnlAccent     = new System.Windows.Forms.Panel();
            this.lblTitle      = new System.Windows.Forms.Label();
            this.lblCompany    = new System.Windows.Forms.Label();
            this.pnlToolbar    = new System.Windows.Forms.Panel();
            this.btnCargar     = new System.Windows.Forms.Button();
            this.btnNuevo      = new System.Windows.Forms.Button();
            this.btnGuardar    = new System.Windows.Forms.Button();
            this.btnEliminar   = new System.Windows.Forms.Button();
            this.lblStatus     = new System.Windows.Forms.Label();
            this.pnlGrid       = new System.Windows.Forms.Panel();
            this.dgvProjection = new System.Windows.Forms.DataGridView();
            this.pnlFooter     = new System.Windows.Forms.Panel();
            this.lblFooter     = new System.Windows.Forms.Label();
            this.colNIT        = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.colAnio       = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.colSemana     = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.colTotal      = new System.Windows.Forms.DataGridViewTextBoxColumn();

            this.pnlHeader.SuspendLayout();
            this.pnlToolbar.SuspendLayout();
            this.pnlGrid.SuspendLayout();
            this.pnlFooter.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvProjection)).BeginInit();
            this.SuspendLayout();

            // ── pnlAccent (franja izquierda de color) ────────────────────
            this.pnlAccent.BackColor = System.Drawing.Color.FromArgb(59, 108, 164);
            this.pnlAccent.Dock      = System.Windows.Forms.DockStyle.Left;
            this.pnlAccent.Size      = new System.Drawing.Size(10, 80);
            this.pnlAccent.TabIndex  = 0;

            // ── lblCompany ───────────────────────────────────────────────
            this.lblCompany.AutoSize  = false;
            this.lblCompany.Dock      = System.Windows.Forms.DockStyle.Right;
            this.lblCompany.Font      = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Italic);
            this.lblCompany.ForeColor = System.Drawing.Color.FromArgb(59, 108, 164);
            this.lblCompany.Padding   = new System.Windows.Forms.Padding(0, 0, 20, 0);
            this.lblCompany.Size      = new System.Drawing.Size(200, 80);
            this.lblCompany.TabIndex  = 2;
            this.lblCompany.Text      = "INTECPLAST S.A.S.";
            this.lblCompany.TextAlign = System.Drawing.ContentAlignment.MiddleRight;

            // ── lblTitle ─────────────────────────────────────────────────
            this.lblTitle.AutoSize  = false;
            this.lblTitle.Dock      = System.Windows.Forms.DockStyle.Fill;
            this.lblTitle.Font      = new System.Drawing.Font("Segoe UI", 18F, System.Drawing.FontStyle.Bold);
            this.lblTitle.ForeColor = System.Drawing.Color.FromArgb(22, 54, 92);
            this.lblTitle.Padding   = new System.Windows.Forms.Padding(16, 0, 0, 0);
            this.lblTitle.TabIndex  = 1;
            this.lblTitle.Text      = "Flujo de Caja \u2014 Proyectado";
            this.lblTitle.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;

            // ── pnlHeader ────────────────────────────────────────────────
            this.pnlHeader.BackColor = System.Drawing.Color.FromArgb(183, 211, 234);
            this.pnlHeader.Controls.Add(this.lblTitle);
            this.pnlHeader.Controls.Add(this.lblCompany);
            this.pnlHeader.Controls.Add(this.pnlAccent);
            this.pnlHeader.Dock      = System.Windows.Forms.DockStyle.Top;
            this.pnlHeader.Size      = new System.Drawing.Size(900, 80);
            this.pnlHeader.TabIndex  = 0;

            // ── btnCargar ────────────────────────────────────────────────
            this.btnCargar.BackColor                 = System.Drawing.Color.FromArgb(74, 125, 182);
            this.btnCargar.Cursor                    = System.Windows.Forms.Cursors.Hand;
            this.btnCargar.FlatAppearance.BorderSize = 0;
            this.btnCargar.FlatStyle                 = System.Windows.Forms.FlatStyle.Flat;
            this.btnCargar.Font                      = new System.Drawing.Font("Segoe UI", 9.5F);
            this.btnCargar.ForeColor                 = System.Drawing.Color.White;
            this.btnCargar.Location                  = new System.Drawing.Point(12, 8);
            this.btnCargar.Name                      = "btnCargar";
            this.btnCargar.Size                      = new System.Drawing.Size(110, 34);
            this.btnCargar.TabIndex                  = 0;
            this.btnCargar.Text                      = "\u21BB  Cargar";
            this.btnCargar.UseVisualStyleBackColor   = false;
            this.btnCargar.Click                    += new System.EventHandler(this.btnCargar_Click);

            // ── btnNuevo ─────────────────────────────────────────────────
            this.btnNuevo.BackColor                 = System.Drawing.Color.FromArgb(74, 125, 182);
            this.btnNuevo.Cursor                    = System.Windows.Forms.Cursors.Hand;
            this.btnNuevo.FlatAppearance.BorderSize = 0;
            this.btnNuevo.FlatStyle                 = System.Windows.Forms.FlatStyle.Flat;
            this.btnNuevo.Font                      = new System.Drawing.Font("Segoe UI", 9.5F);
            this.btnNuevo.ForeColor                 = System.Drawing.Color.White;
            this.btnNuevo.Location                  = new System.Drawing.Point(130, 8);
            this.btnNuevo.Name                      = "btnNuevo";
            this.btnNuevo.Size                      = new System.Drawing.Size(100, 34);
            this.btnNuevo.TabIndex                  = 1;
            this.btnNuevo.Text                      = "+  Nuevo";
            this.btnNuevo.UseVisualStyleBackColor   = false;
            this.btnNuevo.Click                    += new System.EventHandler(this.btnNuevo_Click);

            // ── btnGuardar ───────────────────────────────────────────────
            this.btnGuardar.BackColor                 = System.Drawing.Color.FromArgb(52, 101, 153);
            this.btnGuardar.Cursor                    = System.Windows.Forms.Cursors.Hand;
            this.btnGuardar.FlatAppearance.BorderSize = 0;
            this.btnGuardar.FlatStyle                 = System.Windows.Forms.FlatStyle.Flat;
            this.btnGuardar.Font                      = new System.Drawing.Font("Segoe UI", 9.5F);
            this.btnGuardar.ForeColor                 = System.Drawing.Color.White;
            this.btnGuardar.Location                  = new System.Drawing.Point(238, 8);
            this.btnGuardar.Name                      = "btnGuardar";
            this.btnGuardar.Size                      = new System.Drawing.Size(110, 34);
            this.btnGuardar.TabIndex                  = 2;
            this.btnGuardar.Text                      = "\u2714  Guardar";
            this.btnGuardar.UseVisualStyleBackColor   = false;
            this.btnGuardar.Click                    += new System.EventHandler(this.btnGuardar_Click);

            // ── btnEliminar ──────────────────────────────────────────────
            this.btnEliminar.BackColor                 = System.Drawing.Color.FromArgb(180, 70, 70);
            this.btnEliminar.Cursor                    = System.Windows.Forms.Cursors.Hand;
            this.btnEliminar.FlatAppearance.BorderSize = 0;
            this.btnEliminar.FlatStyle                 = System.Windows.Forms.FlatStyle.Flat;
            this.btnEliminar.Font                      = new System.Drawing.Font("Segoe UI", 9.5F);
            this.btnEliminar.ForeColor                 = System.Drawing.Color.White;
            this.btnEliminar.Location                  = new System.Drawing.Point(356, 8);
            this.btnEliminar.Name                      = "btnEliminar";
            this.btnEliminar.Size                      = new System.Drawing.Size(110, 34);
            this.btnEliminar.TabIndex                  = 3;
            this.btnEliminar.Text                      = "\u2715  Eliminar";
            this.btnEliminar.UseVisualStyleBackColor   = false;
            this.btnEliminar.Click                    += new System.EventHandler(this.btnEliminar_Click);

            // ── lblStatus ────────────────────────────────────────────────
            this.lblStatus.AutoSize  = false;
            this.lblStatus.Dock      = System.Windows.Forms.DockStyle.Right;
            this.lblStatus.Font      = new System.Drawing.Font("Segoe UI", 8.5F, System.Drawing.FontStyle.Italic);
            this.lblStatus.ForeColor = System.Drawing.Color.FromArgb(52, 101, 153);
            this.lblStatus.Padding   = new System.Windows.Forms.Padding(0, 0, 16, 0);
            this.lblStatus.Size      = new System.Drawing.Size(340, 50);
            this.lblStatus.TabIndex  = 4;
            this.lblStatus.Text      = "Listo";
            this.lblStatus.TextAlign = System.Drawing.ContentAlignment.MiddleRight;

            // ── pnlToolbar ───────────────────────────────────────────────
            this.pnlToolbar.BackColor = System.Drawing.Color.FromArgb(214, 233, 247);
            this.pnlToolbar.Controls.Add(this.lblStatus);
            this.pnlToolbar.Controls.Add(this.btnEliminar);
            this.pnlToolbar.Controls.Add(this.btnGuardar);
            this.pnlToolbar.Controls.Add(this.btnNuevo);
            this.pnlToolbar.Controls.Add(this.btnCargar);
            this.pnlToolbar.Dock      = System.Windows.Forms.DockStyle.Top;
            this.pnlToolbar.Size      = new System.Drawing.Size(900, 50);
            this.pnlToolbar.TabIndex  = 1;

            // ── Estilos del DataGridView ──────────────────────────────────
            var headerStyle = new System.Windows.Forms.DataGridViewCellStyle();
            headerStyle.Alignment  = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            headerStyle.BackColor  = System.Drawing.Color.FromArgb(143, 185, 222);
            headerStyle.Font       = new System.Drawing.Font("Segoe UI", 9.5F, System.Drawing.FontStyle.Bold);
            headerStyle.ForeColor  = System.Drawing.Color.FromArgb(22, 54, 92);
            headerStyle.Padding    = new System.Windows.Forms.Padding(2);

            var cellStyle = new System.Windows.Forms.DataGridViewCellStyle();
            cellStyle.BackColor          = System.Drawing.Color.White;
            cellStyle.Font               = new System.Drawing.Font("Segoe UI", 9.25F);
            cellStyle.ForeColor          = System.Drawing.Color.FromArgb(35, 40, 55);
            cellStyle.SelectionBackColor = System.Drawing.Color.FromArgb(74, 125, 182);
            cellStyle.SelectionForeColor = System.Drawing.Color.White;

            var altRowStyle = new System.Windows.Forms.DataGridViewCellStyle();
            altRowStyle.BackColor          = System.Drawing.Color.FromArgb(232, 244, 253);
            altRowStyle.SelectionBackColor = System.Drawing.Color.FromArgb(74, 125, 182);
            altRowStyle.SelectionForeColor = System.Drawing.Color.White;

            // ── Columnas ──────────────────────────────────────────────────
            // colNIT
            this.colNIT.DataPropertyName = "NIT";
            this.colNIT.FillWeight       = 130F;
            this.colNIT.HeaderText       = "NIT";
            this.colNIT.MaxInputLength   = 20;
            this.colNIT.MinimumWidth     = 120;
            this.colNIT.Name             = "colNIT";

            // colAnio
            var centerStyle = new System.Windows.Forms.DataGridViewCellStyle();
            centerStyle.Alignment          = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            centerStyle.SelectionBackColor = System.Drawing.Color.FromArgb(74, 125, 182);
            centerStyle.SelectionForeColor = System.Drawing.Color.White;
            this.colAnio.DataPropertyName  = "Year";
            this.colAnio.DefaultCellStyle  = centerStyle;
            this.colAnio.FillWeight        = 60F;
            this.colAnio.HeaderText        = "A\u00f1o";
            this.colAnio.MaxInputLength    = 4;
            this.colAnio.MinimumWidth      = 70;
            this.colAnio.Name              = "colAnio";

            // colSemana
            var centerStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            centerStyle2.Alignment          = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            centerStyle2.SelectionBackColor = System.Drawing.Color.FromArgb(74, 125, 182);
            centerStyle2.SelectionForeColor = System.Drawing.Color.White;
            this.colSemana.DataPropertyName = "Week";
            this.colSemana.DefaultCellStyle = centerStyle2;
            this.colSemana.FillWeight       = 60F;
            this.colSemana.HeaderText       = "Semana";
            this.colSemana.MaxInputLength   = 2;
            this.colSemana.MinimumWidth     = 70;
            this.colSemana.Name             = "colSemana";

            // colTotal
            var rightStyle = new System.Windows.Forms.DataGridViewCellStyle();
            rightStyle.Alignment          = System.Windows.Forms.DataGridViewContentAlignment.MiddleRight;
            rightStyle.Format             = "N2";
            rightStyle.SelectionBackColor = System.Drawing.Color.FromArgb(74, 125, 182);
            rightStyle.SelectionForeColor = System.Drawing.Color.White;
            this.colTotal.DataPropertyName = "TotalProjected";
            this.colTotal.DefaultCellStyle = rightStyle;
            this.colTotal.FillWeight       = 130F;
            this.colTotal.HeaderText       = "Total Proyectado";
            this.colTotal.MinimumWidth     = 130;
            this.colTotal.Name             = "colTotal";

            // ── dgvProjection ──────────────────────────────────────────────
            this.dgvProjection.AllowUserToAddRows              = false;
            this.dgvProjection.AllowUserToDeleteRows           = false;
            this.dgvProjection.AlternatingRowsDefaultCellStyle = altRowStyle;
            this.dgvProjection.AutoGenerateColumns             = false;
            this.dgvProjection.AutoSizeColumnsMode             = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill;
            this.dgvProjection.BackgroundColor                 = System.Drawing.Color.FromArgb(240, 247, 253);
            this.dgvProjection.BorderStyle                     = System.Windows.Forms.BorderStyle.None;
            this.dgvProjection.CellBorderStyle                 = System.Windows.Forms.DataGridViewCellBorderStyle.SingleHorizontal;
            this.dgvProjection.ColumnHeadersBorderStyle        = System.Windows.Forms.DataGridViewHeaderBorderStyle.None;
            this.dgvProjection.ColumnHeadersDefaultCellStyle   = headerStyle;
            this.dgvProjection.ColumnHeadersHeight             = 38;
            this.dgvProjection.ColumnHeadersHeightSizeMode     = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            this.dgvProjection.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
                this.colNIT, this.colAnio, this.colSemana, this.colTotal });
            this.dgvProjection.DefaultCellStyle                = cellStyle;
            this.dgvProjection.Dock                            = System.Windows.Forms.DockStyle.Fill;
            this.dgvProjection.EnableHeadersVisualStyles       = false;
            this.dgvProjection.GridColor                       = System.Drawing.Color.FromArgb(183, 211, 234);
            this.dgvProjection.MultiSelect                     = false;
            this.dgvProjection.Name                            = "dgvProjection";
            this.dgvProjection.RowHeadersVisible               = false;
            this.dgvProjection.RowTemplate.Height              = 32;
            this.dgvProjection.SelectionMode                   = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvProjection.TabIndex                        = 0;

            // ── pnlGrid ────────────────────────────────────────────────────
            this.pnlGrid.BackColor = System.Drawing.Color.FromArgb(240, 247, 253);
            this.pnlGrid.Controls.Add(this.dgvProjection);
            this.pnlGrid.Dock      = System.Windows.Forms.DockStyle.Fill;
            this.pnlGrid.Padding   = new System.Windows.Forms.Padding(12, 8, 12, 8);
            this.pnlGrid.TabIndex  = 2;

            // ── lblFooter ──────────────────────────────────────────────────
            this.lblFooter.AutoSize  = false;
            this.lblFooter.Dock      = System.Windows.Forms.DockStyle.Fill;
            this.lblFooter.Font      = new System.Drawing.Font("Segoe UI", 8F);
            this.lblFooter.ForeColor = System.Drawing.Color.FromArgb(74, 125, 182);
            this.lblFooter.TabIndex  = 0;
            this.lblFooter.Text      = "CashFlow Manager  \u2022  INTECPLAST S.A.S.  \u2022  v1.0";
            this.lblFooter.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;

            // ── pnlFooter ──────────────────────────────────────────────────
            this.pnlFooter.BackColor = System.Drawing.Color.FromArgb(214, 233, 247);
            this.pnlFooter.Controls.Add(this.lblFooter);
            this.pnlFooter.Dock      = System.Windows.Forms.DockStyle.Bottom;
            this.pnlFooter.Size      = new System.Drawing.Size(900, 28);
            this.pnlFooter.TabIndex  = 3;

            // ── Form1 ──────────────────────────────────────────────────────
            // IMPORTANTE: el orden de Controls.Add determina el docking.
            // Fill primero, luego Bottom, luego Top en orden inverso al visual.
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode       = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor           = System.Drawing.Color.FromArgb(240, 247, 253);
            this.ClientSize          = new System.Drawing.Size(900, 560);
            this.Controls.Add(this.pnlGrid);
            this.Controls.Add(this.pnlFooter);
            this.Controls.Add(this.pnlToolbar);
            this.Controls.Add(this.pnlHeader);
            this.Font            = new System.Drawing.Font("Segoe UI", 9F);
            this.MinimumSize     = new System.Drawing.Size(700, 480);
            this.Name            = "Form1";
            this.StartPosition   = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text            = "Flujo de Caja \u2014 Proyectado";

            this.pnlHeader.ResumeLayout(false);
            this.pnlToolbar.ResumeLayout(false);
            this.pnlGrid.ResumeLayout(false);
            this.pnlFooter.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvProjection)).EndInit();
            this.ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.Panel                       pnlHeader;
        private System.Windows.Forms.Panel                       pnlAccent;
        private System.Windows.Forms.Label                       lblTitle;
        private System.Windows.Forms.Label                       lblCompany;
        private System.Windows.Forms.Panel                       pnlToolbar;
        private System.Windows.Forms.Button                      btnCargar;
        private System.Windows.Forms.Button                      btnNuevo;
        private System.Windows.Forms.Button                      btnGuardar;
        private System.Windows.Forms.Button                      btnEliminar;
        private System.Windows.Forms.Label                       lblStatus;
        private System.Windows.Forms.Panel                       pnlGrid;
        private System.Windows.Forms.DataGridView                dgvProjection;
        private System.Windows.Forms.Panel                       pnlFooter;
        private System.Windows.Forms.Label                       lblFooter;
        private System.Windows.Forms.DataGridViewTextBoxColumn   colNIT;
        private System.Windows.Forms.DataGridViewTextBoxColumn   colAnio;
        private System.Windows.Forms.DataGridViewTextBoxColumn   colSemana;
        private System.Windows.Forms.DataGridViewTextBoxColumn   colTotal;
    }
}

