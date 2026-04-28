using System;
using System.Drawing;
using System.Windows.Forms;

namespace CashFlowManager.UI
{
    /// <summary>
    /// Shell principal de CashFlow Manager.
    /// Unifica todas las pantallas en un TabControl con estética corporativa.
    ///
    /// Orden de tabs (requisito de negocio):
    ///   1. Flujo de Caja   — generación del Excel semanal
    ///   2. Proyección       — proyecciones manuales por NIT/semana
    ///   3. Proveedores      — asignación de categoría cashflow por proveedor
    ///   4. Bancos           — clasificación COP/USD de cuentas bancarias
    ///   5. Documentos       — consulta y ajuste de fecha cobro por documento
    ///   6. Configuración    — parámetros del sistema (CashflowManagerConfig)
    /// </summary>
    public class MainShellForm : Form
    {
        // ── Paleta corporativa ────────────────────────────────────────
        private static readonly Color NavyDark    = Color.FromArgb(30, 58, 95);
        private static readonly Color AccentBlue  = Color.FromArgb(30, 58, 95);
        private static readonly Color TabSelected  = Color.White;
        private static readonly Color TabNormal   = Color.FromArgb(241, 245, 249);
        private static readonly Color TabTextSel  = Color.FromArgb(30, 58, 95);
        private static readonly Color TabTextNorm = Color.FromArgb(100, 116, 139);
        private static readonly Color PageBg      = Color.FromArgb(249, 250, 251);

        // ── Controles ─────────────────────────────────────────────────
        private readonly Panel      _pnlTopBar   = new Panel();
        private readonly Label      _lblAppTitle = new Label();
        private readonly Label      _lblCompany  = new Label();
        private readonly TabControl _tabs        = new TabControl();

        // ── Definición de pestañas en orden corporativo ───────────────
        //    Func<Form> factory: lazy — el form se instancia al abrir la pestaña por primera vez.
        private static readonly (string Label, Func<Form> Factory)[] Pages =
        {
            ("Flujo de Caja",  () => new GeneradorFlujoCajaForm()),
            ("Proyección",     () => new ProjectionForm()),
            ("Proveedores",    () => new ProveedorCategoryForm()),
            ("Bancos",         () => new BancosClassificationForm()),
            ("Documentos",     () => new DocumentQueryForm()),
            ("Configuración",  () => new CashflowConfigForm()),
        };

        // ── Constructor ───────────────────────────────────────────────
        public MainShellForm()
        {
            BuildUI();
            InitializeTabs();
        }

        // ═════════════════════════════════════════════════════════════
        //  CONSTRUCCIÓN DE UI
        // ═════════════════════════════════════════════════════════════

        private void BuildUI()
        {
            SuspendLayout();

            Text          = "Flujo de Caja - Intecplast";
            ClientSize    = new Size(1100, 680);
            MinimumSize   = new Size(860, 560);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor     = PageBg;
            Font          = new Font("Segoe UI", 9.75F);

            // ── Barra superior de aplicación ─────────────────────────
            _pnlTopBar.Dock      = DockStyle.Top;
            _pnlTopBar.Height    = 52;
            _pnlTopBar.BackColor = NavyDark;
            _pnlTopBar.Padding   = new Padding(20, 0, 20, 0);

            _lblAppTitle.Dock      = DockStyle.Fill;
            _lblAppTitle.Text      = "Flujo de Caja";
            _lblAppTitle.Font      = new Font("Segoe UI Semibold", 15F);
            _lblAppTitle.ForeColor = Color.White;
            _lblAppTitle.TextAlign = ContentAlignment.MiddleLeft;

            _lblCompany.Dock      = DockStyle.Right;
            _lblCompany.Width     = 220;
            _lblCompany.Text      = "INTECPLAST S.A.S.";
            _lblCompany.Font      = new Font("Segoe UI", 8.5F);
            _lblCompany.ForeColor = Color.FromArgb(148, 163, 184);
            _lblCompany.TextAlign = ContentAlignment.MiddleRight;

            _pnlTopBar.Controls.Add(_lblAppTitle);
            _pnlTopBar.Controls.Add(_lblCompany);

            // ── TabControl con dibujo personalizado ──────────────────
            _tabs.Dock      = DockStyle.Fill;
            _tabs.DrawMode  = TabDrawMode.OwnerDrawFixed;
            _tabs.SizeMode  = TabSizeMode.Fixed;
            _tabs.ItemSize  = new Size(138, 38);
            _tabs.Font      = new Font("Segoe UI Semibold", 9.5F);
            _tabs.Padding   = new Point(8, 6);
            _tabs.DrawItem += Tabs_DrawItem;
            _tabs.SelectedIndexChanged += Tabs_SelectedIndexChanged;

            Controls.Add(_tabs);
            Controls.Add(_pnlTopBar);

            ResumeLayout();
        }

        // ═════════════════════════════════════════════════════════════
        //  GESTIÓN DE TABS (lazy loading)
        // ═════════════════════════════════════════════════════════════

        private void InitializeTabs()
        {
            foreach (var (label, factory) in Pages)
            {
                var page = new TabPage(label)
                {
                    BackColor = PageBg,
                    Padding   = new Padding(0),
                };
                page.Tag = factory;
                _tabs.TabPages.Add(page);
            }

            // Cargar el primer tab inmediatamente
            if (_tabs.TabPages.Count > 0)
                EnsureTabLoaded(_tabs.TabPages[0]);
        }

        /// <summary>
        /// Instancia e incrusta el formulario en la pestaña la primera vez que se abre.
        /// Patrón: TopLevel=false + FormBorderStyle=None + Dock=Fill.
        /// </summary>
        private void EnsureTabLoaded(TabPage page)
        {
            if (page.Controls.Count > 0) return;
            if (!(page.Tag is Func<Form> factory)) return;

            var form = factory();
            form.TopLevel        = false;
            form.FormBorderStyle = FormBorderStyle.None;
            form.Dock            = DockStyle.Fill;
            page.Controls.Add(form);
            form.Show();
        }

        private void Tabs_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (_tabs.SelectedTab != null)
                EnsureTabLoaded(_tabs.SelectedTab);
        }

        // ═════════════════════════════════════════════════════════════
        //  DIBUJO PERSONALIZADO DE PESTAÑAS
        // ═════════════════════════════════════════════════════════════

        private void Tabs_DrawItem(object sender, DrawItemEventArgs e)
        {
            var tab      = (TabControl)sender;
            var page     = tab.TabPages[e.Index];
            bool selected = e.Index == tab.SelectedIndex;

            // Fondo de la pestaña
            using (var bgBrush = new SolidBrush(selected ? TabSelected : TabNormal))
                e.Graphics.FillRectangle(bgBrush, e.Bounds);

            // Separador vertical entre pestañas no seleccionadas
            if (!selected)
            {
                using (var sepPen = new Pen(Color.FromArgb(210, 218, 230)))
                    e.Graphics.DrawLine(sepPen,
                        e.Bounds.Right - 1, e.Bounds.Top + 5,
                        e.Bounds.Right - 1, e.Bounds.Bottom - 5);
            }

            // Línea de acento navy en la parte inferior de la pestaña activa
            if (selected)
            {
                using (var accentBrush = new SolidBrush(AccentBlue))
                    e.Graphics.FillRectangle(accentBrush,
                        e.Bounds.X, e.Bounds.Bottom - 3, e.Bounds.Width, 3);
            }

            // Texto de la pestaña
            using (var sf = new StringFormat
            {
                Alignment     = StringAlignment.Center,
                LineAlignment = StringAlignment.Center,
                Trimming      = StringTrimming.EllipsisCharacter,
            })
            using (var fgBrush = new SolidBrush(selected ? TabTextSel : TabTextNorm))
            {
                var textBounds = e.Bounds;
                if (selected) textBounds.Height -= 3; // dejar espacio al acento
                e.Graphics.DrawString(page.Text, tab.Font, fgBrush, textBounds, sf);
            }
        }
    }
}
