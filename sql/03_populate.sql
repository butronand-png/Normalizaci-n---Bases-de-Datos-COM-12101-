-- Poblar las tablas normalizadas desde la tabla cruda

INSERT INTO sector (sector, ambito)
SELECT DISTINCT sector, ambito
FROM deuda_raw
WHERE sector IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO concepto (
    clave_concepto, nombre, subtema, sector,
    tipo_informacion, base_registro, unidad_medida, frecuencia, difusion
)
SELECT DISTINCT
    clave_concepto, nombre, subtema, sector,
    tipo_informacion, base_registro, unidad_medida, frecuencia, difusion
FROM deuda_raw
ON CONFLICT DO NOTHING;

INSERT INTO registro (clave_concepto, ciclo, mes, monto)
SELECT clave_concepto, ciclo, mes, monto
FROM deuda_raw
ON CONFLICT DO NOTHING;

SELECT 'sector'   AS tabla, COUNT(*) AS filas FROM sector
UNION ALL
SELECT 'concepto' AS tabla, COUNT(*) AS filas FROM concepto
UNION ALL
SELECT 'registro' AS tabla, COUNT(*) AS filas FROM registro;
