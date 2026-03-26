using System;
using System.Windows.Forms;

namespace CashflowProjectionInput
{
    internal static class Program
    {
        /// <summary>
        /// Punto de entrada. FoxPro puede pasar screen=nombre para abrir
        /// una pantalla específica:
        ///   RUN /N "CashflowProjectionInput.exe" screen=proyeccion
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string screen = "proyeccion";
            foreach (var arg in args)
                if (arg.StartsWith("screen=", StringComparison.OrdinalIgnoreCase))
                    screen = arg.Substring(7).Trim().ToLower();

            Form form;
            switch (screen)
            {
                // Nuevas pantallas se registran aquí:
                // case "egresos":  form = new EgresosForm();  break;
                // case "ingresos": form = new IngresosForm(); break;
                // case "flujo":    form = new FlujoForm();    break;
                default: form = new Form1(); break;
            }

            Application.Run(form);
        }
    }
}
