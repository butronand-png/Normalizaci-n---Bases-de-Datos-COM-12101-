-- Tabla plana original para importar el CSV sin modificaciones
CREATE TABLE IF NOT EXISTS deuda_raw (
    ciclo            INT,
    mes              TEXT,
    clave_concepto   TEXT,
    nombre           TEXT,
    tema             TEXT,
    subtema          TEXT,
    sector           TEXT,
    ambito           TEXT,
    tipo_informacion TEXT,
    base_registro    TEXT,
    unidad_medida    TEXT,
    periodo_inicio   TEXT,
    periodo_final    TEXT,
    frecuencia       TEXT,
    difusion         TEXT,
    monto            NUMERIC
);

-- Ajustar la ruta al CSV según la ubicación real en el sistema
COPY deuda_raw
FROM '/data/deuda_publica_2011_012026.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
