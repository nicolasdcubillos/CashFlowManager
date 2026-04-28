-- ===========================================================
--  CashFlowManager - Inicialización de clasificación de moneda MTBANCOS
--  Autor: Nicolas David Cubillos
--  Descripcion:
--    Asigna CashflowBankClassificationId (COP / USD) a las cuentas
--    bancarias conocidas de INTECPLAST en dbo.MTBANCOS.
--
--  Nota: el cruce se hace por NROCTA (número de cuenta) ya que
--  CODIGOCTA es un código interno del sistema Ofima y puede variar.
--  Ajustar si el cruce debe hacerse por CODIGOCTA.
-- ===========================================================

USE INTECPL;

-- ── COP: Cuentas en Pesos Colombianos ────────────────────────────────
UPDATE dbo.MTBANCOS
SET CashflowBankClassificationId = 'COP'
WHERE RTRIM(NROCTA) IN (
    '52500003946',      -- BANCOLOMBIA CTE 52500003946         (11100531)
    '494001761',        -- BBVA CTE 494001761                  (11100511)
    '061263596',        -- BANCO DE BOGOTA CTE 061263596       (11100502)
    '061-28167-1',      -- BANCO DE BOGOTA CTE 061281671       (11100516)
    '061403945',        -- BANCO DE BOGOTA AHO 061403945       (11200502)
    '4721009306',       -- COLPATRIA MULTIBANCA CTE 4721009306 (11100503)
    '474969998050',     -- BANCO DAVIVIENDA CTE 474969998050   (11100518)
    '006375158',        -- BANCO ITAU CTE 006375158            (11100530)
    '292814878',        -- BANCO DE OCCIDENTE CTE 292814878    (11100529)
    '100007304'         -- BANCO SANTANDER AHO 100007304       (11200506)
);

-- ── USD: Cuentas en Dólares Americanos ───────────────────────────────
UPDATE dbo.MTBANCOS
SET CashflowBankClassificationId = 'USD'
WHERE RTRIM(NROCTA) IN (
    '1040113516'            -- HELM BANK MIAMI (USD)
);

-- ── PCA: PA Credicorp - Excedentes ───────────────────────────────────
UPDATE dbo.MTBANCOS
SET CashflowBankClassificationId = 'PCA'
WHERE RTRIM(NROCTA) IN (
    '005126381           ',          -- PA CREDICORP - ITAU
    '919301183689        '          -- FAFP GASTOS Y COMISIONES
);