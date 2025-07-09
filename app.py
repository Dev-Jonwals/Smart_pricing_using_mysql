import streamlit as st
import pandas as pd
import mysql.connector

# --- DB Connection ---
@st.cache_resource
@st.cache_resource
def get_connection():
    try:
        conn = mysql.connector.connect(
            host="sql12.freesqldatabase.com",
            user="sql12789127",
            password="68d3WKY3rv",
            database="sql12789127",
            port=3306
        )
        return conn
    except mysql.connector.Error as e:
        st.error(f"❌ Connection failed: {e}")
        return None

st.title("🧠 Smart Pricing Optimization Tool")
st.markdown("Analyze discount sensitivity, conversion, and margin by user cohort.")

city_tier = st.selectbox("Select City Tier", ["Tier-1", "Tier-2", "Tier-3"])
loyalty = st.selectbox("Select Loyalty Segment", ["Low", "Mid", "High"])

product_df = pd.read_sql(f"""
    SELECT DISTINCT product_id, product_name 
    FROM discount_performance
    WHERE city_tier = '{city_tier}' AND loyalty_segment = '{loyalty}'
""", conn)

product_row = st.selectbox("Select Product", product_df['product_name'].tolist())

selected_product_id = product_df[product_df['product_name'] == product_row]['product_id'].values[0]

performance_df = pd.read_sql(f"""
    SELECT discount_percent, conversion_rate, avg_margin_pct
    FROM discount_performance
    WHERE product_id = '{selected_product_id}' AND city_tier = '{city_tier}' AND loyalty_segment = '{loyalty}'
    ORDER BY discount_percent
""", conn)

st.subheader("📈 Conversion Rate vs Discount")
st.line_chart(performance_df.set_index("discount_percent")["conversion_rate"])

st.subheader("💰 Margin % vs Discount")
st.line_chart(performance_df.set_index("discount_percent")["avg_margin_pct"])

rec = pd.read_sql(f"""
    SELECT discount_percent
    FROM best_discount_recommendation
    WHERE product_id = '{selected_product_id}' AND city_tier = '{city_tier}' AND loyalty_segment = '{loyalty}'
""", conn)

if not rec.empty:
    st.success(f"✅ Recommended Discount: **{rec.iloc[0]['discount_percent']}%**")
else:
    st.warning("⚠️ No discount meets both conversion and margin thresholds.")
