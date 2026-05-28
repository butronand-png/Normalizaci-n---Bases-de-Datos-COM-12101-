-- ============================================================
-- ESQUEMA NORMALIZADO A 3FN
-- ============================================================
CREATE TABLE IF NOT EXISTS sector (
    sector  TEXT PRIMARY KEY,
    ambito  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS concepto (
    clave_concepto   TEXT PRIMARY KEY,
    nombre           TEXT NOT NULL,
    subtema          TEXT,
    sector           TEXT REFERENCES sector(sector),
    tipo_informacion TEXT,
    base_registro    TEXT,
    unidad_medida    TEXT,
    frecuencia       TEXT,
    difusion         TEXT
);

CREATE TABLE IF NOT EXISTS registro (
    clave_concepto  TEXT REFERENCES concepto(clave_concepto),
    ciclo           INT,
    mes             TEXT,
    monto           NUMERIC,
    PRIMARY KEY (clave_concepto, ciclo, mes)
);
