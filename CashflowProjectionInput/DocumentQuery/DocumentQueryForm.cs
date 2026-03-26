using System;
using System.Configuration;
using System.Data;
using System.Data.Odbc;
using System.Drawing;
using System.Windows.Forms;

namespace CashFlowManager.UI
{
    public class DocumentQueryForm : Form
    {
        // ── Configuración ──────────────────────────────────────────────
        private string ConnStr =>
            ConfigurationManager.ConnectionStrings["CashflowDB"].ConnectionString;

        private string _origen;

        // ── Controles de búsqueda ──────────────────────────────────────
        private TextBox txtTipoDcto;
        private TextBox txtNroDcto;
        private Button  btnBuscar;

        // ── Controles de resultado (readonly) ──────────────────────────
        private TextBox txtProveedor;
        private TextBox txtTotal;
        private TextBox txtNota;

        // ── Campo editable ─────────────────────────────────────────────
        private DateTimePicker dtpFechaCobro;
        private CheckBox       chkFechaCobro;
        private Button         btnActualizar;

        // ── Paneles y labels de estética ───────────────────────────────
        private Panel pnlHeader;
        private Panel pnlFooter;
        private Panel pnlResultado;
        private Label lblStatus;

        public DocumentQueryForm()
        {
            BuildUI();
            Load += (s, e) => CargarOrigen();
        }

        // ── Cargar ORIGEN desde CashflowManagerConfig ──────────────────
        private void CargarOrigen()
        {
            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new OdbcCommand(
                        "SELECT Value FROM dbo.CashflowManagerConfig WHERE Config = ?", conn))
                    {
                        cmd.Parameters.AddWithValue("@Config", "ORIGEN");
                        var result = cmd.ExecuteScalar();
                        if (result == null || result == DBNull.Value)
                        {
                            MessageBox.Show(
                                "No se encontró la configuración 'ORIGEN' en CashflowManagerConfig.\n" +
                                "Agregue un registro con Config='ORIGEN' y el valor correspondiente.",
                                "Configuración faltante",
                                MessageBoxButtons.OK, MessageBoxIcon.Warning);
                            btnBuscar.Enabled = false;
                            return;
                        }
                        _origen = result.ToString().Trim();
                    }
                }
                SetStatus($"Origen configurado: {_origen}");
            }
            catch (Exception ex)
            {
                SetStatus("Error al conectar");
                MessageBox.Show(
                    "Error al leer configuración:\n\n" + ex.Message,
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                btnBuscar.Enabled = false;
            }
        }

        // ── Buscar documento ───────────────────────────────────────────
        private void BuscarDocumento()
        {
            string tipoDcto = txtTipoDcto.Text.Trim();
            string nroDcto  = txtNroDcto.Text.Trim();

            if (string.IsNullOrEmpty(tipoDcto) || string.IsNullOrEmpty(nroDcto))
            {
                MessageBox.Show("Ingrese Tipo Dcto y Nro Dcto.",
                    "Datos requeridos", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            LimpiarResultado();

            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new OdbcCommand(
                        "SELECT NIT, BRUTO, NOTA, FechaCobro " +
                        "FROM dbo.TRADE " +
                        "WHERE ORIGEN = ? AND TIPODCTO = ? AND NRODCTO = ?", conn))
                    {
                        cmd.Parameters.AddWithValue("@ORIGEN",   _origen);
                        cmd.Parameters.AddWithValue("@TIPODCTO", tipoDcto);
                        cmd.Parameters.AddWithValue("@NRODCTO",  nroDcto);

                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                txtProveedor.Text = reader["NIT"]?.ToString()?.Trim() ?? "";

                                if (reader["BRUTO"] != DBNull.Value)
                                    txtTotal.Text = Convert.ToDecimal(reader["BRUTO"]).ToString("N2");

                                txtNota.Text = reader["NOTA"]?.ToString()?.Trim() ?? "";

                                if (reader["FechaCobro"] != DBNull.Value)
                                {
                                    dtpFechaCobro.Value = Convert.ToDateTime(reader["FechaCobro"]);
                                    chkFechaCobro.Checked = true;
                                }
                                else
                                {
                                    chkFechaCobro.Checked = false;
                                }

                                pnlResultado.Visible   = true;
                                btnActualizar.Visible   = true;
                                SetStatus("Documento encontrado");
                            }
                            else
                            {
                                SetStatus("No se encontró documento");
                                MessageBox.Show(
                                    $"No se encontró documento con Origen='{_origen}', " +
                                    $"TipoDcto='{tipoDcto}', NroDcto='{nroDcto}'.",
                                    "Sin resultados", MessageBoxButtons.OK, MessageBoxIcon.Information);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                SetStatus("Error al buscar");
                MessageBox.Show(
                    "Error al buscar documento:\n\n" + ex.Message,
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        // ── Actualizar FechaCobro ──────────────────────────────────────
        private void ActualizarFechaCobro()
        {
            string tipoDcto = txtTipoDcto.Text.Trim();
            string nroDcto  = txtNroDcto.Text.Trim();

            DateTime? fechaCobro = chkFechaCobro.Checked
                ? (DateTime?)dtpFechaCobro.Value.Date
                : null;

            if (!chkFechaCobro.Checked)
            {
                var resp = MessageBox.Show(
                    "No ha marcado una fecha de cobro. ¿Desea limpiar la fecha existente?",
                    "Confirmar", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (resp != DialogResult.Yes) return;
            }

            try
            {
                using (var conn = new OdbcConnection(ConnStr))
                {
                    conn.Open();
                    using (var cmd = new OdbcCommand(
                        "UPDATE dbo.TRADE SET FechaCobro = ? " +
                        "WHERE ORIGEN = ? AND TIPODCTO = ? AND NRODCTO = ?", conn))
                    {
                        if (fechaCobro.HasValue)
                            cmd.Parameters.AddWithValue("@FechaCobro", fechaCobro.Value);
                        else
                            cmd.Parameters.AddWithValue("@FechaCobro", DBNull.Value);

                        cmd.Parameters.AddWithValue("@ORIGEN",   _origen);
                        cmd.Parameters.AddWithValue("@TIPODCTO", tipoDcto);
                        cmd.Parameters.AddWithValue("@NRODCTO",  nroDcto);

                        int rows = cmd.ExecuteNonQuery();
                        if (rows > 0)
                        {
                            SetStatus("Fecha de cobro actualizada correctamente");
                            MessageBox.Show("Fecha de cobro actualizada.",
                                "Éxito", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                        else
                        {
                            SetStatus("No se actualizó ningún registro");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                SetStatus("Error al actualizar");
                MessageBox.Show(
                    "Error al actualizar fecha de cobro:\n\n" + ex.Message,
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        // ── Helpers ────────────────────────────────────────────────────
        private void LimpiarResultado()
        {
            txtProveedor.Text      = "";
            txtTotal.Text          = "";
            txtNota.Text           = "";
            chkFechaCobro.Checked  = false;
            dtpFechaCobro.Value    = DateTime.Today;
            pnlResultado.Visible   = false;
            btnActualizar.Visible  = false;
        }

        private void SetStatus(string msg)
        {
            lblStatus.Text = msg;
            lblStatus.Refresh();
        }

        // ── Construcción de UI ─────────────────────────────────────────
        private void BuildUI()
        {
            SuspendLayout();

            Text           = "Consulta de Documento";
            BackColor      = Color.White;
            Font           = new Font("Segoe UI", 9F);
            ClientSize     = new Size(600, 480);
            MinimumSize    = new Size(520, 450);
            StartPosition  = FormStartPosition.CenterScreen;
            AutoScaleDimensions = new SizeF(6F, 13F);
            AutoScaleMode       = AutoScaleMode.Font;

            // ── Header ─────────────────────────────────────────────────
            var pnlAccent = new Panel
            {
                BackColor = Color.FromArgb(30, 58, 95),
                Dock      = DockStyle.Left,
                Size      = new Size(5, 64)
            };
            var lblTitle = new Label
            {
                AutoSize  = false,
                Dock      = DockStyle.Fill,
                Font      = new Font("Segoe UI Semibold", 14F),
                ForeColor = Color.FromArgb(17, 24, 39),
                Padding   = new Padding(16, 0, 0, 0),
                Text      = "Consulta de Documento",
                TextAlign = ContentAlignment.MiddleLeft
            };
            var lblCompany = new Label
            {
                AutoSize  = false,
                Dock      = DockStyle.Right,
                Font      = new Font("Segoe UI", 8.25F),
                ForeColor = Color.FromArgb(156, 163, 175),
                Padding   = new Padding(0, 0, 20, 0),
                Size      = new Size(200, 64),
                Text      = "INTECPLAST S.A.S.",
                TextAlign = ContentAlignment.MiddleRight
            };
            pnlHeader = new Panel
            {
                BackColor = Color.White,
                Dock      = DockStyle.Top,
                Size      = new Size(600, 64)
            };
            pnlHeader.Controls.Add(lblTitle);
            pnlHeader.Controls.Add(lblCompany);
            pnlHeader.Controls.Add(pnlAccent);

            // ── Panel de búsqueda ──────────────────────────────────────
            var pnlBusqueda = new Panel
            {
                BackColor = Color.FromArgb(240, 244, 248),
                Dock      = DockStyle.Top,
                Size      = new Size(600, 50)
            };

            var lblTipoDcto = new Label
            {
                AutoSize  = true,
                Font      = new Font("Segoe UI", 8.75F),
                ForeColor = Color.FromArgb(107, 114, 128),
                Location  = new Point(16, 16),
                Text      = "Tipo Dcto:"
            };
            txtTipoDcto = new TextBox
            {
                BorderStyle = BorderStyle.FixedSingle,
                Font        = new Font("Segoe UI", 9.5F),
                Location    = new Point(90, 12),
                MaxLength   = 2,
                Size        = new Size(50, 24),
                CharacterCasing = CharacterCasing.Upper
            };

            var lblNroDcto = new Label
            {
                AutoSize  = true,
                Font      = new Font("Segoe UI", 8.75F),
                ForeColor = Color.FromArgb(107, 114, 128),
                Location  = new Point(155, 16),
                Text      = "Nro Dcto:"
            };
            txtNroDcto = new TextBox
            {
                BorderStyle = BorderStyle.FixedSingle,
                Font        = new Font("Segoe UI", 9.5F),
                Location    = new Point(225, 12),
                MaxLength   = 10,
                Size        = new Size(120, 24)
            };

            btnBuscar = new Button
            {
                BackColor                   = Color.FromArgb(30, 58, 95),
                Cursor                      = Cursors.Hand,
                FlatStyle                   = FlatStyle.Flat,
                Font                        = new Font("Segoe UI", 8.75F),
                ForeColor                   = Color.White,
                Location                    = new Point(360, 10),
                Size                        = new Size(96, 30),
                Text                        = "Buscar",
                UseVisualStyleBackColor     = false
            };
            btnBuscar.FlatAppearance.BorderSize = 0;
            btnBuscar.Click += (s, e) => BuscarDocumento();

            // Status label en búsqueda
            lblStatus = new Label
            {
                AutoSize  = false,
                Anchor    = AnchorStyles.Top | AnchorStyles.Right,
                Font      = new Font("Segoe UI", 8.25F),
                ForeColor = Color.FromArgb(107, 114, 128),
                Location  = new Point(460, 0),
                Size      = new Size(130, 50),
                Text      = "Listo",
                TextAlign = ContentAlignment.MiddleRight
            };

            pnlBusqueda.Controls.Add(lblStatus);
            pnlBusqueda.Controls.Add(btnBuscar);
            pnlBusqueda.Controls.Add(txtNroDcto);
            pnlBusqueda.Controls.Add(lblNroDcto);
            pnlBusqueda.Controls.Add(txtTipoDcto);
            pnlBusqueda.Controls.Add(lblTipoDcto);

            // Enter en los textboxes dispara búsqueda
            txtTipoDcto.KeyDown += (s, e) => { if (e.KeyCode == Keys.Enter) { e.SuppressKeyPress = true; txtNroDcto.Focus(); } };
            txtNroDcto.KeyDown  += (s, e) => { if (e.KeyCode == Keys.Enter) { e.SuppressKeyPress = true; BuscarDocumento(); } };

            // ── Panel de resultado ─────────────────────────────────────
            pnlResultado = new Panel
            {
                BackColor = Color.White,
                Dock      = DockStyle.Fill,
                Padding   = new Padding(24, 16, 24, 16),
                Visible   = false
            };

            int y = 12;
            const int labelWidth  = 110;
            const int fieldLeft   = 140;
            const int fieldWidth  = 400;
            const int rowHeight   = 36;

            // Proveedor
            var lblProveedor = CreateFieldLabel("Proveedor:", 16, y);
            txtProveedor = new TextBox
            {
                BorderStyle = BorderStyle.FixedSingle,
                Font        = new Font("Segoe UI", 10F),
                ForeColor   = Color.FromArgb(31, 41, 55),
                Location    = new Point(fieldLeft, y - 2),
                ReadOnly    = true,
                BackColor   = Color.FromArgb(243, 244, 246),
                Size        = new Size(fieldWidth, 26)
            };
            y += rowHeight;

            // Total
            var lblTotal = CreateFieldLabel("Total:", 16, y);
            txtTotal = new TextBox
            {
                BorderStyle = BorderStyle.FixedSingle,
                Font        = new Font("Segoe UI", 10F),
                ForeColor   = Color.FromArgb(31, 41, 55),
                Location    = new Point(fieldLeft, y - 2),
                ReadOnly    = true,
                BackColor   = Color.FromArgb(243, 244, 246),
                Size        = new Size(200, 26),
                TextAlign   = HorizontalAlignment.Right
            };
            y += rowHeight;

            // Nota
            var lblNota = CreateFieldLabel("Nota:", 16, y);
            txtNota = new TextBox
            {
                BorderStyle = BorderStyle.FixedSingle,
                Font        = new Font("Segoe UI", 10F),
                ForeColor   = Color.FromArgb(31, 41, 55),
                Location    = new Point(fieldLeft, y - 2),
                ReadOnly    = true,
                BackColor   = Color.FromArgb(243, 244, 246),
                Size        = new Size(fieldWidth, 60),
                Multiline   = true
            };
            y += 72;

            // Separador
            var separator = new Panel
            {
                BackColor = Color.FromArgb(229, 231, 235),
                Location  = new Point(16, y),
                Size      = new Size(540, 1)
            };
            y += 16;

            // Fecha de cobro
            var lblFechaCobro = CreateFieldLabel("Fecha de cobro:", 16, y);
            chkFechaCobro = new CheckBox
            {
                AutoSize = false,
                Location = new Point(fieldLeft, y + 2),
                Size     = new Size(18, 18),
                Checked  = false
            };
            chkFechaCobro.CheckedChanged += (s, e) =>
            {
                dtpFechaCobro.Enabled = chkFechaCobro.Checked;
            };

            dtpFechaCobro = new DateTimePicker
            {
                Font        = new Font("Segoe UI", 10F),
                Format      = DateTimePickerFormat.Short,
                Location    = new Point(fieldLeft + 24, y - 2),
                Size        = new Size(170, 26),
                Value       = DateTime.Today,
                Enabled     = false
            };
            y += rowHeight + 8;

            // Botón Actualizar
            btnActualizar = new Button
            {
                BackColor                   = Color.FromArgb(4, 120, 87),
                Cursor                      = Cursors.Hand,
                FlatStyle                   = FlatStyle.Flat,
                Font                        = new Font("Segoe UI", 9F, FontStyle.Bold),
                ForeColor                   = Color.White,
                Location                    = new Point(fieldLeft, y),
                Size                        = new Size(160, 34),
                Text                        = "Actualizar Fecha",
                UseVisualStyleBackColor     = false,
                Visible                     = false
            };
            btnActualizar.FlatAppearance.BorderSize = 0;
            btnActualizar.Click += (s, e) => ActualizarFechaCobro();

            pnlResultado.Controls.Add(lblProveedor);
            pnlResultado.Controls.Add(txtProveedor);
            pnlResultado.Controls.Add(lblTotal);
            pnlResultado.Controls.Add(txtTotal);
            pnlResultado.Controls.Add(lblNota);
            pnlResultado.Controls.Add(txtNota);
            pnlResultado.Controls.Add(separator);
            pnlResultado.Controls.Add(lblFechaCobro);
            pnlResultado.Controls.Add(chkFechaCobro);
            pnlResultado.Controls.Add(dtpFechaCobro);
            pnlResultado.Controls.Add(btnActualizar);

            // ── Footer ─────────────────────────────────────────────────
            var lblFooter = new Label
            {
                AutoSize  = false,
                Dock      = DockStyle.Fill,
                Font      = new Font("Segoe UI", 8F),
                ForeColor = Color.FromArgb(156, 163, 175),
                Text      = "CashFlow Manager  \u2022  INTECPLAST S.A.S.  \u2022  v1.0",
                TextAlign = ContentAlignment.MiddleCenter
            };
            pnlFooter = new Panel
            {
                BackColor = Color.FromArgb(249, 250, 251),
                Dock      = DockStyle.Bottom,
                Size      = new Size(600, 28)
            };
            pnlFooter.Controls.Add(lblFooter);

            // ── Agregar paneles al form ────────────────────────────────
            Controls.Add(pnlResultado);
            Controls.Add(pnlFooter);
            Controls.Add(pnlBusqueda);
            Controls.Add(pnlHeader);

            ResumeLayout(false);
        }

        private static Label CreateFieldLabel(string text, int x, int y)
        {
            return new Label
            {
                AutoSize  = true,
                Font      = new Font("Segoe UI Semibold", 9.5F),
                ForeColor = Color.FromArgb(55, 65, 81),
                Location  = new Point(x, y),
                Text      = text
            };
        }
    }
}
