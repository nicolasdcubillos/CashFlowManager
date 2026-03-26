using System;
using System.Windows.Forms;

namespace CashflowDataGenerator
{
    internal static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            Application.ThreadException += (s, e) =>
                MessageBox.Show(e.Exception.ToString(), "Error no controlado",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);

            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
                MessageBox.Show(e.ExceptionObject.ToString(), "Error fatal",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);

            try
            {
                Application.Run(new MainForm());
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error de inicio",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
