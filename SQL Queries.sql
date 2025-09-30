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

