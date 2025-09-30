-- ============================================================
-- PostgreSQL Script: Liner Connectivity & Port Connectivity
-- Purpose: Schema + Analysis Queries for Global Shipping Data
-- ============================================================

-- ==================
-- 1. Create Tables
-- ==================
DROP TABLE IF EXISTS liner_connectivity;
DROP TABLE IF EXISTS port_liner;

CREATE TABLE liner_connectivity (
    economy_label TEXT,
    quarter_label TEXT,
    index_value NUMERIC
);

CREATE TABLE port_liner (
    port_label TEXT,
    quarter_label TEXT,
    index_value NUMERIC
);

-- ==================
-- 2. Analysis Queries
-- ==================

-- (A) Global Trends: Average connectivity over time
-- Shows how liner connectivity has evolved globally
SELECT quarter_label,
       AVG(index_value) AS avg_global_connectivity
FROM liner_connectivity
GROUP BY quarter_label
ORDER BY quarter_label;

-- (B) Top 10 Connected Economies (Latest Quarter)
-- Replace '2024-Q4' with the latest available quarter
SELECT quarter_label, economy_label, index_value
FROM liner_connectivity
WHERE quarter_label = '2024-Q4'
ORDER BY index_value DESC
LIMIT 10;

-- (C) Most Volatile Economies
-- Measures which economies have had the biggest swings
SELECT economy_label,
       MAX(index_value) - MIN(index_value) AS volatility
FROM liner_connectivity
GROUP BY economy_label
ORDER BY volatility DESC
LIMIT 10;

-- (D) Port vs Country Correlation (Example: match ports to their economy)
-- This query joins port-level and country-level data on the same quarter
-- and allows analysis of whether ports track country-level performance
SELECT p.port_label,
       l.economy_label,
       p.quarter_label,
       p.index_value AS port_index,
       l.index_value AS country_index
FROM port_liner p
JOIN liner_connectivity l
  ON p.quarter_label = l.quarter_label
 AND p.port_label LIKE l.economy_label || '%'
ORDER BY l.economy_label, p.quarter_label;

-- (E) Quarterly Disruptions
-- A disruption is defined as a drop >10% below the rolling average
WITH rolling AS (
    SELECT economy_label,
           quarter_label,
           index_value,
           AVG(index_value) OVER (
               PARTITION BY economy_label
               ORDER BY quarter_label
               ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
           ) AS rolling_avg
    FROM liner_connectivity
)
SELECT economy_label,
       quarter_label,
       index_value,
       rolling_avg,
       (index_value - rolling_avg) / rolling_avg * 100 AS pct_change,
       CASE WHEN (index_value - rolling_avg) / rolling_avg * 100 < -10
            THEN TRUE ELSE FALSE END AS is_disruption
FROM rolling
ORDER BY economy_label, quarter_label;

-- (F) Global Disruptions Count Over Time
-- Counts how many economies faced disruptions each quarter
WITH rolling AS (
    SELECT economy_label,
           quarter_label,
           index_value,
           AVG(index_value) OVER (
               PARTITION BY economy_label
               ORDER BY quarter_label
               ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
           ) AS rolling_avg
    FROM liner_connectivity
),
disruptions AS (
    SELECT quarter_label,
           CASE WHEN (index_value - rolling_avg) / rolling_avg * 100 < -10
                THEN 1 ELSE 0 END AS is_disruption
    FROM rolling
)
SELECT quarter_label,
       SUM(is_disruption) AS total_disruptions
FROM disruptions
GROUP BY quarter_label
ORDER BY quarter_label;

-- ==================
-- End of Script
-- ==================

