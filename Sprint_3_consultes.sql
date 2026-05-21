/*===================================================
=====================================================
                    NIVELL 1
=====================================================
===================================================^*/


# Crea capa lògica Silver
CREATE SCHEMA IF NOT EXISTS `sprint3-analytics-alicia.sprint3_silver`
OPTIONS(
  location = "EU"
  );

  # Crea taula externa companies_raw
  CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-alicia.sprint3_bronze.companies_raw`
(
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

# Crea taula externa transactions_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-alicia.sprint3_bronze.transactions_raw`
(
  id STRING,
  card_id STRING,
  business_id STRING,
  timestamp STRING,
  amount STRING,
  declined STRING,
  product_ids STRING,
  user_id STRING,
  lat STRING,
  longitude STRING
)
OPTIONS (
  format = 'CSV',
  field_delimiter = ';',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  skip_leading_rows = 1
);

#Crea taula externa european_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-alicia.sprint3_bronze.european_users_raw`
(
  id STRING,
  name STRING,
  surname STRING,
  phone STRING,
  email STRING,
  birth_date STRING,
  country STRING,
  city STRING,
  postal_code STRING,
  address STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

# Crea taula externa american_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-alicia.sprint3_bronze.american_users_raw`
(
  id STRING,
  name STRING,
  surname STRING,
  phone STRING,
  email STRING,
  birth_date STRING,
  country STRING,
  city STRING,
  postal_code STRING,
  address STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

# Crea taula externa credit_cards_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-alicia.sprint3_bronze.credit_cards_raw`
(
  id STRING,
  user_id STRING,
  iban STRING,
  pan STRING,
  pin STRING,
  cvv STRING,
  track1 STRING,
  track2 STRING,
  expiring_date STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
);

# Crea taula nativa transactions_raw_native

CREATE OR REPLACE TABLE `sprint3-analytics-alicia.sprint3_bronze.transactions_raw_native` AS
SELECT
  *
FROM
  `sprint3-analytics-alicia.sprint3_bronze.transactions_raw`
  
  # Costos consulta taula externa
  SELECT id
FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw`;

# Costos consulta taula nativa

SELECT id
FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw_native`;

# Costos amb LIMIT
SELECT *
FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw_native`
LIMIT 10;

# Costos SENSE LIMIT
SELECT *
FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw_native`;

  /*Exercici 5
---------------------------------------------------^*/
WITH transactions_formatada AS (
  SELECT
    COALESCE(
      SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S%Ez', timestamp),
      SAFE.PARSE_TIMESTAMP('%d/%m/%Y %H:%M:%S', timestamp)
    ) AS data_formatada,
    
    SAFE_CAST(amount AS FLOAT64) AS amount,

    (LOWER(TRIM(declined)) = 'true' 
    OR LOWER(TRIM(declined)) = '1' 
    OR LOWER(TRIM(declined)) = 'yes') AS is_declined

  FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw`
)

SELECT
  DATE(transactions_formatada.data_formatada) AS data_transaccio,
  ROUND(SUM(amount), 3) AS ingressos_totals
FROM transactions_formatada
WHERE transactions_formatada.data_formatada IS NOT NULL
  AND EXTRACT(YEAR FROM transactions_formatada.data_formatada) = 2021
  AND is_declined = FALSE
GROUP BY data_transaccio
ORDER BY ingressos_totals DESC
LIMIT 5;

  /*Exercici 6
---------------------------------------------------^*/

WITH transactions_formatada AS (
  SELECT
    COALESCE(
      SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S%Ez', t.timestamp),
      SAFE.PARSE_TIMESTAMP('%d/%m/%Y %H:%M:%S', t.timestamp)
    ) AS data_formatada,
    SAFE_CAST(t.amount AS FLOAT64) AS amount,
    SAFE_CAST(t.company_id AS INT64) AS company_id

  FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw` t
),

companies_formatada AS (
  SELECT
    SAFE_CAST(company_id AS INT64) AS company_id,
    company_name,
    country
  FROM `sprint3-analytics-alicia.sprint3_bronze.companies_raw`
)

SELECT
  c.company_name AS nom_empresa,
  c.country AS pais,
  DATE(t.data_formatada) AS data_transaccio

FROM transactions_formatada t
JOIN companies_formatada c
  ON t.company_id = c.company_id

WHERE t.data_formatada IS NOT NULL
  AND t.amount BETWEEN 100 AND 200
  AND DATE(t.data_formatada) IN (
    '2015-04-29',
    '2018-07-20',
    '2024-03-13'
  )

ORDER BY data_transaccio;

/*===================================================
=====================================================
                      NIVELL 2
=====================================================
===================================================^*/

# Exercici 1: Creació taula products clean a silver

CREATE OR REPLACE TABLE `sprint3-analytics-alicia.sprint3_silver.products_clean` AS
SELECT
  CAST(id AS INT64) AS product_id,
  product_name AS name,
  SAFE_CAST(
        REPLACE(price, '$', '') 
        AS FLOAT64
  ) AS price,
  colour,
  weight,
 SAFE_CAST(
    REGEXP_REPLACE(warehouse_id, r'[^0-9]', '')
    AS INT64
) AS warehouse_id

FROM `sprint3-analytics-alicia.sprint3_bronze.products_raw`;

# Exercici 2: Creació taula transactions clean a silver
CREATE OR REPLACE TABLE `sprint3-analytics-alicia.sprint3_silver.transactions_clean` AS
SELECT
    id AS transaction_id,
    card_id,
    business_id,
    PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp) AS transaction_timestamp,
    IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
    declined,
   ARRAY(
        SELECT SAFE_CAST(TRIM(p) AS INT64)
        FROM UNNEST(SPLIT(product_ids, ',')) AS p
    ) AS product_ids,
    user_id,
    SAFE_CAST(TRIM(lat) AS FLOAT64) AS lat,
    SAFE_CAST(TRIM(longitude) AS FLOAT64) AS longitude

FROM `sprint3-analytics-alicia.sprint3_bronze.transactions_raw_native`;

# Exercici 3: Creació taula users_combined a silver

CREATE OR REPLACE TABLE `sprint3-analytics-alicia.sprint3_silver.users_combined` AS

SELECT
    id AS user_id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    'Europe' AS origin

FROM `sprint3-analytics-alicia.sprint3_bronze.european_users_raw`

UNION ALL

SELECT
    id AS user_id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    'America' AS origin

FROM `sprint3-analytics-alicia.sprint3_bronze.american_users_raw`;

# Exercici 4: Materialització de companies i credit cards

CREATE OR REPLACE TABLE `sprint3-analytics-alicia.sprint3_silver.companies_clean` AS
SELECT
    company_id AS business_id,
    company_name,
    phone,
    email,
    country,
    website
FROM `sprint3-analytics-alicia.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3-analytics-alicia.sprint3_silver.credit_cards_clean` AS
SELECT
    id AS card_id,
    user_id,
    iban,
    pan,
    pin,
    cvv,
    track1,
    track2,
    expiring_date

FROM `sprint3-analytics-alicia.sprint3_bronze.credit_cards_raw`;


/*===================================================
=====================================================
                      NIVELL 3
=====================================================
===================================================^*/

# Exercici 1: Vista de marketing

#creació
CREATE OR REPLACE VIEW `sprint3-analytics-alicia.sprint3_gold.v_marketing_kpis` AS 
SELECT 
	c.company_name AS nom_empresa,
	c.phone AS telefon,
	c.country AS pais,
	 ROUND(
        AVG(
            CASE 
                WHEN SAFE_CAST(t.declined AS INT64) = 0 
                THEN t.amount 
                ELSE NULL 
            END
        ),
        3
    ) AS mitjana_compra,
    CASE
	  WHEN AVG(
            CASE 
                WHEN SAFE_CAST(t.declined AS INT64) = 0 
                THEN t.amount 
                ELSE NULL 
            END
        ) > 260 THEN 'Premium'
        ELSE 'Standard'
    END AS client_tier
FROM `sprint3-analytics-alicia.sprint3_silver.transactions_clean` t
JOIN `sprint3-analytics-alicia.sprint3_silver.companies_clean` c 
ON TRIM(t.business_id) = TRIM(c.business_id)
GROUP BY 
	c.company_name,
	c.phone,
	c.country;

#testeig
SELECT *
FROM `sprint3-analytics-alicia.sprint3_gold.v_marketing_kpis`
ORDER BY 
  CASE
    WHEN client_tier = 'Premium' THEN 1
    ELSE 2
  END,
  mitjana_compra DESC
LIMIT 10;

#execució
SELECT *
FROM `sprint3-analytics-alicia.sprint3_gold.v_marketing_kpis`
ORDER BY 
  CASE
    WHEN client_tier = 'Premium' THEN 1
    ELSE 2
  END,
  mitjana_compra DESC;
 

# Exercici 2: Consulta ranking productes
SELECT 
  product_id AS id_de_producte,
  name AS nom,
  CONCAT('$', FORMAT('%.2f', price)) AS preu,
  colour AS color,
  total_sold AS total_venut,
  price * total_sold AS revenue,
  ROW_NUMBER() OVER (ORDER BY total_sold DESC) AS ranking

FROM `sprint3-analytics-alicia.sprint3_gold.product_sales_ranking`

ORDER BY total_sold DESC