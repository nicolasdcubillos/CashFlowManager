# CashFlow Manager — INTECPLAST S.A.S.

> **[Versión en español](README.es.md)**

Hybrid **Visual FoxPro + .NET WinForms + SQL Server** system for weekly cash flow generation and supporting data management.

---

## Overview

The system has two main components working against the same SQL Server database (`INTECPL`):

| Component | Technology | Responsibility |
|---|---|---|
| **Report generator** | Visual FoxPro 9 + Excel COM | Queries SQL functions, renders a formatted Excel workbook with formulas (USD and COP sheets) |
| **Data entry screens** | .NET 4.8 WinForms (ODBC) | CRUD for projections, vendor categorization, document lookup |

All financial logic (aggregation, currency conversion, weekly pivoting) lives **exclusively in SQL Server** through Table-Valued Functions + a generic pivot Stored Procedure. No client component calculates financial values; they only consume pre-transformed data.

---

## Folder Structure

```
CashFlowManager/
├── CashFlowManager/                 ← FoxPro: Excel generator
│   ├── cashflowmanagerdata.prg          Rendering logic
│   └── cashflowmanager.scx/.SCT         FoxPro form
│
├── CashflowManagerUI/               ← .NET WinForms
│   ├── CashflowManagerUI.sln
│   ├── CashflowManagerUI.csproj
│   ├── Program.cs                       Entry point + screen router
│   ├── App.config                       ODBC connection string
│   ├── Common/
│   │   └── BaseProjectionForm.cs        Abstract base class (CRUD + UI)
│   ├── Projection/
│   │   ├── ProjectionForm.cs            Manual projections by NIT/week
│   │   ├── ProjectionForm.Designer.cs
│   │   ├── ProveedorLookupForm.cs       NIT search popup
│   │   └── ProveedorLookupForm.Designer.cs
│   ├── DocumentQuery/
│   │   └── DocumentQueryForm.cs         Document lookup + FechaCobro
│   ├── ProveedorCategory/
│   │   └── ProveedorCategoryForm.cs     Vendor category assignment
│   └── Properties/
│       ├── AssemblyInfo.cs
│       ├── Resources.Designer.cs
│       └── Settings.Designer.cs
│
└── SQL/
    ├── CreateTablesDDL.sql              Full DDL (tables, ALTERs, seed data)
    ├── Initialize_MtprocliCategories.sql
    ├── OfimaSchemaHelper.txt            Ofima table reference
    └── CashflowData/
        ├── CashflowDataHeader.sql       TVF: opening bank balances
        ├── CashflowDataIngresos.sql     TVF: revenue by category/week
        ├── CashflowDataEgresos.sql      TVF: expenses by category/week
        ├── CashflowDataFlujoEconomico.sql  TVF: financing cash flow
        ├── CashflowDataProjection.sql   TVF: manual projections
        └── CashflowPivot.sql            Generic dynamic pivot SP
```

---

## Architecture

```
                         ┌─────────────────────────────┐
                         │      SQL Server (INTECPL)    │
                         │                              │
                         │  Ofima tables:               │
                         │   TRADE, MTPROCLI, MVBANCOS  │
                         │   ABOCXP, MVTO, MTCAMBIO     │
                         │                              │
                         │  Custom tables:              │
                         │   CashflowProjection         │
                         │   CashflowCategory           │
                         │   CashflowManagerConfig      │
                         │                              │
                         │  5 TVFs + 1 pivot SP         │
                         └──────┬──────────────┬────────┘
                                │              │
                         ODBC   │              │  ODBC
                                │              │
              ┌─────────────────▼──┐    ┌──────▼──────────────────┐
              │   FoxPro (.prg)    │    │  .NET WinForms (.exe)   │
              │                    │    │                          │
              │  Calls CashflowPivot   │  3 data entry screens    │
              │  for each section  │    │  (projection, document, │
              │  and renders Excel │    │   vendor category)       │
              │  with formulas     │    │                          │
              │  (USD + COP)       │    │  Launched by FoxPro:     │
              │                    │    │  RUN /N "CashflowManagerUI│
              │                    │    │  .exe" screen=<name>     │
              └────────────────────┘    └──────────────────────────┘
```

FoxPro acts as the orchestrator: it generates Excel reports and launches the .NET application when the user needs to enter or query data.

---

## .NET Component — CashflowManagerUI

### Namespace and Assembly

- **Namespace**: `CashFlowManager.UI`
- **Assembly**: `CashflowManagerUI.exe`
- **Target**: .NET Framework 4.8

### Screen Router (Program.cs)

FoxPro invokes the exe with a `screen=` argument:

```
CashflowManagerUI.exe screen=proyeccion    → ProjectionForm (default)
CashflowManagerUI.exe screen=documento     → DocumentQueryForm
CashflowManagerUI.exe screen=proveedores   → ProveedorCategoryForm
```

Adding a new screen only requires creating the Form class and registering a `case` in the `switch` inside `Program.cs`.

### BaseProjectionForm — Abstract Base Class

All CRUD screens inherit from `BaseProjectionForm`, which programmatically generates:

- **Header panel**: corporate blue bar (RGB 30,58,95) + dynamic title
- **Toolbar**: New, Save, Delete, Refresh buttons + status bar
- **DataGridView**: auto-sized columns, alternating row colors, `BindingSource` binding
- **Footer panel**: version + company name

Each subclass implements these abstract members:

| Abstract Member | Type | Description |
|---|---|---|
| `TituloVentana` | `string` | Title displayed in the header |
| `ConnStr` | `string` | Connection string (from App.config) |
| `SelectSql` | `string` | SELECT query to load data |
| `SaveSql` | `string` | Base query for `OdbcCommandBuilder` to generate INSERT/UPDATE/DELETE |
| `ConfigurarColumnas()` | `void` | Configures grid columns (readonly, ComboBox, widths, headers) |
| `ConstruirTablaVacia()` | `DataTable` | Defines DataTable schema when there is no data |

Virtual hooks `OnNuevo()`, `OnGuardar()`, `OnEliminar()`, `ValidarFila()` allow overriding behavior per screen without modifying the base.

### Screens

#### ProjectionForm — Manual Projections

Edits the `CashflowProjection` table. The grid allows entering projected amounts by **NIT + Year + ISO Week**. Filters: year and week. Includes a `ProveedorLookupForm` popup for NIT search with autocomplete.

#### DocumentQueryForm — Document Lookup

Searches `TRADE` by (TIPODCTO, NRODCTO) filtered by the ORIGEN configured in `CashflowManagerConfig`. Displays read-only fields (Vendor, Total, Notes) and an editable **FechaCobro** (collection date) field that updates TRADE directly.

#### ProveedorCategoryForm — Vendor Categorization

Shows all `MTPROCLI` records with a ComboBox column to assign `CashflowCategoryId` (FK to `CashflowCategory`). Includes a dual filter bar: text search (NIT or name) + category type filter (Ingresos/Egresos/Financiamiento). New and Delete buttons are hidden; only Save and Refresh are available.

---

## SQL Layer

### Custom Tables

```sql
CashflowManagerConfig (Config PK, Value)
    -- Settings: ORIGEN, SemanasAtras, SemanasAdelante

CashflowProjection (NIT PK, Year PK, Week PK, TotalProjected)
    -- Manual projections entered via ProjectionForm

CashflowCategory (Id PK, Category, ParentName, ItemOrder)
    -- 28 categories: INGRESOS (01-09), EGRESOS (10-21), FINANCIAMIENTO (22-28)

MTPROCLI  + ALTER ADD CashflowCategoryId FK → CashflowCategory
TRADE     + ALTER ADD FechaCobro DATETIME NULL
```

### Existing Ofima Tables Consumed

| Table | Usage |
|---|---|
| `TRADE` | Commercial documents (invoices, notes, etc.) |
| `MTPROCLI` | Vendor/client master |
| `MTCAMBIO` | Exchange rates (daily TRM COP/USD) |
| `MVBANCOS` / `MTBANCOS` | Bank transactions and master |
| `ABOCXP` | Accounts payable aging |
| `MVTO` | Accounting entries (payroll, taxes) |

### TVF + Dynamic Pivot Pattern

Each financial section is implemented as a **Table-Valued Function** returning rows with the structure `(Concepto, ItemOrder, Semana, Valor)`:

| TVF | Section | Primary Source |
|---|---|---|
| `CashflowDataHeader` | Opening bank balances | MVBANCOS + MTCAMBIO |
| `CashflowDataIngresos` | Revenue by category | TRADE + MTPROCLI + CashflowCategory |
| `CashflowDataEgresos` | Expenses by category | ABOCXP + MVTO + MTCAMBIO |
| `CashflowDataFlujoEconomico` | Financing cash flow | (stub, zero values) |
| `CashflowDataProjection` | Manual projections | CashflowProjection + CashflowCategory |

The **`CashflowPivot` SP** receives the TVF name, date range, currency and optional category, and dynamically generates a `PIVOT` with one column per week in the range. It uses an internal whitelist to validate the function name and prevent SQL injection.

Adding a new financial concept = adding a `UNION ALL` in the corresponding TVF. No changes to FoxPro or .NET.

---

## FoxPro Component — Excel Generator

`cashflowmanagerdata.prg` generates an Excel workbook with two sheets (USD and COP). The flow is:

1. Reads configuration (`SemanasAtras`, `SemanasAdelante`) from `CashflowManagerConfig`
2. Calculates the ISO week range based on the provided date
3. Creates an Excel workbook via COM (ActiveX)
4. For each sheet, calls `CashflowPivot` passing each TVF sequentially:
   - Header → Ingresos → Subtotal Ingresos → Egresos → Subtotal Egresos → Flujo Económico → Subtotal Financiamiento → Totals
5. Each section is drawn with `DibujarCursor` (data) and `DibujarSubtotal` (SUM formulas)
6. Applies corporate color palette (blue headers, alternating rows, purple totals section)
7. Saves as `.xlsx`

The drawing functions use a **row pointer pattern**: each receives `lnFilaActual` and returns the next available row. This allows inserting or removing sections without renumbering anything.

---

## Database Connection

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

The entire .NET application uses `System.Data.Odbc` (`OdbcConnection`, `OdbcDataAdapter`, `OdbcCommandBuilder`). FoxPro also connects via ODBC to the same server.

---

## Scalability

The system is designed to grow along three axes without restructuring:

**New .NET screens:**
Create a class inheriting `BaseProjectionForm`, implement the abstract members, and add a `case` in `Program.cs`. The full UI (header, grid, toolbar, footer) is generated automatically.

**New financial concepts:**
Add a `UNION ALL` in the corresponding TVF with the new `Concepto`, `ItemOrder`, and calculation logic. The pivot SP and FoxPro renderer include it automatically.

**New classification categories:**
Insert rows in `CashflowCategory`. The .NET screens and TVFs consume them dynamically with no code changes.

## Good Practices Applied

- **Single responsibility:** each VFP function does exactly one visual task.
- **Fail-fast with `IF NOT`:** each section returns `.T.`/`.F.`; the main function stops immediately on any SQL error and surfaces a descriptive message.
- **No hardcoded dates:** week ranges are always calculated from `GETDATE()` relative offsets.
- **Named color constants:** `#DEFINE COLOR_*` palette at the top of the file — change a color in one place, updates everywhere.
- **Structured error handling:** `TRY / CATCH` wraps the entire workbook generation; error detail (message, procedure, line number) is shown to the user.
- **Separation of formatting and data:** `FormatearHojaBase` runs on an empty sheet; data functions run after. AutoFit runs last, when all labels are already rendered.

---

## Project Structure

```
CashFlowManager/
├── cashflowmanagerdata.prg   # VFP: all rendering logic
├── cashflowmanager.scx/.SCT  # VFP: UI form (entry point)
└── SQL/
    ├── CashflowDataHeader.sql
    ├── CashflowDataIngresos.sql
    ├── CashflowDataEgresos.sql
    └── CashflowDataFlujoEconomico.sql
```

---

## Requirements

- Visual FoxPro 9 (or compatible runtime)
- SQL Server 2012+ (uses `DATEADD`, dynamic PIVOT)
- Microsoft Excel installed (COM automation via `CREATEOBJECT("Excel.Application")`)

---

## Usage

```foxpro
* GenerarCashFlowExcel(fechaFinal, semanasAtras, semanasAdelante)
GenerarCashFlowExcel(DATE(), 8, 3)
```

Generates `FlujoDeCaja_<Company>_<Month><Year>.xlsx` in the current working directory, with two sheets (USD and COP), frozen panes at row 6 / column B, and a success dialog showing the period and week range.
