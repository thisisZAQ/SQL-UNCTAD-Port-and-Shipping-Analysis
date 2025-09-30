-- 1. Global Trend Analysis
SELECT quarter_label,
       AVG(index_value) AS avg_global_connectivity
FROM liner_connectivity
GROUP BY quarter_label
ORDER BY quarter_label;

-- 2. Top 10 Connected Economies (latest quarter)
SELECT quarter_label, economy_label, index_value
FROM liner_connectivity
WHERE quarter_label = '2024-Q4'
ORDER BY index_value DESC
LIMIT 10;

-- 3. Volatility Analysis
SELECT economy_label,
       MAX(index_value) - MIN(index_value) AS volatility
FROM liner_connectivity
GROUP BY economy_label
ORDER BY volatility DESC
LIMIT 10;

--4. Country vs Port Level Comparison
SELECT l.economy_label,
       p.port_label,
       p.quarter_label,
       p.index_value AS port_connectivity,
       l.index_value AS country_connectivity
FROM port_liner p
JOIN liner_connectivity l
  ON p.quarter_label = l.quarter_label
 AND p.port_label LIKE l.economy_label || '%'
ORDER BY l.economy_label, p.quarter_label;

--Shock Detection (Disruption Periods)
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
       ROUND(((index_value - rolling_avg) / rolling_avg) * 100, 2) AS pct_change
FROM rolling
WHERE ((index_value - rolling_avg) / rolling_avg) * 100 < -10;

--port importance within a country
SELECT p.port_label,
       p.quarter_label,
       p.index_value,
       l.index_value AS country_index,
       ROUND((p.index_value::decimal / l.index_value) * 100, 2) AS port_share
FROM port_liner p
JOIN liner_connectivity l
  ON p.quarter_label = l.quarter_label
 AND p.port_label LIKE l.economy_label || '%'
ORDER BY p.quarter_label, port_share DESC;
