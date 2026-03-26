# CashFlow Manager — INTECPLAST S.A.S.

> **[English version](README.md)**

Sistema híbrido **Visual FoxPro + .NET WinForms + SQL Server** para generación de flujo de caja semanal y administración de datos de soporte.

---

## Visión general

El sistema tiene dos grandes componentes que trabajan sobre la misma base de datos SQL Server (`INTECPL`):

| Componente | Tecnología | Responsabilidad |
|---|---|---|
| **Generador de reportes** | Visual FoxPro 9 + Excel COM | Consulta funciones SQL, dibuja libro Excel con fórmulas (hoja USD y COP) |
| **Pantallas de captura** | .NET 4.8 WinForms (ODBC) | CRUD de proyecciones, categorización de proveedores, consulta de documentos |

La lógica financiera (agregación, conversión de moneda, pivoteo por semana) vive **exclusivamente en SQL Server** mediante Table-Valued Functions + un Stored Procedure genérico de pivoteo. Ningún componente cliente calcula valores financieros; solo consumen datos ya transformados.

---

## Estructura de carpetas

```
CashFlowManager/
├── CashFlowManager/                 ← FoxPro: generador Excel
│   ├── cashflowmanagerdata.prg          Lógica de renderizado
│   └── cashflowmanager.scx/.SCT         Formulario FoxPro
│
├── CashflowManagerUI/               ← .NET WinForms
│   ├── CashflowManagerUI.sln
│   ├── CashflowManagerUI.csproj
│   ├── Program.cs                       Entry point + router de pantallas
│   ├── App.config                       Connection string ODBC
│   ├── Common/
│   │   └── BaseProjectionForm.cs        Clase base abstracta (CRUD + UI)
│   ├── Projection/
│   │   ├── ProjectionForm.cs            Proyecciones manuales por NIT/semana
│   │   ├── ProjectionForm.Designer.cs
│   │   ├── ProveedorLookupForm.cs       Popup de búsqueda de NIT
│   │   └── ProveedorLookupForm.Designer.cs
│   ├── DocumentQuery/
│   │   └── DocumentQueryForm.cs         Consulta de documentos + FechaCobro
│   ├── ProveedorCategory/
│   │   └── ProveedorCategoryForm.cs     Asignación de categoría a proveedores
│   └── Properties/
│       ├── AssemblyInfo.cs
│       ├── Resources.Designer.cs
│       └── Settings.Designer.cs
│
└── SQL/
    ├── CreateTablesDDL.sql              DDL completo (tablas, ALTER, datos iniciales)
    ├── Initialize_MtprocliCategories.sql
    ├── OfimaSchemaHelper.txt            Referencia de tablas Ofima
    └── CashflowData/
        ├── CashflowDataHeader.sql       TVF: saldos bancarios de apertura
        ├── CashflowDataIngresos.sql     TVF: ingresos por categoría/semana
        ├── CashflowDataEgresos.sql      TVF: egresos por categoría/semana
        ├── CashflowDataFlujoEconomico.sql  TVF: flujo de financiamiento
        ├── CashflowDataProjection.sql   TVF: proyecciones manuales
        └── CashflowPivot.sql            SP genérico de pivoteo dinámico
```

---

## Arquitectura general

```
                         ┌─────────────────────────────┐
                         │      SQL Server (INTECPL)    │
                         │                              │
                         │  Tablas Ofima:               │
                         │   TRADE, MTPROCLI, MVBANCOS  │
                         │   ABOCXP, MVTO, MTCAMBIO     │
                         │                              │
                         │  Tablas propias:             │
                         │   CashflowProjection         │
                         │   CashflowCategory           │
                         │   CashflowManagerConfig      │
                         │                              │
                         │  5 TVFs + 1 SP pivoteo       │
                         └──────┬──────────────┬────────┘
                                │              │
                         ODBC   │              │  ODBC
                                │              │
              ┌─────────────────▼──┐    ┌──────▼──────────────────┐
              │   FoxPro (.prg)    │    │  .NET WinForms (.exe)   │
              │                    │    │                          │
              │  Llama CashflowPivot   │  3 pantallas de captura  │
              │  para cada sección │    │  (proyección, documento, │
              │  y dibuja Excel    │    │   categoría proveedor)   │
              │  con fórmulas      │    │                          │
              │  (USD + COP)       │    │  Invocado por FoxPro:    │
              │                    │    │  RUN /N "CashflowManagerUI│
              │                    │    │  .exe" screen=<nombre>   │
              └────────────────────┘    └──────────────────────────┘
```

FoxPro actúa como orquestador: genera los reportes Excel y lanza la aplicación .NET cuando el usuario necesita capturar o consultar datos.

---

## Componente .NET — CashflowManagerUI

### Namespace y ensamblado

- **Namespace**: `CashFlowManager.UI`
- **Assembly**: `CashflowManagerUI.exe`
- **Target**: .NET Framework 4.8

### Router de pantallas (Program.cs)

FoxPro invoca el exe con un argumento `screen=`:

```
CashflowManagerUI.exe screen=proyeccion    → ProjectionForm (default)
CashflowManagerUI.exe screen=documento     → DocumentQueryForm
CashflowManagerUI.exe screen=proveedores   → ProveedorCategoryForm
```

Agregar una pantalla nueva solo requiere crear la clase Form y registrar un `case` en el `switch` de `Program.cs`.

### BaseProjectionForm — Clase base abstracta

Todas las pantallas CRUD heredan de `BaseProjectionForm`, que genera programáticamente:

- **Panel encabezado**: barra azul corporativa (RGB 30,58,95) + título dinámico
- **Barra de herramientas**: botones Nuevo, Guardar, Eliminar, Actualizar + barra de estado
- **DataGridView**: columnas autoajustadas, filas alternadas, binding vía `BindingSource`
- **Panel pie de página**: versión + nombre empresa

Cada subclase implementa estas propiedades/métodos abstractos:

| Miembro abstracto | Tipo | Descripción |
|---|---|---|
| `TituloVentana` | `string` | Título que aparece en el encabezado |
| `ConnStr` | `string` | Connection string (de App.config) |
| `SelectSql` | `string` | Query SELECT para cargar datos |
| `SaveSql` | `string` | Query base para que `OdbcCommandBuilder` genere INSERT/UPDATE/DELETE |
| `ConfigurarColumnas()` | `void` | Configura columnas del grid (readonly, ComboBox, anchos, headers) |
| `ConstruirTablaVacia()` | `DataTable` | Define esquema del DataTable cuando no hay datos |

Los hooks virtuales `OnNuevo()`, `OnGuardar()`, `OnEliminar()`, `ValidarFila()` permiten sobrescribir comportamiento por pantalla sin tocar la base.

### Pantallas

#### ProjectionForm — Proyecciones manuales

Edita la tabla `CashflowProjection`. El grid permite registrar el monto proyectado por **NIT + Año + Semana ISO**. Filtros: año y semana. Incluye popup `ProveedorLookupForm` para buscar NIT con autocompletar.

#### DocumentQueryForm — Consulta de documentos

Busca en `TRADE` por (TIPODCTO, NRODCTO) filtrado por el ORIGEN configurado en `CashflowManagerConfig`. Muestra campos de solo lectura (Proveedor, Total, Nota) y un campo editable **FechaCobro** (fecha de cobro) que se actualiza directamente en TRADE.

#### ProveedorCategoryForm — Categorización de proveedores

Muestra todos los registros de `MTPROCLI` con una columna ComboBox para asignar `CashflowCategoryId` (FK a `CashflowCategory`). Incluye barra de filtro dual: búsqueda por texto (NIT o nombre) + filtro por tipo de categoría (Ingresos/Egresos/Financiamiento). Los botones Nuevo y Eliminar están ocultos; solo permite Guardar y Actualizar.

---

## Capa SQL

### Tablas propias

```sql
CashflowManagerConfig (Config PK, Value)
    -- Configuraciones: ORIGEN, SemanasAtras, SemanasAdelante

CashflowProjection (NIT PK, Year PK, Week PK, TotalProjected)
    -- Proyecciones manuales capturadas desde ProjectionForm

CashflowCategory (Id PK, Category, ParentName, ItemOrder)
    -- 28 categorías: INGRESOS (01-09), EGRESOS (10-21), FINANCIAMIENTO (22-28)

MTPROCLI  + ALTER ADD CashflowCategoryId FK → CashflowCategory
TRADE     + ALTER ADD FechaCobro DATETIME NULL
```

### Tablas Ofima existentes consumidas

| Tabla | Uso |
|---|---|
| `TRADE` | Documentos comerciales (facturas, notas, etc.) |
| `MTPROCLI` | Maestro de proveedores/clientes |
| `MTCAMBIO` | Tasas de cambio (TRM diaria COP/USD) |
| `MVBANCOS` / `MTBANCOS` | Movimientos y maestro bancario |
| `ABOCXP` | Cartera de cuentas por pagar |
| `MVTO` | Movimientos contables (nómina, impuestos) |

### Patrón TVF + Pivoteo dinámico

Cada sección financiera se implementa como una **Table-Valued Function** que retorna filas con la estructura `(Concepto, ItemOrder, Semana, Valor)`:

| TVF | Sección | Fuente principal |
|---|---|---|
| `CashflowDataHeader` | Saldos de apertura bancarios | MVBANCOS + MTCAMBIO |
| `CashflowDataIngresos` | Ingresos por categoría | TRADE + MTPROCLI + CashflowCategory |
| `CashflowDataEgresos` | Egresos por categoría | ABOCXP + MVTO + MTCAMBIO |
| `CashflowDataFlujoEconomico` | Flujo de financiamiento | (stub, valores en 0) |
| `CashflowDataProjection` | Proyecciones manuales | CashflowProjection + CashflowCategory |

El **SP `CashflowPivot`** recibe el nombre de la TVF, rango de fechas, moneda y categoría opcional, y genera dinámicamente un `PIVOT` con una columna por cada semana del rango. Usa un whitelist interno para validar el nombre de función y prevenir inyección SQL.

Agregar un concepto financiero nuevo = agregar un `UNION ALL` en la TVF correspondiente. No se toca FoxPro ni .NET.

---

## Componente FoxPro — Generador Excel

`cashflowmanagerdata.prg` genera un libro Excel con dos hojas (USD y COP). El flujo es:

1. Lee configuración (`SemanasAtras`, `SemanasAdelante`) de `CashflowManagerConfig`
2. Calcula el rango de semanas ISO basado en la fecha proporcionada
3. Crea workbook Excel vía COM (ActiveX)
4. Para cada hoja llama a `CashflowPivot` pasando cada TVF secuencialmente:
   - Header → Ingresos → Subtotal Ingresos → Egresos → Subtotal Egresos → Flujo Económico → Subtotal Financiamiento → Totales
5. Cada sección se dibuja con `DibujarCursor` (datos), `DibujarSubtotal` (fórmulas SUM)
6. Aplica paleta corporativa (azul cabecera, filas alternas, sección de totales en lila)
7. Guarda como `.xlsx`

Las funciones de dibujo usan un patrón de **puntero de fila**: cada una recibe `lnFilaActual` y retorna la siguiente fila disponible. Esto permite insertar o remover secciones sin renumerar nada.

---

## Conexión a base de datos

```xml
<!-- App.config -->
<connectionStrings>
  <add name="CashflowDB"
       connectionString="Driver={ODBC Driver 17 for SQL Server};
                         Server=NICOLASD\SQL2025;
                         Database=INTECPL;
                         Trusted_Connection=Yes;
                         TrustServerCertificate=Yes;" />
</connectionStrings>
```

Toda la aplicación .NET usa `System.Data.Odbc` (`OdbcConnection`, `OdbcDataAdapter`, `OdbcCommandBuilder`). FoxPro también se conecta por ODBC al mismo servidor.

---

## Escalabilidad

El sistema está diseñado para crecer en tres ejes sin reestructuración:

**Nuevas pantallas .NET:**
Crear una clase que herede `BaseProjectionForm`, implementar los miembros abstractos y agregar un `case` en `Program.cs`. La UI completa (encabezado, grid, toolbar, footer) se genera automáticamente.

**Nuevos conceptos financieros:**
Agregar un `UNION ALL` en la TVF correspondiente con el nuevo `Concepto`, `ItemOrder` y lógica de cálculo. El SP de pivoteo y el renderizador FoxPro lo incluyen automáticamente.

**Nuevas categorías de clasificación:**
Insertar filas en `CashflowCategory`. Las pantallas .NET y las TVFs las consumen dinámicamente sin cambios de código.
