using System;
using System.Drawing;
using System.Windows.Forms;
using CashFlowManager.UI.Services;

namespace CashFlowManager.UI
{
    public class GeneradorFlujoCajaForm : Form
    {
        // ── Controles ───────────────────────────────────────────────
        private readonly Panel          _pnlHeader  = new Panel();
        private readonly Panel          _pnlAccent  = new Panel();
        private readonly Label          _lblTitle   = new Label();
        private readonly Label          _lblCompany = new Label();

        private readonly Panel          _pnlBody    = new Panel();

        // Selección de modo
        private readonly RadioButton    _rbFecha    = new RadioButton();
        private readonly RadioButton    _rbSemana   = new RadioButton();

        // Modo por fecha
        private readonly Label          _lblFecha   = new Label();
        private readonly DateTimePicker _dtpFecha   = new DateTimePicker();

        // Modo por semana ISO
        private readonly Label          _lblAno     = new Label();
        private readonly NumericUpDown  _nudAno     = new NumericUpDown();
        private readonly Label          _lblSemana  = new Label();
        private readonly NumericUpDown  _nudSemana  = new NumericUpDown();
        private readonly Label          _lblRango   = new Label();

        // Comunes
        private readonly Button         _btnGenerar = new Button();
        private readonly ProgressBar    _progress   = new ProgressBar();
        private readonly Label          _lblStatus  = new Label();

        private readonly Panel          _pnlFooter  = new Panel();
        private readonly Label          _lblFooter  = new Label();

        public GeneradorFlujoCajaForm()
        {
            BuildUI();

            _rbFecha.CheckedChanged  += (s, e) => ActualizarModo();
            _rbSemana.CheckedChanged += (s, e) => ActualizarModo();
            _nudAno.ValueChanged     += (s, e) => ActualizarRango();
            _nudSemana.ValueChanged  += (s, e) => ActualizarRango();
            _btnGenerar.Click        += BtnGenerar_Click;

            // Modo inicial: semana ISO
            _rbSemana.Checked = true;
            ActualizarRango();
        }

        private void BuildUI()
        {
            SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)_nudAno).BeginInit();
            ((System.ComponentModel.ISupportInitialize)_nudSemana).BeginInit();

            // ── Form ────────────────────────────────────────────────
            Text            = "Generador Flujo de Caja";
            ClientSize      = new Size(520, 370);
            StartPosition   = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox     = false;
            BackColor       = Color.FromArgb(249, 250, 251);
            Font            = new Font("Segoe UI", 9.75F);

            // ── Header ──────────────────────────────────────────────
            _pnlHeader.Dock      = DockStyle.Top;
            _pnlHeader.Height    = 64;
            _pnlHeader.BackColor = Color.White;

            _pnlAccent.BackColor = Color.FromArgb(30, 58, 95);
            _pnlAccent.Dock      = DockStyle.Left;
            _pnlAccent.Width     = 5;

            _lblTitle.Text      = "Generador Flujo de Caja";
            _lblTitle.AutoSize  = false;
            _lblTitle.Dock      = DockStyle.Fill;
            _lblTitle.Font      = new Font("Segoe UI Semibold", 14F);
            _lblTitle.ForeColor = Color.FromArgb(17, 24, 39);
            _lblTitle.Padding   = new Padding(16, 0, 0, 0);
            _lblTitle.TextAlign = ContentAlignment.MiddleLeft;

            _lblCompany.Text      = "INTECPLAST S.A.S.";
            _lblCompany.AutoSize  = false;
            _lblCompany.Dock      = DockStyle.Right;
            _lblCompany.Font      = new Font("Segoe UI", 8.25F);
            _lblCompany.ForeColor = Color.FromArgb(156, 163, 175);
            _lblCompany.Padding   = new Padding(0, 0, 20, 0);
            _lblCompany.Width     = 160;
            _lblCompany.TextAlign = ContentAlignment.MiddleRight;

            _pnlHeader.Controls.Add(_lblTitle);
            _pnlHeader.Controls.Add(_lblCompany);
            _pnlHeader.Controls.Add(_pnlAccent);

            // ── Body ────────────────────────────────────────────────
            _pnlBody.Dock = DockStyle.Fill;

            // Radio buttons de selección de modo
            _rbFecha.Text      = "Por fecha";
            _rbFecha.Location  = new Point(40, 18);
            _rbFecha.AutoSize  = true;
            _rbFecha.ForeColor = Color.FromArgb(55, 65, 81);
            _rbFecha.Font      = new Font("Segoe UI", 9.75F);

            _rbSemana.Text      = "Por semana";
            _rbSemana.Location  = new Point(160, 18);
            _rbSemana.AutoSize  = true;
            _rbSemana.ForeColor = Color.FromArgb(55, 65, 81);
            _rbSemana.Font      = new Font("Segoe UI", 9.75F);

            // ── Sección: Por fecha ──────────────────────────────────
            _lblFecha.Text      = "Fecha de referencia:";
            _lblFecha.Location  = new Point(40, 58);
            _lblFecha.AutoSize  = true;
            _lblFecha.ForeColor = Color.FromArgb(55, 65, 81);

            _dtpFecha.Location  = new Point(180, 54);
            _dtpFecha.Width     = 160;
            _dtpFecha.Format    = DateTimePickerFormat.Short;
            _dtpFecha.Value     = DateTime.Today;
            _dtpFecha.Font      = new Font("Segoe UI", 10F);

            // ── Sección: Por semana ──────────────────────────────────
            _lblAno.Text      = "Año:";
            _lblAno.Location  = new Point(40, 58);
            _lblAno.AutoSize  = true;
            _lblAno.ForeColor = Color.FromArgb(55, 65, 81);

            _nudAno.Location    = new Point(80, 54);
            _nudAno.Width       = 76;
            _nudAno.Minimum     = 2000;
            _nudAno.Maximum     = 2099;
            _nudAno.Value       = DateTime.Today.Year;
            _nudAno.Font        = new Font("Segoe UI", 10F);
            _nudAno.BorderStyle = BorderStyle.FixedSingle;

            _lblSemana.Text      = "Semana:";
            _lblSemana.Location  = new Point(174, 58);
            _lblSemana.AutoSize  = true;
            _lblSemana.ForeColor = Color.FromArgb(55, 65, 81);

            _nudSemana.Location    = new Point(272, 54);
            _nudSemana.Width       = 56;
            _nudSemana.Minimum     = 1;
            _nudSemana.Maximum     = 53;
            _nudSemana.Value       = GetIsoWeek(DateTime.Today);
            _nudSemana.Font        = new Font("Segoe UI", 10F);
            _nudSemana.BorderStyle = BorderStyle.FixedSingle;

            _lblRango.Location  = new Point(40, 92);
            _lblRango.Size      = new Size(420, 22);
            _lblRango.ForeColor = Color.FromArgb(107, 114, 128);
            _lblRango.Font      = new Font("Segoe UI", 8.75F);

            // ── Botón generar ────────────────────────────────────────
            _btnGenerar.Text                      = "Generar Excel";
            _btnGenerar.Location                  = new Point(40, 128);
            _btnGenerar.Size                      = new Size(420, 34);
            _btnGenerar.BackColor                 = Color.FromArgb(30, 58, 95);
            _btnGenerar.ForeColor                 = Color.White;
            _btnGenerar.FlatStyle                 = FlatStyle.Flat;
            _btnGenerar.FlatAppearance.BorderSize = 0;
            _btnGenerar.Cursor                    = Cursors.Hand;
            _btnGenerar.Font                      = new Font("Segoe UI Semibold", 10F);

            // ── Barra de progreso ────────────────────────────────────
            _progress.Location              = new Point(40, 178);
            _progress.Size                  = new Size(420, 20);
            _progress.Style                 = ProgressBarStyle.Marquee;
            _progress.MarqueeAnimationSpeed = 30;
            _progress.Visible               = false;

            // ── Estado ───────────────────────────────────────────────
            _lblStatus.Location  = new Point(40, 206);
            _lblStatus.Size      = new Size(420, 80);
            _lblStatus.ForeColor = Color.FromArgb(75, 85, 99);
            _lblStatus.Text      = "";

            _pnlBody.Controls.AddRange(new Control[]
            {
                _rbFecha, _rbSemana,
                _lblFecha, _dtpFecha,
                _lblAno, _nudAno, _lblSemana, _nudSemana, _lblRango,
                _btnGenerar, _progress, _lblStatus
            });

            // ── Footer ──────────────────────────────────────────────
            _pnlFooter.Dock      = DockStyle.Bottom;
            _pnlFooter.Height    = 32;
            _pnlFooter.BackColor = Color.FromArgb(243, 244, 246);

            _lblFooter.Dock      = DockStyle.Fill;
            _lblFooter.Text      = "CC Sistemas © " + DateTime.Now.Year;
            _lblFooter.Font      = new Font("Segoe UI", 7.5F);
            _lblFooter.ForeColor = Color.FromArgb(156, 163, 175);
            _lblFooter.TextAlign = ContentAlignment.MiddleCenter;
            _pnlFooter.Controls.Add(_lblFooter);

            // ── Ensamblar ───────────────────────────────────────────
            Controls.Add(_pnlBody);
            Controls.Add(_pnlHeader);
            Controls.Add(_pnlFooter);

            ((System.ComponentModel.ISupportInitialize)_nudAno).EndInit();
            ((System.ComponentModel.ISupportInitialize)_nudSemana).EndInit();
            ResumeLayout();
        }

        // ── Muestra/oculta controles según el modo seleccionado ─────

        private void ActualizarModo()
        {
            bool esPorFecha = _rbFecha.Checked;

            _lblFecha.Visible = esPorFecha;
            _dtpFecha.Visible = esPorFecha;

            _lblAno.Visible    = !esPorFecha;
            _nudAno.Visible    = !esPorFecha;
            _lblSemana.Visible = !esPorFecha;
            _nudSemana.Visible = !esPorFecha;
            _lblRango.Visible  = !esPorFecha;
        }

        // ── Actualiza el label de rango cuando cambia año o semana ──

        private void ActualizarRango()
        {
            int year = (int)_nudAno.Value;
            int week = (int)_nudSemana.Value;

            int maxWeeks = IsoWeeksInYear(year);
            if (_nudSemana.Maximum != maxWeeks)
                _nudSemana.Maximum = maxWeeks;
            if (week > maxWeeks)
            {
                _nudSemana.Value = maxWeeks;
                return;
            }

            DateTime lunes   = GetMondayOfWeek(year, week);
            DateTime domingo = lunes.AddDays(6);
            _lblRango.Text = $"Semana {week} — del {lunes:dd/MM/yyyy} al {domingo:dd/MM/yyyy}";
        }

        // ── Generación del Excel ─────────────────────────────────────

        private async void BtnGenerar_Click(object sender, EventArgs e)
        {
            _btnGenerar.Enabled  = false;
            _progress.Visible    = true;
            _lblStatus.ForeColor = Color.FromArgb(75, 85, 99);
            _lblStatus.Text      = "Iniciando...";

            DateTime fecha;
            if (_rbFecha.Checked)
            {
                fecha = _dtpFecha.Value.Date;
            }
            else
            {
                fecha = GetMondayOfWeek((int)_nudAno.Value, (int)_nudSemana.Value);
            }

            try
            {
                string ruta = await System.Threading.Tasks.Task.Run(() =>
                {
                    using (var builder = new ExcelCashFlowBuilder(fecha))
                    {
                        builder.OnProgress += msg =>
                        {
                            if (InvokeRequired)
                                BeginInvoke(new Action(() => _lblStatus.Text = msg));
                            else
                                _lblStatus.Text = msg;
                        };
                        return builder.Generar();
                    }
                });

                _lblStatus.ForeColor = Color.FromArgb(22, 163, 74);
                _lblStatus.Text = $"Generado exitosamente.\n{ruta}";

                MessageBox.Show(
                    $"Flujo de Caja generado exitosamente.\n\n{ruta}",
                    "Flujo de Caja - INTECPLAST",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                _lblStatus.ForeColor = Color.FromArgb(220, 38, 38);
                _lblStatus.Text = $"Error: {ex.Message}";

                MessageBox.Show(
                    $"Error generando Excel:\n\n{ex.Message}\n\n{ex.StackTrace}",
                    "Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
            finally
            {
                _progress.Visible   = false;
                _btnGenerar.Enabled = true;
            }
        }

        // ── Utilidades de semana ISO ─────────────────────────────────

        private static DateTime GetMondayOfWeek(int year, int week)
        {
            var jan4     = new DateTime(year, 1, 4);
            int dow      = ((int)jan4.DayOfWeek + 6) % 7;
            DateTime w1  = jan4.AddDays(-dow);
            return w1.AddDays((week - 1) * 7);
        }

        private static int GetIsoWeek(DateTime date) =>
            System.Globalization.CultureInfo.InvariantCulture.Calendar
                .GetWeekOfYear(date,
                    System.Globalization.CalendarWeekRule.FirstFourDayWeek,
                    DayOfWeek.Monday);

        private static int IsoWeeksInYear(int year)
        {
            var jan1  = new DateTime(year, 1, 1);
            var dec31 = new DateTime(year, 12, 31);
            return (jan1.DayOfWeek == DayOfWeek.Thursday ||
                    dec31.DayOfWeek == DayOfWeek.Thursday) ? 53 : 52;
        }
    }
}
