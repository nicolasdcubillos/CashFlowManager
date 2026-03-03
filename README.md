# CashFlowManager

A lightweight, data-driven **weekly Cash Flow generator** that queries a SQL Server backend and renders a fully formatted Excel workbook via COM automation — built in Visual FoxPro (VFP).

---

## Overview

The core design principle is a **strict separation of concerns**:

- **SQL Server** owns all financial logic — aggregation, currency conversion, and pivoting are done entirely at the database layer.
- **VFP** is a pure rendering engine — it calls stored procedures, receives ready-to-paint cursors, and draws them into Excel cells.

This means the Excel output can be completely restructured without touching any financial calculations, and vice versa.

---

## Architecture

```
┌─────────────────────────────────┐
│         GenerarCashFlowExcel     │  Entry point
│  (parameters: date, weeks back,  │  Builds filename, creates workbook,
│   weeks forward)                 │  calls both sheets, saves .xlsx
└────────────┬────────────────────┘
             │
     ┌───────┴────────┐
     │                │
  Sheet USD        Sheet COP
     │                │
     └───────┬────────┘
             │
  ArmarDataCashFlowHistorico
  ┌──────────────────────────────────────────┐
  │  1. Header (opening balances / TRM)      │
  │  2. Label row "Ingresos"                 │
  │  3. EXEC IngresosPivot  → DibujarCursor  │
  │  4. DibujarSubtotal("Total Ingresos")    │
  │  5. Label row "Egresos"                  │
  │  6. EXEC EgresosPivot   → DibujarCursor  │
  │  7. DibujarSubtotal("Total Egresos")     │
  │  8. Label row "Flujo Economico"          │
  │  9. EXEC FlujoEcoPivot  → DibujarCursor  │
  │ 10. DibujarSubtotal("Total Financ.")     │
  │ 11. Flujo de Caja Financiero (row)       │
  │     [2 blank rows]                       │
  │ 12. DibujarTotalesCashFlow (7 items)     │
  │ 13. Columns(2).AutoFit                   │
  └──────────────────────────────────────────┘
```

---

## SQL Layer Pattern

Each financial section follows the same reusable pattern:

```sql
-- 1. Scalar function: returns one row per concept per week offset
CREATE FUNCTION dbo.CashflowData<Section>(
    @SemanaInicial INT,   -- negative = weeks back (e.g. -8)
    @SemanaFinal   INT,   -- 0 = current week
    @Moneda        CHAR(3)
) RETURNS TABLE ...

-- 2. Stored procedure: pivots the function output into wide format
--    One row per concept, one column per week
CREATE PROCEDURE dbo.CashflowData<Section>Pivot(...) AS
    SELECT * FROM (
        SELECT Concepto, Semana, Valor
        FROM dbo.CashflowData<Section>(...)
    ) src
    PIVOT (SUM(Valor) FOR Semana IN ([...dynamic weeks...])) pvt
```

**Key advantages of this pattern:**
- Adding a new financial concept = one `UNION ALL` row in the function. No changes to VFP.
- Week range is offset-based (`DATEADD(WEEK, offset, GETDATE())`), so it works seamlessly across year boundaries.
- Currency conversion (e.g. USD↔COP via daily exchange rate) lives entirely inside the function — the caller never needs to know.

---

## Excel Rendering Layer

All drawing helpers are stateless functions that accept `loHoja` and a starting row:

| Function | Responsibility |
|---|---|
| `FormatearHojaBase` | Font, col widths, white background, no gridlines, freeze panes |
| `ArmarEncabezadoCashFlow` | Title row, SEMANA headers, date row, TRM row (USD only) |
| `DibujarCursor` | SCAN loop: color, value, number format, thin border per row |
| `DibujarSubtotal` | SUM formula per column, bold, border |
| `DibujarTotalesCashFlow` | Fixed 7-row totals block, custom color, no alternation |
| `ColorFilaAlternar` | Returns alternating row color (even/odd) |

**Row pointer pattern:** every draw function receives `lnFilaActual` and returns the next available row. This makes sections fully composable — insert or remove a section without renumbering anything.

---

## Scalability

- **New section:** create `CashflowData<NewSection>.sql` (function + pivot SP), add one block in `ArmarDataCashFlowHistorico` calling `DibujarCursor` + `DibujarSubtotal`. Done.
- **New currency:** pass a different `@Moneda` parameter. Conversion logic is isolated in SQL.
- **Future projections:** `ArmarDataCashFlowFuturo` is a defined stub — when the projection model is ready, plug it in without modifying the historical flow.
- **More columns (weeks):** the pivot SP generates columns dynamically; VFP reads whatever columns the cursor returns. No hardcoded column counts.

---

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
