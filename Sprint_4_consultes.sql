/*===================================================
=====================================================
                    NIVELL 1
=====================================================
===================================================^*/


# S4-N1-E2 Mocking data: creació taula transactions_optimized
CREATE OR REPLACE TABLE sprint3-analytics-alicia.sprint3_gold.transactions_optimized
PARTITION BY DATE(transaction_timestamp)
CLUSTER BY business_id
AS
SELECT
    * EXCEPT(amount),
    CAST(amount AS NUMERIC) AS amount
FROM sprint3-analytics-alicia.sprint3_silver.transactions_recent
WHERE transaction_timestamp IS NOT NULL
AND business_id IS NOT NULL
AND amount IS NOT NULL;

# S4-N1-E2 Mocking data: creació taula transactions_optimized
CREATE OR REPLACE TABLE sprint3-analytics-alicia.sprint3_gold.transactions_optimized
PARTITION BY DATE(transaction_timestamp)
CLUSTER BY business_id
AS
SELECT
    * EXCEPT(amount),
    CAST(amount AS NUMERIC) AS amount
FROM sprint3-analytics-alicia.sprint3_silver.transactions_recent
WHERE transaction_timestamp IS NOT NULL
AND business_id IS NOT NULL
AND amount IS NOT NULL;

# S4-N1-E2 Mocking data: creació taula transactions_recent
CREATE OR REPLACE TABLE sprint3-analytics-alicia.sprint3_silver.transactions_recent AS
SELECT
    * EXCEPT(transaction_timestamp),
    TIMESTAMP(
        DATE_SUB(
            CURRENT_DATE(),
            INTERVAL CAST(FLOOR(RAND() * 50) AS INT64) DAY
        )
    ) AS transaction_timestamp
FROM sprint3-analytics-alicia.sprint3_silver.transactions_clean;

# S4-N1-E2-Validació de la taula transactions_recent
SELECT COUNT(*) AS dates_fora_de_rang
FROM sprint3_silver.transactions_recent
WHERE transaction_timestamp <
    TIMESTAMP_SUB(
        CURRENT_TIMESTAMP(),
        INTERVAL 50 DAY
    )
OR transaction_timestamp > CURRENT_TIMESTAMP();

# S4-N1-E3 Benchmark no optimitzat
SELECT *
FROM sprint3-analytics-alicia.sprint3_silver.transactions_recent
WHERE DATE(transaction_timestamp)
>= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

# S4-N1-E4 Verificació de la vista (execució)
SELECT *
FROM sprint3-analytics-alicia.sprint3_gold.mv_daily_sales
ORDER BY data_vendes DESC;

# S4-N1-E4 Vista materialitzada: vendes totals per dia
CREATE MATERIALIZED VIEW sprint3-analytics-alicia.sprint3_gold.mv_daily_sales AS
SELECT
   DATE(transaction_timestamp) AS data_vendes,
   SUM(amount) AS total_vendes
FROM sprint3-analytics-alicia.sprint3_gold.transactions_optimized
WHERE declined = '0'
GROUP BY data_vendes;

# S4-N2_E4 Filtratge avançat: 3a transacció
SELECT
    t.user_id,
    CONCAT(u.name, ' ', u.surname) AS nom_complet,
    u.email,
    t.transaction_timestamp AS data_tercera_transaccio,
    t.amount AS import_tercera_transaccio,
    ROUND(
        AVG(t.amount) OVER (
            PARTITION BY t.user_id
            ORDER BY t.transaction_timestamp
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
    2) AS mitjana_3_primeres
FROM sprint3_gold.transactions_optimized t
JOIN sprint3_silver.users_combined u ON t.user_id = u.user_id
WHERE t.declined = '0'
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY t.user_id
    ORDER BY t.transaction_timestamp
) = 3;

# S4-N2-E1 perfilat de clients VIP
WITH VIP_Stats AS (
    SELECT
        user_id,
        ROUND(SUM(amount), 3) AS total_gastat,
        COUNT(*) AS num_compres,
        ROUND(AVG(amount), 3) AS ticket_mitja,
        ROUND(MAX(amount), 3) AS max_compra

    FROM sprint3_gold.transactions_optimized
    WHERE declined = '0'
    GROUP BY user_id
    HAVING SUM(amount) > 500
)

SELECT
    v.user_id,
    CONCAT(u.name, ' ', u.surname) AS nom_complet,
    u.email,
    v.num_compres,
    v.ticket_mitja,
    v.max_compra,
    v.total_gastat

FROM VIP_Stats v
JOIN sprint3_silver.users_combined u ON v.user_id = u.user_id
ORDER BY v.total_gastat DESC;

# S4-N2-E1 Verificació de resultats: conteig product_ids a transactions_optimized
SELECT
    SUM(ARRAY_LENGTH(product_ids)) AS total_productos_nested
FROM sprint3_gold.transactions_optimized;

# S4-N2-E2 Ranquing de vendes
SELECT 
  COUNT(*) AS uds_venudes,
  product_name AS nom_producte
FROM `sprint3-analytics-alicia.sprint3_gold.dim_transactions_flat` 
GROUP BY product_sku, product_name
ORDER BY uds_venudes DESC
LIMIT 5;

# S4-N2-E2 Velocitat vendes (window functions sobre vista)
WITH CTE_daily_sales AS (
    SELECT
        data_vendes,
        total_vendes,
        LAG(total_vendes) OVER (ORDER BY data_vendes) AS vendes_ahir
    FROM sprint3_gold.mv_daily_sales
)

SELECT
    data_vendes,
    total_vendes AS vendes_avui,
    vendes_ahir,
    ROUND((total_vendes - vendes_ahir) / vendes_ahir * 100, 2) AS diff_percentual
FROM CTE_daily_sales
ORDER BY data_vendes ASC;

#S4-N2-E3 Totals acumulats (runnings totals sobre vistes)
SELECT
    data_vendes,
    ROUND(total_vendes, 2) AS vendes_del_dia,
    ROUND(
        SUM(total_vendes) OVER (
            PARTITION BY EXTRACT(YEAR FROM data_vendes)
            ORDER BY data_vendes
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS vendes_acumulades_ytd
FROM sprint3_gold.mv_daily_sales
ORDER BY data_vendes;

# S4-N2-E4 Validació de la consulta 
SELECT
    t.user_id,
    t.transaction_timestamp,
    t.amount,
    ROW_NUMBER() OVER (
        PARTITION BY t.user_id
        ORDER BY t.transaction_timestamp
    ) AS rn
FROM sprint3_gold.transactions_optimized t
WHERE t.declined = '0'
ORDER BY t.user_id, rn;

# S4-N3-E1 Crea la taula dim_transactions_flat (UNNEST) sense tax
CREATE OR REPLACE TABLE sprint3_gold.dim_transactions_flat AS
SELECT
  t.transaction_id,
  t.transaction_timestamp,
  ROUND(CAST(t.amount AS NUMERIC), 3) AS total_ticket,
  product_id AS product_sku,
  p.name AS product_name,
  ROUND(CAST(p.price AS NUMERIC), 3) AS product_price,
  `sprint3-analytics-alicia.sprint3_gold.calculate_tax`(
    CAST(p.price AS NUMERIC)
  ) AS product_price_tax_inc
FROM sprint3_gold.transactions_optimized t
CROSS JOIN UNNEST(t.product_ids) AS product_id
JOIN sprint3_silver.products_clean p ON product_id = p.product_id;

# S4-N3-E1 Pas 2: Crea la taula dim_transactions_flat (UNNEST) amb tax
CREATE OR REPLACE TABLE sprint3_gold.dim_transactions_flat AS
SELECT
  t.transaction_id,
  t.transaction_timestamp,
  ROUND(CAST(t.amount AS NUMERIC), 3) AS total_ticket,
  product_id AS product_sku,
  p.name AS product_name,
  ROUND(CAST(p.price AS NUMERIC), 3) AS product_price,
  `sprint3-analytics-alicia.sprint3_gold.calculate_tax`(
    CAST(p.price AS NUMERIC)
  ) AS product_price_tax_inc
FROM sprint3_gold.transactions_optimized t
CROSS JOIN UNNEST(t.product_ids) AS product_id
JOIN sprint3_silver.products_clean p ON product_id = p.product_id;

#S4-N3-E3 Pas 1: UDF càlcul tax
CREATE OR REPLACE FUNCTION
`sprint3-analytics-alicia.sprint3_gold.calculate_tax`(amount NUMERIC)
RETURNS NUMERIC
AS (
    ROUND(amount * 1.21, 3)
);








