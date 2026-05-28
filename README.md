# Normalización a 3FN — Deuda Pública SHCP

**Materia:** Bases de Datos (COM-12101) — ITAM  
**Dataset:** Indicadores de Deuda Pública 2011–2026  
**Fuente:** Secretaría de Hacienda y Crédito Público (SHCP)  
**Link:** https://www.datos.gob.mx/busca/dataset/indicadores-de-la-deuda-publica  

---

## 1. Descripción del dataset

El dataset contiene indicadores de deuda pública del Gobierno Federal mexicano,
entidades paraestatales financieras y no financieras, y el sector público federal,
publicado por la SHCP como dato abierto. Cubre el período enero 2011 a enero 2026.

| Característica   | Valor                          |
|------------------|--------------------------------|
| Filas            | 82,455                         |
| Columnas         | 16                             |
| Formato          | CSV, UTF-8                     |
| Institución      | SHCP — datos.gob.mx            |

Cada fila representa la medición mensual de un concepto de deuda (identificado por
`clave_concepto`) para un año (`ciclo`) y mes (`mes`) específicos. Los atributos
descriptivos del concepto se repiten en cada fila, generando redundancia masiva.

---

## 2. Esquema original (tabla plana)

Al importar el CSV sin transformaciones se obtiene la siguiente relación:

```
deuda_raw(ciclo, mes, clave_concepto, nombre, tema, subtema, sector, ambito,
          tipo_informacion, base_registro, unidad_medida, periodo_inicio,
          periodo_final, frecuencia, difusion, monto)
```

Se identificaron tres columnas constantes en las 82,455 filas que no aportan
información discriminante y se descartan del esquema normalizado:

- `tema` = `'Deuda Pública'` (igual en todas las filas)
- `periodo_inicio` = `'2011-01'` (igual en todas las filas)
- `periodo_final` = `'2026-01'` (igual en todas las filas)

El esquema de trabajo resultante es:

```
R(clave_concepto, ciclo, mes, nombre, subtema, sector, ambito,
  tipo_informacion, base_registro, unidad_medida, frecuencia, difusion, monto)

Llave candidata: {clave_concepto, ciclo, mes}
```

---

## 3. Dependencias funcionales identificadas

| ID  | Dependencia funcional                            | Tipo                      |
|-----|--------------------------------------------------|---------------------------|
| F1  | clave_concepto → nombre                          | Parcial (viola 2FN)       |
| F2  | clave_concepto → subtema                         | Parcial (viola 2FN)       |
| F3  | clave_concepto → sector                          | Parcial (viola 2FN)       |
| F4  | clave_concepto → tipo_informacion                | Parcial (viola 2FN)       |
| F5  | clave_concepto → base_registro                   | Parcial (viola 2FN)       |
| F6  | clave_concepto → unidad_medida                   | Parcial (viola 2FN)       |
| F7  | clave_concepto → frecuencia                      | Parcial (viola 2FN)       |
| F8  | clave_concepto → difusion                        | Parcial (viola 2FN)       |
| F9  | {clave_concepto, ciclo, mes} → monto             | Completa (cumple 2FN)     |
| F10 | sector → ambito                                  | Transitiva (viola 3FN)    |

**Nota sobre F10:** Las dependencias F3 y F10 forman la cadena transitiva
`clave_concepto →(F3) sector →(F10) ambito`. Como `sector` no es superllave
de R, la presencia de `ambito` en la misma relación viola 3FN.

Todas las dependencias F1–F8 se verificaron computacionalmente en los datos:
ninguna `clave_concepto` tiene más de un valor para cualquiera de estos atributos.
La dependencia F10 también se verificó: cada valor de `sector` mapea a exactamente
un valor de `ambito` en todo el dataset.

---

## 4. Proceso de normalización

### 4.1 Primera Forma Normal (1FN)

La tabla original ya satisface 1FN: todos los atributos contienen valores atómicos
y no existen grupos repetitivos. No se requiere descomposición en este paso.

### 4.2 Segunda Forma Normal (2FN)

Una relación está en 2FN si está en 1FN y ningún atributo no-llave depende de un
subconjunto propio de la llave candidata.

La llave candidata es compuesta: `{clave_concepto, ciclo, mes}`. Las dependencias
F1–F8 son dependencias **parciales**: los nueve atributos descriptivos del concepto
dependen únicamente de `clave_concepto`, no de `ciclo` ni `mes`. Esto significa que,
para cada concepto de deuda, esos atributos se repiten idénticos en cada fila
mensual — redundancia pura que viola 2FN.

Solo `monto` (F9) depende de la llave completa.

**Descomposición a 2FN:** se separan los atributos del concepto en una tabla propia.

```
Concepto(clave_concepto, nombre, subtema, sector, ambito,
         tipo_informacion, base_registro, unidad_medida, frecuencia, difusion)
         PK: clave_concepto

Registro(clave_concepto, ciclo, mes, monto)
         PK: {clave_concepto, ciclo, mes}
         FK: clave_concepto → Concepto
```

La descomposición es sin pérdida (*lossless*) porque
`Concepto ∩ Registro = {clave_concepto}`, que es llave de `Concepto`.

### 4.3 Tercera Forma Normal (3FN)

Una relación está en 3FN si está en 2FN y ningún atributo no-llave depende
transitivamente de la llave.

Al examinar la tabla `Concepto` (llave: `clave_concepto`) se detecta la dependencia
F10: `sector → ambito`. Esto produce la cadena transitiva
`clave_concepto →(F3) sector →(F10) ambito`. Como `sector` no es superllave
de `Concepto`, la presencia de `ambito` en esta tabla viola 3FN.

**Descomposición a 3FN:** se extrae `sector` con su dependiente `ambito` a una
tabla propia.

```
Sector(sector, ambito)
       PK: sector

Concepto(clave_concepto, nombre, subtema, sector,
         tipo_informacion, base_registro, unidad_medida, frecuencia, difusion)
         PK: clave_concepto
         FK: sector → Sector

Registro(clave_concepto, ciclo, mes, monto)
         PK: {clave_concepto, ciclo, mes}
         FK: clave_concepto → Concepto
```

La descomposición es sin pérdida porque `Concepto ∩ Sector = {sector}`,
que es llave de `Sector`. Todas las dependencias funcionales originales
quedan preservadas: F10 en `Sector`, F1–F3 y F4–F8 en `Concepto`, F9 en `Registro`.

---

## 5. Esquema final normalizado (DDL)

```sql
-- Tabla 1: Sector
-- Elimina la dependencia transitiva sector → ambito (F10)
CREATE TABLE sector (
    sector  TEXT PRIMARY KEY,
    ambito  TEXT NOT NULL
);

-- Tabla 2: Concepto
-- Concentra los metadatos del concepto de deuda.
-- Elimina las dependencias parciales F1-F8 respecto a la llave compuesta original.
CREATE TABLE concepto (
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

-- Tabla 3: Registro
-- Contiene únicamente la serie de tiempo.
-- monto es el único atributo que depende de la llave completa {clave_concepto, ciclo, mes} (F9).
CREATE TABLE registro (
    clave_concepto  TEXT REFERENCES concepto(clave_concepto),
    ciclo           INT,
    mes             TEXT,
    monto           NUMERIC,
    PRIMARY KEY (clave_concepto, ciclo, mes)
);
```

---

## 6. Carga de datos

```sql
-- 1. Importar CSV a tabla plana
COPY deuda_raw
FROM '/ruta/al/archivo/deuda_publica_2011_012026.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 2. Poblar tablas normalizadas
INSERT INTO sector (sector, ambito)
SELECT DISTINCT sector, ambito FROM deuda_raw WHERE sector IS NOT NULL;

INSERT INTO concepto
SELECT DISTINCT clave_concepto, nombre, subtema, sector,
    tipo_informacion, base_registro, unidad_medida, frecuencia, difusion
FROM deuda_raw;

INSERT INTO registro (clave_concepto, ciclo, mes, monto)
SELECT clave_concepto, ciclo, mes, monto FROM deuda_raw;
```

---

## 7. Estructura del repositorio

```
/
├── README.md                            ← este archivo
├── data/
│   └── deuda_publica_2011_012026.csv    ← dataset original
└── sql/
    ├── 01_create_raw.sql                ← tabla plana + COPY
    ├── 02_normalized_ddl.sql            ← DDL del esquema 3FN
    └── 03_populate.sql                  ← INSERT ... SELECT
```

---

## 8. Cómo replicar paso a paso

### Requisitos previos

- PostgreSQL 14 o superior instalado y corriendo
- Git instalado
- El archivo CSV está incluido en el repositorio (`data/`)

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/butronand-png/Normalizaci-n---Bases-de-Datos-COM-12101-
cd Normalizaci-n---Bases-de-Datos-COM-12101-
```

### Paso 2 — Ajustar la ruta del CSV en el script 01

Abre `sql/01_create_raw.sql` y reemplaza la línea del `COPY` con la ruta absoluta
real del CSV en tu máquina:

**En macOS/Linux:**
```sql
-- Reemplaza esto:
COPY deuda_raw FROM '/data/deuda_publica_2011_012026.csv' ...

-- Por la ruta absoluta en tu máquina, por ejemplo:
COPY deuda_raw FROM '/Users/tu_usuario/Normalizaci-n---Bases-de-Datos-COM-12101-/data/deuda_publica_2011_012026.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

**En Windows:**
```sql
COPY deuda_raw FROM 'C:\\Users\\tu_usuario\\Normalizaci-n---Bases-de-Datos-COM-12101-\\data\\deuda_publica_2011_012026.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
```

**Con Docker (recomendado para evitar problemas de rutas):**
```bash
# Copia el CSV dentro del contenedor primero
docker cp data/deuda_publica_2011_012026.csv <nombre_contenedor>:/tmp/deuda_publica_2011_012026.csv

# Luego en el script usa:
# COPY deuda_raw FROM '/tmp/deuda_publica_2011_012026.csv' ...
```

### Paso 3 — Ejecutar los scripts en orden

**Opción A — desde terminal con psql:**

```bash
# Conectarse a PostgreSQL
psql -U postgres

# Ejecutar los 3 scripts en orden
\i sql/01_create_raw.sql
\i sql/02_normalized_ddl.sql
\i sql/03_populate.sql
```

**Opción B — desde DBeaver u otro cliente SQL:**

1. Conectarse a la base de datos `postgres`
2. Abrir y ejecutar `sql/01_create_raw.sql`
3. Abrir y ejecutar `sql/02_normalized_ddl.sql`
4. Abrir y ejecutar `sql/03_populate.sql`

### Paso 4 — Verificar el resultado

El script `03_populate.sql` incluye una consulta de verificación al final.
El resultado esperado es:

```
  tabla   | filas
----------+-------
 sector   |     4
 concepto |   519
 registro | 82455
```

### Paso 5 — Consultar las tablas normalizadas

Una vez pobladas las tablas, puedes explorar los datos con queries como:

```sql
-- Ver todos los sectores y sus ámbitos
SELECT * FROM sector;

-- Ver conceptos de un subtema específico
SELECT clave_concepto, nombre, unidad_medida
FROM concepto
WHERE subtema = 'Deuda Externa de México';

-- Serie de tiempo de un indicador (JOIN completo)
SELECT r.ciclo, r.mes, r.monto, c.nombre, c.unidad_medida, s.ambito
FROM registro r
JOIN concepto c ON r.clave_concepto = c.clave_concepto
JOIN sector   s ON c.sector = s.sector
WHERE r.clave_concepto = 'XEM280'
ORDER BY r.ciclo,
         ARRAY_POSITION(ARRAY['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                               'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'],
                        r.mes);

-- Comparar tamaño original vs normalizado
SELECT 'deuda_raw' AS tabla, COUNT(*) AS filas FROM deuda_raw
UNION ALL
SELECT 'sector',   COUNT(*) FROM sector
UNION ALL
SELECT 'concepto', COUNT(*) FROM concepto
UNION ALL
SELECT 'registro', COUNT(*) FROM registro;
```
