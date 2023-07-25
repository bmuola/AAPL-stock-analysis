-- Create schema and table for stock updates
CREATE SCHEMA IF NOT EXISTS trends;

CREATE TABLE IF NOT EXISTS aaplstock.trends.updates (
    Date DATE,
    Open FLOAT,
    High FLOAT,
    Low FLOAT,
    Close FLOAT,
    Adj_Close FLOAT,
    Volume FLOAT
);

-- Import data from CSV into the table
COPY aaplstock.trends.updates
FROM 'C:\Users\Ben\Downloads\archive (2)\AAPL_daily_update.csv' DELIMITER ',' CSV HEADER;

SELECT *
FROM aaplstock.trends.updates
ORDER BY Date DESC
LIMIT 10;

-- View the average volume of stock traded every month using a view
CREATE OR REPLACE VIEW volume_trend AS (
    SELECT
        TO_CHAR(Date, 'YYYY-MM') AS Month,
        AVG(Volume) AS Avg
    FROM aaplstock.trends.updates
    GROUP BY Month 
    ORDER BY Month DESC
);

-- Calculate and view Simple Moving Averages using a view
CREATE OR REPLACE VIEW SMA_Trend AS (
    SELECT
        date,
        close,
        AVG(close) OVER (ORDER BY date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS SMA
    FROM aaplstock.trends.updates
);

-- Analyze and view stock volatility by interpreting Bollinger Bands and EMA patterns using a view
CREATE OR REPLACE VIEW stock_volatility_trend AS (
    WITH ema_data AS (
        SELECT
            date,
            close,
            AVG(close) OVER (ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS ema_20_periods
        FROM aaplstock.trends.updates
    ),
    std_dev AS (
        SELECT
            date,
            close,
            STDDEV(close) OVER (ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS std_dev_20_periods
        FROM aaplstock.trends.updates
    )
    SELECT
        ed.date,
        ed.close,
        ed.ema_20_periods,
        sd.std_dev_20_periods,
        ed.ema_20_periods + 2 * sd.std_dev_20_periods AS upper_bollinger_band,
        ed.ema_20_periods - 2 * sd.std_dev_20_periods AS lower_bollinger_band
    FROM
        ema_data ed
    JOIN
        std_dev sd ON ed.date = sd.date
);

-- Calculate and view the RSI using a view

-- Step 1: Calculate Price Changes 
WITH price_changes_custom AS (
    SELECT
        date,
        close,
        LEAD(close) OVER (ORDER BY date) - close AS price_change
    FROM
        aaplstock.trends.updates
),

-- Step 2: Calculate Gains and Losses 
gains_losses_custom AS (
    SELECT
        date,
        close,
        CASE
            WHEN price_change > 0 THEN price_change
            ELSE 0
        END AS gain,
        CASE
            WHEN price_change < 0 THEN ABS(price_change)
            ELSE 0
        END AS loss
    FROM
        price_changes_custom
),

-- Step 3: Calculate Average Gains and Losses 
average_gains_losses_custom AS (
    SELECT
        date,
        close,
        AVG(gain) OVER (ORDER BY date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS avg_gain,
        AVG(loss) OVER (ORDER BY date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS avg_loss
    FROM
        gains_losses_custom
)

-- Step 4: Calculate RSI_trend (14-day RSI) 
CREATE OR REPLACE VIEW RSI_trend AS (
    SELECT
        date,
        close,
        100 - (100 / (1 + (avg_gain / avg_loss))) AS rsi_14_days
    FROM
        average_gains_losses_custom
    WHERE
        avg_loss <> 0
);
