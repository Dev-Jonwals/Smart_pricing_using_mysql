# 🧠 Smart Pricing Optimization Tool (SQL + Streamlit)

This project is a data-driven pricing optimization engine designed for quick commerce platforms (like Blinkit, Zepto, Swiggy Instamart). It helps optimize discounting by analyzing user behavior, product margins, and conversion patterns — all built using MySQL (or PlanetScale), SQL views, and Streamlit for interactive visualization.

---

## 🚀 Business Context

Quick commerce operates on thin margins and fast delivery. Random discounting can burn contribution margins. This tool helps:

- 🎯 Offer the right discount to the right user cohort (price-sensitive vs loyal)
- 📉 Avoid over-discounting where users would've purchased anyway
- 🧾 Identify loss leaders (popular but low-margin SKUs)
- 📈 Simulate discount changes on conversion and margins

---

## 🛠 Tech Stack

| Component          | Description                                       |
|--------------------|---------------------------------------------------|
| MySQL / PlanetScale| Backend SQL engine for all transformations        |
| Streamlit          | Frontend dashboard and interactivity              |
| Pandas             | For running SQL queries and plotting              |

---

## 📊 Schema Overview

Tables:

- users (city, tier, signup date, loyalty)
- products (category, base/cost price)
- transactions (discount, price, purchased flag)

SQL Views:

- user_metrics: orders, recency, AOV, tenure
- user_loyalty_cohort: segments users into Low / Mid / High loyalty
- discount_performance: conversion & margin vs discount per cohort
- best_discount_recommendation: optimal discount meeting conversion + margin threshold

---

## ✨ Features

- ✅ Cohort-based analysis (City Tier × Loyalty Segment)
- ✅ Real-time product performance visualization
- ✅ Conversion Rate vs Discount chart
- ✅ Margin % vs Discount chart
- ✅ Discount recommendation engine (SQL-driven)
- ✅ Lightweight (no ML needed)

---

## 📂 File Structure

| File                  | Description                                        |
|-----------------------|----------------------------------------------------|
| schema.sql            | Full SQL schema, views, and cohort logic           |
| app.py                | Streamlit frontend app                             |
| users_large.csv       | Sample user data                                   |
| products.csv          | Sample product data                                |
| transactions.csv      | Sample transactions with discount flags            |

---

## 📷 Sample Dashboard Preview

1. Select City Tier and Loyalty Segment from dropdowns  
2. Choose a product  
3. View charts:
   - 📈 Conversion Rate vs Discount %
   - 💰 Average Margin % vs Discount %
4. See optimal discount recommendation based on SQL logic

---

## 💡 Example Insight

> For Tier-1 Mid-Loyalty users buying “Amul Butter”, conversion jumps to 75% at 10% discount — with 20% margin. Thus, 10% is the optimal discount.

---

## 🧪 How to Run

1. Import schema.sql into your MySQL or PlanetScale database
2. Load sample CSVs into the corresponding tables
3. Update your database connection details in app.py
4. Start the Streamlit app:

```bash
streamlit run app.py
