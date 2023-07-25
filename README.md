![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)
[![View My Profile](https://img.shields.io/badge/View-My_Profile-green?logo=GitHub)](https://github.com/bmuola)
[![View Repositories](https://img.shields.io/badge/View-My_Repositories-blue?logo=GitHub)](https://github.com/bmuola?tab=repositories)

# AAPL Stock Analysis

> 
## 📕 **Table of contents**
<!--ts-->
* 🛠️ [Overview](#️-overview)
* 🚀 [Solutions](#-solutions).

## 🛠️ Overview
 1. To see the average volume of stocks traded every month.
 2. To view the simple moving averages.
 3. To analyze stock volatility.
 4. To analyze the RSI.
    
---
## 🚀 Solutions

![Question 1](https://img.shields.io/badge/Question-1-971901)

**Average volume of stocks traded every month.**
 ```sql
CREATE OR REPLACE VIEW volume_trend AS (
    SELECT
        TO_CHAR(Date, 'YYYY-MM') AS Month,
        AVG(Volume) AS Avg
    FROM aaplstock.trends.updates
    GROUP BY Month 
    ORDER BY Month DESC
);
```
**Output:**

<p align="center">
<img src="Data-Overview/POWER BI AAPL-4.png" width=80% height=80%>

![Question 2](https://img.shields.io/badge/Question-2-971901)

**View Simple Moving Averages.**
 ```sql
CREATE OR REPLACE VIEW SMA_Trend AS (
    SELECT
        date,
        close,
        AVG(close) OVER (ORDER BY date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS SMA
    FROM aaplstock.trends.updates
);
```
**Output:**

<p align="center">
<img src="Data-Overview/POWER BI AAPL-2.png" width=80% height=80%>

![Question 3](https://img.shields.io/badge/Question-3-971901)

**Analyze and view stock volatility.**
 ```sql
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
```
**Output:**

<p align="center">
<img src="Data-Overview/POWER BI AAPL-3.png" width=80% height=80%>

![Question 4](https://img.shields.io/badge/Question-4-971901)

**Calculate and view the RSI.**
 ```sql

-- Step 1: Calculate Price Changes --
WITH price_changes_custom AS (
    SELECT
        date,
        close,
        LEAD(close) OVER (ORDER BY date) - close AS price_change
    FROM
        aaplstock.trends.updates
),

-- Step 2: Calculate Gains and Losses --
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

-- Step 3: Calculate Average Gains and Losses --
average_gains_losses_custom AS (
    SELECT
        date,
        close,
        AVG(gain) OVER (ORDER BY date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS avg_gain,
        AVG(loss) OVER (ORDER BY date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS avg_loss
    FROM
        gains_losses_custom
)

-- Step 4: Calculate RSI_trend (RSI) --
CREATE OR REPLACE VIEW RSI_trend AS (
    SELECT
        date,
        close,
        100 - (100 / (1 + (avg_gain / avg_loss))) AS rsi
    FROM
        average_gains_losses_custom
    WHERE
        avg_loss <> 0
);

```
**Output:**

<p align="center">
<img src="Data-Overview/POWER BI AAPL-1.png" width=80% height=80%>









