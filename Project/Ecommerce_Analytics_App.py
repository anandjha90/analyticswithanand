# ######################################################################
# SNOWFLAKE ECOMMERCE ANALYTICS — STREAMLIT APP (in Snowflake)
# Database : ECOM_DB  |  Schema : RAW
# ######################################################################

import streamlit as st
import pandas as pd
import altair as alt
import time
from snowflake.snowpark.context import get_active_session

try:
    import plotly.express as px
    HAS_PLOTLY = True
except ImportError:
    HAS_PLOTLY = False

# ============================================================
# 0.  SESSION & CONFIG
# ============================================================
session    = get_active_session()
sf_db      = "ECOM_DB"
sf_schema  = "ECOM_DB.RAW"
FULL_TABLES = ["PRODUCTS","CUSTOMERS","STORES","SALES_CHANNELS",
               "FCT_ORDERS","FCT_INVENTORY","FCT_RETURNS"]

# ============================================================
# 1.  PAGE CONFIG & THEME TOGGLE
# ============================================================
st.set_page_config(
    page_title="🛒 ECommerce Analytics",
    page_icon="🛒",
    layout="wide",
    initial_sidebar_state="expanded"
)

# -- Theme toggle stored in session state --
if "dark_mode" not in st.session_state:
    st.session_state["dark_mode"] = False

dark = st.session_state["dark_mode"]

# Dynamic CSS for Light / Dark
BG   = "#0E1117" if dark else "#FFFFFF"
CARD = "#1E1E2E" if dark else "#F8F9FA"
TXT  = "#FAFAFA" if dark else "#212121"
ACCENT = "#00BCD4" if dark else "#1565C0"

css = f"""
<style>
.stApp {{
    background: {BG};
    color: {TXT};
}}

.metric-card {{
    background: {CARD};
    border-radius: 12px;
    padding: 20px;
    margin: 6px;
    text-align: center;
    border-left: 5px solid {ACCENT};
    box-shadow: 2px 2px 8px rgba(0,0,0,0.15);
}}

.metric-val {{
    font-size: 2rem;
    font-weight: 700;
    color: {ACCENT};
}}

.metric-label {{
    font-size: 0.85rem;
    color: #888;
    margin-top: 4px;
}}

.section-hdr {{
    background: linear-gradient(90deg,{ACCENT},#00695C);
    padding: 10px 18px;
    border-radius: 10px;
    color: #fff;
    font-size: 1.3rem;
    font-weight: 700;
    margin-bottom: 12px;
}}
</style>
"""
st.markdown(css, unsafe_allow_html=True)

# ============================================================
# 2.  SIDEBAR
# ============================================================
with st.sidebar:
    st.image("https://upload.wikimedia.org/wikipedia/commons/thumb/f/ff/Snowflake_Logo.svg/1280px-Snowflake_Logo.svg.png",
             width=180)
    st.markdown("## 🛒 ECommerce Analytics")
    st.markdown("---")

    # -- Theme toggle --
    theme_label = "☀️ Switch to Light Mode" if dark else "🌙 Switch to Dark Mode"
    if st.button(theme_label, key="theme_btn"):
        st.session_state["dark_mode"] = not dark
        st.rerun()

    # -- Auto-refresh --
    st.markdown("### ⏱ Auto-Refresh")
    auto_refresh = st.toggle("Enable Auto-Refresh", value=False)
    refresh_secs = st.slider("Refresh every (sec)", 10, 120, 30, step=10,
                              disabled=not auto_refresh)

    st.markdown("### 📅 Global Date Range")
    start_date = st.date_input("From", value=pd.to_datetime("2024-01-01"))
    end_date   = st.date_input("To",   value=pd.to_datetime("2024-12-31"))

    st.markdown("### 🏷 Category Filter")
    cats_q = session.sql("SELECT DISTINCT CATEGORY FROM ECOM_DB.RAW.PRODUCTS ORDER BY 1").collect()
    all_cats = [r[0] for r in cats_q]
    sel_cats = st.multiselect("Categories", all_cats, default=all_cats[:4])

    st.markdown("### 📡 Channel Filter")
    ch_q = session.sql("SELECT CHANNEL_ID, CHANNEL_NAME FROM ECOM_DB.RAW.SALES_CHANNELS").collect()
    ch_map = {r[1]: r[0] for r in ch_q}
    sel_ch_names = st.multiselect("Channels", list(ch_map.keys()), default=list(ch_map.keys()))
    sel_channels = [ch_map[n] for n in sel_ch_names]

    st.markdown("---")
    st.caption(f"🔗 Connected: {sf_db} | Schema: RAW")

# ── Auto-refresh loop ──────────────────────────────────────────────────────────
if auto_refresh:
    time.sleep(refresh_secs)
    st.rerun()

# ============================================================
# 3.  UTILITIES
# ============================================================
def run_query(sql, fetch=False):
    t0 = time.time()
    result = session.sql(sql)
    if fetch:
        df = result.to_pandas()
        return df, round(time.time()-t0, 3)
    result.collect()
    return None, round(time.time()-t0, 3)

def cat_filter_sql(alias=""):
    """Return a SQL fragment for category filtering.
    Pass alias (e.g. 'o') when the query involves JOINs to avoid ambiguity.
    """
    prefix = f"{alias}." if alias else ""
    if not sel_cats:
        return "1=1"
    cats_str = ", ".join([f"'{c}'" for c in sel_cats])
    return f"{prefix}CATEGORY IN ({cats_str})"

def ch_filter_sql(alias=""):
    """Return a SQL fragment for channel filtering.
    Pass alias (e.g. 'o') when the query involves JOINs to avoid ambiguity.
    """
    prefix = f"{alias}." if alias else ""
    if not sel_channels:
        return "1=1"
    chs_str = ", ".join([f"'{c}'" for c in sel_channels])
    return f"{prefix}CHANNEL_ID IN ({chs_str})"

s = str(start_date)
e = str(end_date)

# ============================================================
# 4.  TABS
# ============================================================
tabs = st.tabs([
    "📊 Dashboard",
    "🛍 Orders",
    "📦 Inventory",
    "↩️ Returns",
    "🧑‍🤝‍🧑 Customers",
    "⚡ Performance",
    "🧠 AI Analyst"
])

# ──────────────────────────────────────────────────────────────
# TAB 0: DASHBOARD — Executive KPI Overview
# ──────────────────────────────────────────────────────────────
with tabs[0]:
    st.markdown("<div class='section-hdr'>📊 Executive Dashboard — ECommerce KPIs</div>",
                unsafe_allow_html=True)

    # KPI CARDS
    kpi_sql = f"""
    SELECT
        COUNT(DISTINCT ORDER_ID)               AS TOTAL_ORDERS,
        ROUND(SUM(TOTAL_SALES)/1e6,2)          AS REVENUE_M,
        ROUND(AVG(TOTAL_SALES),2)              AS AVG_ORDER_VALUE,
        COUNT(DISTINCT CUSTOMER_ID)            AS UNIQUE_CUSTOMERS,
        SUM(CASE WHEN ORDER_STATUS='Returned'
                 THEN 1 ELSE 0 END)            AS TOTAL_RETURNS,
        ROUND(AVG(DELIVERY_DAYS),1)            AS AVG_DELIVERY_DAYS
    FROM {sf_schema}.FCT_ORDERS
    WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
      AND {cat_filter_sql()} AND {ch_filter_sql()}
    """
    df_kpi, _ = run_query(kpi_sql, fetch=True)

    if not df_kpi.empty:
        r = df_kpi.iloc[0]
        c1,c2,c3,c4,c5,c6 = st.columns(6)
        for col, val, lbl in [
            (c1, f"{int(r['TOTAL_ORDERS']):,}",      "Total Orders"),
            (c2, f"₹{r['REVENUE_M']}M",              "Revenue"),
            (c3, f"₹{r['AVG_ORDER_VALUE']:,.0f}",    "Avg Order Value"),
            (c4, f"{int(r['UNIQUE_CUSTOMERS']):,}",  "Unique Customers"),
            (c5, f"{int(r['TOTAL_RETURNS']):,}",     "Total Returns"),
            (c6, f"{r['AVG_DELIVERY_DAYS']} days",   "Avg Delivery"),
        ]:
            col.markdown(f"""<div class='metric-card'>
                <div class='metric-val'>{val}</div>
                <div class='metric-label'>{lbl}</div>
            </div>""", unsafe_allow_html=True)

    st.markdown("---")

    # Sales Trend + Category Pie
    col_left, col_right = st.columns([2,1])
    with col_left:
        st.markdown("#### 📈 Monthly Revenue Trend")
        trend_sql = f"""
        SELECT DATE_TRUNC('MONTH', ORDER_DATE)::DATE AS MONTH,
               SUM(TOTAL_SALES) AS REVENUE
        FROM {sf_schema}.FCT_ORDERS
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()} AND {ch_filter_sql()}
        GROUP BY 1 ORDER BY 1
        """
        df_trend, _ = run_query(trend_sql, fetch=True)
        if not df_trend.empty:
            df_trend['MONTH'] = pd.to_datetime(df_trend['MONTH'])
            if HAS_PLOTLY:
                fig = px.area(df_trend, x='MONTH', y='REVENUE', title='',
                              color_discrete_sequence=['#00BCD4'])
                fig.update_layout(plot_bgcolor='rgba(0,0,0,0)')
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.altair_chart(alt.Chart(df_trend)
                    .mark_area(color='#00BCD4', opacity=0.7)
                    .encode(x='MONTH:T', y='REVENUE:Q')
                    .properties(height=250), use_container_width=True)

    with col_right:
        st.markdown("#### 🏷 Revenue by Category")
        cat_sql = f"""
        SELECT CATEGORY, SUM(TOTAL_SALES) AS REVENUE
        FROM {sf_schema}.FCT_ORDERS
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()} AND {ch_filter_sql()}
        GROUP BY 1 ORDER BY 2 DESC
        """
        df_cat, _ = run_query(cat_sql, fetch=True)
        if not df_cat.empty and HAS_PLOTLY:
            fig2 = px.pie(df_cat, names='CATEGORY', values='REVENUE',
                          color_discrete_sequence=px.colors.qualitative.Set3,
                          hole=0.4)
            st.plotly_chart(fig2, use_container_width=True)
        elif not df_cat.empty:
            st.bar_chart(df_cat.set_index('CATEGORY')['REVENUE'])

    # Top Products + Channel Mix
    col_tp, col_ch = st.columns(2)
    with col_tp:
        st.markdown("#### 🏆 Top 10 Products by Revenue")
        top_sql = f"""
        SELECT PRODUCT_NAME, SUM(TOTAL_SALES) AS REVENUE
        FROM {sf_schema}.FCT_ORDERS
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()} AND {ch_filter_sql()}
        GROUP BY 1 ORDER BY 2 DESC LIMIT 10
        """
        df_top, _ = run_query(top_sql, fetch=True)
        if not df_top.empty and HAS_PLOTLY:
            fig3 = px.bar(df_top.sort_values('REVENUE'), x='REVENUE',
                          y='PRODUCT_NAME', orientation='h',
                          color='REVENUE', color_continuous_scale='Teal')
            st.plotly_chart(fig3, use_container_width=True)
        elif not df_top.empty:
            st.bar_chart(df_top.set_index('PRODUCT_NAME')['REVENUE'])

    with col_ch:
        st.markdown("#### 📡 Sales by Channel")
        ch_sql = f"""
        SELECT o.CHANNEL_ID, sc.CHANNEL_NAME,
               SUM(o.TOTAL_SALES) AS REVENUE,
               COUNT(o.ORDER_ID)  AS ORDERS
        FROM {sf_schema}.FCT_ORDERS o
        LEFT JOIN {sf_schema}.SALES_CHANNELS sc ON o.CHANNEL_ID = sc.CHANNEL_ID
        WHERE o.ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql("o")} AND {ch_filter_sql("o")}
        GROUP BY 1,2 ORDER BY 3 DESC
        """
        df_ch, _ = run_query(ch_sql, fetch=True)
        if not df_ch.empty and HAS_PLOTLY:
            fig4 = px.bar(df_ch, x='CHANNEL_NAME', y='REVENUE',
                          color='CHANNEL_NAME',
                          color_discrete_sequence=['#1565C0','#00695C','#E65100'])
            st.plotly_chart(fig4, use_container_width=True)
        elif not df_ch.empty:
            st.bar_chart(df_ch.set_index('CHANNEL_NAME')['REVENUE'])

    # State-level heatmap (using bar)
    st.markdown("#### 🗺 Revenue by State (Top 15)")
    state_sql = f"""
    SELECT STATE, SUM(TOTAL_SALES) AS REVENUE
    FROM {sf_schema}.FCT_ORDERS
    WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
      AND {cat_filter_sql()} AND {ch_filter_sql()}
    GROUP BY 1 ORDER BY 2 DESC LIMIT 15
    """
    df_state, _ = run_query(state_sql, fetch=True)
    if not df_state.empty and HAS_PLOTLY:
        fig5 = px.funnel(df_state, x='REVENUE', y='STATE',
                         color_discrete_sequence=['#2E75B6'])
        st.plotly_chart(fig5, use_container_width=True)
    elif not df_state.empty:
        st.bar_chart(df_state.set_index('STATE')['REVENUE'])

# ──────────────────────────────────────────────────────────────
# TAB 1: ORDERS — Sales Deep Dive
# ──────────────────────────────────────────────────────────────
with tabs[1]:
    st.markdown("<div class='section-hdr'>🛍 Orders — Sales Deep Dive</div>",
                unsafe_allow_html=True)

    # Sub-filters
    c1, c2, c3 = st.columns(3)
    with c1:
        status_opts = ['All','Delivered','Shipped','Pending','Cancelled','Returned']
        sel_status = st.selectbox("Order Status", status_opts)
    with c2:
        pay_opts = ['All','UPI','Credit Card','Debit Card','Net Banking','COD','Wallet']
        sel_pay  = st.selectbox("Payment Method", pay_opts)
    with c3:
        view_grain = st.selectbox("Trend Granularity", ['Daily','Weekly','Monthly'])

    status_clause = f"AND ORDER_STATUS = '{sel_status}'" if sel_status != 'All' else ''
    pay_clause    = f"AND PAYMENT_METHOD = '{sel_pay}'"   if sel_pay    != 'All' else ''
    grain_sql = {'Daily':'DAY','Weekly':'WEEK','Monthly':'MONTH'}[view_grain]

    ord_trend_sql = f"""
    SELECT DATE_TRUNC('{grain_sql}', ORDER_DATE)::DATE AS PERIOD,
           COUNT(ORDER_ID) AS ORDERS,
           SUM(TOTAL_SALES) AS REVENUE
    FROM {sf_schema}.FCT_ORDERS
    WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
      AND {cat_filter_sql()} AND {ch_filter_sql()}
      {status_clause} {pay_clause}
    GROUP BY 1 ORDER BY 1
    """
    df_ot, _ = run_query(ord_trend_sql, fetch=True)

    if not df_ot.empty:
        df_ot['PERIOD'] = pd.to_datetime(df_ot['PERIOD'])
        if HAS_PLOTLY:
            fig = px.line(df_ot, x='PERIOD', y='REVENUE',
                          title=f'{view_grain} Revenue Trend', markers=True,
                          color_discrete_sequence=['#00BCD4'])
            st.plotly_chart(fig, use_container_width=True)

    col_a, col_b = st.columns(2)
    with col_a:
        st.markdown("#### 💳 Revenue by Payment Method")
        pay_sql = f"""
        SELECT PAYMENT_METHOD, SUM(TOTAL_SALES) AS REVENUE, COUNT(*) AS CNT
        FROM {sf_schema}.FCT_ORDERS
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()} AND {ch_filter_sql()} {status_clause}
        GROUP BY 1 ORDER BY 2 DESC
        """
        df_pay, _ = run_query(pay_sql, fetch=True)
        if not df_pay.empty and HAS_PLOTLY:
            fig6 = px.bar(df_pay, x='PAYMENT_METHOD', y='REVENUE',
                          color='PAYMENT_METHOD')
            st.plotly_chart(fig6, use_container_width=True)

    with col_b:
        st.markdown("#### 📦 Order Status Breakdown")
        stat_sql = f"""
        SELECT ORDER_STATUS, COUNT(*) AS ORDERS, SUM(TOTAL_SALES) AS REVENUE
        FROM {sf_schema}.FCT_ORDERS
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()} AND {ch_filter_sql()}
        GROUP BY 1
        """
        df_stat, _ = run_query(stat_sql, fetch=True)
        if not df_stat.empty and HAS_PLOTLY:
            fig7 = px.pie(df_stat, names='ORDER_STATUS', values='ORDERS',
                          color_discrete_sequence=px.colors.qualitative.Pastel,
                          hole=0.3)
            st.plotly_chart(fig7, use_container_width=True)

    st.markdown("#### 📋 Order Details Table")
    ord_detail_sql = f"""
    SELECT ORDER_ID, ORDER_DATE, PRODUCT_NAME, CATEGORY, BRAND,
           QUANTITY, UNIT_PRICE, DISCOUNT_PCT, TOTAL_SALES,
           ORDER_STATUS, PAYMENT_METHOD, DELIVERY_DAYS,
           CITY, STATE, CHANNEL_ID
    FROM {sf_schema}.FCT_ORDERS
    WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
      AND {cat_filter_sql()} AND {ch_filter_sql()}
      {status_clause} {pay_clause}
    ORDER BY ORDER_DATE DESC LIMIT 500
    """
    df_ord_detail, _ = run_query(ord_detail_sql, fetch=True)
    st.dataframe(df_ord_detail, use_container_width=True, height=300)

    csv_data = df_ord_detail.to_csv(index=False).encode('utf-8')
    st.download_button("📥 Download Orders CSV", csv_data,
                       file_name="orders_export.csv", mime="text/csv")

# ──────────────────────────────────────────────────────────────
# TAB 2: INVENTORY
# ──────────────────────────────────────────────────────────────
with tabs[2]:
    st.markdown("<div class='section-hdr'>📦 Inventory Analytics</div>",
                unsafe_allow_html=True)

    inv_kpi_sql = f"""
    SELECT
        SUM(CLOSING_STOCK)        AS TOTAL_STOCK,
        SUM(REORDER_TRIGGERED)    AS REORDERS,
        ROUND(AVG(SHRINKAGE),2)   AS AVG_SHRINKAGE,
        SUM(PURCHASES)            AS TOTAL_PURCHASES
    FROM {sf_schema}.FCT_INVENTORY
    WHERE INVENTORY_DATE BETWEEN '{s}' AND '{e}'
    """
    df_inv_kpi, _ = run_query(inv_kpi_sql, fetch=True)
    if not df_inv_kpi.empty:
        r = df_inv_kpi.iloc[0]
        c1,c2,c3,c4 = st.columns(4)
        for col, val, lbl in [
            (c1, f"{int(r['TOTAL_STOCK']):,}",     "Total Closing Stock"),
            (c2, f"{int(r['REORDERS']):,}",         "Reorder Alerts"),
            (c3, f"{r['AVG_SHRINKAGE']}%",          "Avg Shrinkage"),
            (c4, f"{int(r['TOTAL_PURCHASES']):,}",  "Total Purchases"),
        ]:
            col.markdown(f"""<div class='metric-card'>
                <div class='metric-val'>{val}</div>
                <div class='metric-label'>{lbl}</div>
            </div>""", unsafe_allow_html=True)

    col_inv1, col_inv2 = st.columns(2)
    with col_inv1:
        st.markdown("#### 📉 Stock Trend (Opening vs Closing)")
        inv_trend_sql = f"""
        SELECT INVENTORY_DATE::DATE AS DT,
               SUM(OPENING_STOCK) AS OPENING,
               SUM(CLOSING_STOCK) AS CLOSING
        FROM {sf_schema}.FCT_INVENTORY
        WHERE INVENTORY_DATE BETWEEN '{s}' AND '{e}'
        GROUP BY 1 ORDER BY 1
        """
        df_inv_trend, _ = run_query(inv_trend_sql, fetch=True)
        if not df_inv_trend.empty and HAS_PLOTLY:
            fig8 = px.line(df_inv_trend, x='DT', y=['OPENING','CLOSING'],
                           title='Stock Levels Over Time', markers=False)
            st.plotly_chart(fig8, use_container_width=True)

    with col_inv2:
        st.markdown("#### 🔄 Reorder Alerts by Region")
        reorder_sql = f"""
        SELECT REGION_ID, SUM(REORDER_TRIGGERED) AS ALERTS
        FROM {sf_schema}.FCT_INVENTORY
        WHERE INVENTORY_DATE BETWEEN '{s}' AND '{e}'
        GROUP BY 1 ORDER BY 2 DESC
        """
        df_reorder, _ = run_query(reorder_sql, fetch=True)
        if not df_reorder.empty and HAS_PLOTLY:
            fig9 = px.bar(df_reorder, x='REGION_ID', y='ALERTS',
                          color='REGION_ID',
                          color_discrete_sequence=px.colors.qualitative.Bold)
            st.plotly_chart(fig9, use_container_width=True)

    st.markdown("#### 🔍 Product-Level Stock Explorer")
    prod_search = st.text_input("Search Product ID", placeholder="PRD0001")
    if prod_search:
        prod_inv_sql = f"""
        SELECT INVENTORY_DATE, OPENING_STOCK, PURCHASES, SALES,
               CLOSING_STOCK, SHRINKAGE, REORDER_TRIGGERED
        FROM {sf_schema}.FCT_INVENTORY
        WHERE PRODUCT_ID = '{prod_search.upper()}'
        ORDER BY INVENTORY_DATE DESC LIMIT 100
        """
        df_prod_inv, _ = run_query(prod_inv_sql, fetch=True)
        st.dataframe(df_prod_inv, use_container_width=True)

# ──────────────────────────────────────────────────────────────
# TAB 3: RETURNS
# ──────────────────────────────────────────────────────────────
with tabs[3]:
    st.markdown("<div class='section-hdr'>↩️ Returns & Refunds Analytics</div>",
                unsafe_allow_html=True)

    ret_kpi_sql = f"""
    SELECT
        COUNT(RETURN_ID)       AS TOTAL_RETURNS,
        SUM(REFUND_AMOUNT)     AS TOTAL_REFUNDS,
        COUNT(CASE WHEN RETURN_STATUS='Approved' THEN 1 END) AS APPROVED,
        COUNT(CASE WHEN RETURN_STATUS='Rejected' THEN 1 END) AS REJECTED
    FROM {sf_schema}.FCT_RETURNS
    WHERE RETURN_DATE BETWEEN '{s}' AND '{e}'
    """
    df_ret_kpi, _ = run_query(ret_kpi_sql, fetch=True)
    if not df_ret_kpi.empty:
        r = df_ret_kpi.iloc[0]
        c1,c2,c3,c4 = st.columns(4)
        for col, val, lbl in [
            (c1, f"{int(r['TOTAL_RETURNS']):,}", "Total Returns"),
            (c2, f"₹{int(r['TOTAL_REFUNDS']):,}", "Total Refunds"),
            (c3, f"{int(r['APPROVED']):,}", "Approved"),
            (c4, f"{int(r['REJECTED']):,}", "Rejected"),
        ]:
            col.markdown(f"""<div class='metric-card'>
                <div class='metric-val'>{val}</div>
                <div class='metric-label'>{lbl}</div>
            </div>""", unsafe_allow_html=True)

    col_r1, col_r2 = st.columns(2)
    with col_r1:
        st.markdown("#### ❓ Top Return Reasons")
        reason_sql = f"""
        SELECT RETURN_REASON, COUNT(*) AS CNT
        FROM {sf_schema}.FCT_RETURNS
        WHERE RETURN_DATE BETWEEN '{s}' AND '{e}'
        GROUP BY 1 ORDER BY 2 DESC
        """
        df_reason, _ = run_query(reason_sql, fetch=True)
        if not df_reason.empty and HAS_PLOTLY:
            fig10 = px.bar(df_reason, x='CNT', y='RETURN_REASON',
                           orientation='h', color='CNT',
                           color_continuous_scale='RdYlGn_r')
            st.plotly_chart(fig10, use_container_width=True)

    with col_r2:
        st.markdown("#### 📡 Returns by Channel")
        ch_ret_sql = f"""
        SELECT r.CHANNEL_ID, sc.CHANNEL_NAME,
               COUNT(r.RETURN_ID) AS RETURNS,
               SUM(r.REFUND_AMOUNT) AS REFUNDS
        FROM {sf_schema}.FCT_RETURNS r
        LEFT JOIN {sf_schema}.SALES_CHANNELS sc ON r.CHANNEL_ID = sc.CHANNEL_ID
        WHERE r.RETURN_DATE BETWEEN '{s}' AND '{e}'
        GROUP BY 1,2
        """
        df_ch_ret, _ = run_query(ch_ret_sql, fetch=True)
        if not df_ch_ret.empty and HAS_PLOTLY:
            fig11 = px.pie(df_ch_ret, names='CHANNEL_NAME', values='RETURNS',
                           color_discrete_sequence=['#1565C0','#00695C','#E65100'])
            st.plotly_chart(fig11, use_container_width=True)

    st.markdown("#### 📋 Returns Detail Table")
    ret_detail_sql = f"""
    SELECT r.RETURN_ID, r.ORDER_ID, r.RETURN_DATE, p.PRODUCT_NAME,
           r.RETURN_REASON, r.REFUND_AMOUNT, r.RETURN_STATUS, r.CHANNEL_ID
    FROM {sf_schema}.FCT_RETURNS r
    LEFT JOIN {sf_schema}.PRODUCTS p ON r.PRODUCT_ID = p.PRODUCT_ID
    WHERE r.RETURN_DATE BETWEEN '{s}' AND '{e}'
    ORDER BY r.RETURN_DATE DESC LIMIT 300
    """
    df_ret_det, _ = run_query(ret_detail_sql, fetch=True)
    st.dataframe(df_ret_det, use_container_width=True, height=280)

# ──────────────────────────────────────────────────────────────
# TAB 4: CUSTOMERS
# ──────────────────────────────────────────────────────────────
with tabs[4]:
    st.markdown("<div class='section-hdr'>🧑‍🤝‍🧑 Customer Insights</div>",
                unsafe_allow_html=True)

    cust_kpi_sql = f"""
    SELECT
        COUNT(DISTINCT c.CUSTOMER_ID)                        AS TOTAL_CUST,
        COUNT(DISTINCT CASE WHEN o.ORDER_DATE BETWEEN '{s}' AND '{e}'
                            THEN c.CUSTOMER_ID END)          AS ACTIVE_CUST,
        COUNT(DISTINCT CASE WHEN c.LOYALTY_TIER='Platinum'
                            THEN c.CUSTOMER_ID END)          AS PLATINUM,
        ROUND(AVG(o.TOTAL_SALES),2)                          AS AVG_CLV
    FROM {sf_schema}.CUSTOMERS c
    LEFT JOIN {sf_schema}.FCT_ORDERS o ON c.CUSTOMER_ID = o.CUSTOMER_ID
    """
    df_ck, _ = run_query(cust_kpi_sql, fetch=True)
    if not df_ck.empty:
        r = df_ck.iloc[0]
        c1,c2,c3,c4 = st.columns(4)
        for col, val, lbl in [
            (c1, f"{int(r['TOTAL_CUST']):,}",  "Total Customers"),
            (c2, f"{int(r['ACTIVE_CUST']):,}", "Active in Period"),
            (c3, f"{int(r['PLATINUM']):,}",    "Platinum Members"),
            (c4, f"₹{r['AVG_CLV']:,.0f}",      "Avg Customer LTV"),
        ]:
            col.markdown(f"""<div class='metric-card'>
                <div class='metric-val'>{val}</div>
                <div class='metric-label'>{lbl}</div>
            </div>""", unsafe_allow_html=True)

    col_c1, col_c2 = st.columns(2)
    with col_c1:
        st.markdown("#### 🏆 Loyalty Tier Distribution")
        tier_sql = f"""
        SELECT LOYALTY_TIER, COUNT(*) AS CNT
        FROM {sf_schema}.CUSTOMERS GROUP BY 1
        """
        df_tier, _ = run_query(tier_sql, fetch=True)
        if not df_tier.empty and HAS_PLOTLY:
            fig12 = px.pie(df_tier, names='LOYALTY_TIER', values='CNT',
                           color_discrete_sequence=['#CD7F32','#C0C0C0','#FFD700','#E5E4E2'])
            st.plotly_chart(fig12, use_container_width=True)

    with col_c2:
        st.markdown("#### 🗺 Customers by State")
        state_cust_sql = f"""
        SELECT STATE, COUNT(*) AS CUSTOMERS
        FROM {sf_schema}.CUSTOMERS GROUP BY 1 ORDER BY 2 DESC LIMIT 12
        """
        df_sc, _ = run_query(state_cust_sql, fetch=True)
        if not df_sc.empty and HAS_PLOTLY:
            fig13 = px.bar(df_sc, x='STATE', y='CUSTOMERS',
                           color='CUSTOMERS', color_continuous_scale='Blues')
            st.plotly_chart(fig13, use_container_width=True)

    st.markdown("#### 🔍 Customer 360 — Lookup")
    cust_id_input = st.text_input("Enter Customer ID", placeholder="CUS00001")
    if cust_id_input:
        c360_sql = f"""
        SELECT c.CUSTOMER_ID, c.FIRST_NAME||' '||c.LAST_NAME AS NAME,
               c.GENDER, c.CITY, c.STATE, c.LOYALTY_TIER, c.REGISTRATION_DATE,
               COUNT(o.ORDER_ID)          AS TOTAL_ORDERS,
               ROUND(SUM(o.TOTAL_SALES),2) AS LIFETIME_VALUE,
               MAX(o.ORDER_DATE)          AS LAST_ORDER
        FROM {sf_schema}.CUSTOMERS c
        LEFT JOIN {sf_schema}.FCT_ORDERS o ON c.CUSTOMER_ID = o.CUSTOMER_ID
        WHERE c.CUSTOMER_ID = '{cust_id_input.upper()}'
        GROUP BY 1,2,3,4,5,6,7
        """
        df_c360, _ = run_query(c360_sql, fetch=True)
        if not df_c360.empty:
            r = df_c360.iloc[0]
            st.success(f"👤 {r['NAME']} | {r['LOYALTY_TIER']} | {r['CITY']}, {r['STATE']}")
            st.metric("Lifetime Value", f"₹{r['LIFETIME_VALUE']:,.2f}")
            st.metric("Total Orders",   f"{int(r['TOTAL_ORDERS']):,}")
            st.metric("Last Order",     str(r['LAST_ORDER']))
        else:
            st.warning("Customer not found.")

# ──────────────────────────────────────────────────────────────
# TAB 5: PERFORMANCE (Raw vs MV)
# ──────────────────────────────────────────────────────────────
with tabs[5]:
    st.markdown("<div class='section-hdr'>⚡ Query Performance — Raw vs Materialized View</div>",
                unsafe_allow_html=True)
    st.info("Compare query execution speed between raw FCT_ORDERS table and MV_DAILY_SALES_SUMMARY.")

    if st.button("▶ Run Performance Benchmark"):
        q_raw = f"""
        SELECT ORDER_DATE::DATE AS DT, SUM(TOTAL_SALES) AS TOTAL
        FROM {sf_schema}.FCT_ORDERS
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()}
        GROUP BY 1 ORDER BY 1
        """
        q_mv = f"""
        SELECT ORDER_DATE::DATE AS DT, SUM(TOTAL_SALES) AS TOTAL
        FROM {sf_schema}.MV_DAILY_SALES_SUMMARY
        WHERE ORDER_DATE BETWEEN '{s}' AND '{e}'
          AND {cat_filter_sql()}
        GROUP BY 1 ORDER BY 1
        """
        try:
            df_raw, t_raw = run_query(q_raw, fetch=True)
        except Exception as ex:
            st.error(f"Raw query error: {ex}"); df_raw = pd.DataFrame(); t_raw = 0
        try:
            df_mv, t_mv = run_query(q_mv, fetch=True)
        except Exception as ex:
            st.warning(f"MV query error: {ex}"); df_mv = pd.DataFrame(); t_mv = 0

        st.success(f"⏱ Raw: {t_raw:.3f}s | MV: {t_mv:.3f}s | Speed Gain: {t_raw-t_mv:.3f}s")

        col_p1, col_p2 = st.columns(2)
        with col_p1:
            if not df_raw.empty:
                df_raw['DT'] = pd.to_datetime(df_raw['DT'])
                if HAS_PLOTLY:
                    fig14 = px.line(df_raw, x='DT', y='TOTAL',
                                    title=f'Raw Table ({t_raw:.3f}s)', markers=True)
                    st.plotly_chart(fig14, use_container_width=True)
        with col_p2:
            if not df_mv.empty:
                df_mv['DT'] = pd.to_datetime(df_mv['DT'])
                if HAS_PLOTLY:
                    fig15 = px.line(df_mv, x='DT', y='TOTAL',
                                    title=f'Materialized View ({t_mv:.3f}s)',
                                    markers=True,
                                    color_discrete_sequence=['#00695C'])
                    st.plotly_chart(fig15, use_container_width=True)

    # Clustering info
    st.markdown("---")
    st.markdown("### 🔬 Table Clustering Information")
    for tbl in ['FCT_ORDERS','FCT_INVENTORY','FCT_RETURNS']:
        if st.button(f"📊 Check Clustering: {tbl}"):
            try:
                df_cl, _ = run_query(
                    f"SELECT SYSTEM$CLUSTERING_INFORMATION('{sf_schema}.{tbl}')",
                    fetch=True)
                st.json(df_cl.iloc[0,0])
            except Exception as ex:
                st.error(str(ex))

# ──────────────────────────────────────────────────────────────
# TAB 6: AI ANALYST — Cortex AI
# ──────────────────────────────────────────────────────────────
with tabs[6]:
    st.markdown("<div class='section-hdr'>🧠 AI Analyst — Powered by Snowflake Cortex AI</div>",
                unsafe_allow_html=True)
    st.info("Cortex AI summarizes ECommerce datasets, generates insights, visual recommendations, and proposes KPIs.")

    # Table selection
    st.markdown("### 🔍 Select Tables for AI Analysis")
    selected_tables = st.multiselect(
        "Choose tables to analyze:",
        FULL_TABLES,
        default=["FCT_ORDERS","FCT_INVENTORY","FCT_RETURNS"]
    )

    # Cortex Summary
    if st.button("🚀 Run Cortex AI Analysis"):
        if not selected_tables:
            st.warning("Please select at least one table.")
        else:
            with st.spinner("🧠 Analyzing datasets with Cortex AI..."):
                try:
                    table_meta = []
                    for tbl in selected_tables:
                        try:
                            df_meta, _ = run_query(
                                f"SHOW COLUMNS IN {sf_schema}.{tbl};", fetch=True)
                            if not df_meta.empty:
                                cols = ", ".join(df_meta['column_name'].astype(str).tolist())
                                table_meta.append(f"Table {tbl}: Columns - {cols}")
                        except Exception as ex:
                            st.warning(f"Metadata error for {tbl}: {ex}")

                    if not table_meta:
                        st.error("No metadata found."); st.stop()

                    prompt = (
                        "You are a Snowflake Cortex AI data analyst. "
                        "Analyze the following ECommerce dataset tables. "
                        "For each table, summarize attribute meanings, relationships, "
                        "and business implications. "
                        "Then recommend visualizations and KPIs for an executive dashboard.\n\n"
                        + "\n".join(table_meta)
                    )
                    cortex_sql = f"""
                    SELECT SNOWFLAKE.CORTEX.COMPLETE(
                        'mistral-large',
                        '{prompt}'
                    ) AS ANALYSIS;
                    """
                    df_ai, _ = run_query(cortex_sql, fetch=True)
                    if not df_ai.empty:
                        st.success("✅ Cortex AI Summary Complete")
                        st.markdown("### 🧾 AI Summary Report")
                        st.markdown(df_ai.iloc[0,0])
                    else:
                        st.warning("No summary returned from Cortex.")
                except Exception as ex:
                    st.error(f"Cortex AI failed: {ex}")

    st.markdown("---")

    # Q&A
    st.markdown("<h3 style='color:#00BCD4;'>💬 Ask Your Data — AI Q&A Assistant</h3>",
                unsafe_allow_html=True)
    st.caption("Type your analytical question and click Ask AI. "
               "Cortex AI will analyze your ECommerce data and respond with insights.")

    user_query = st.text_input(
        "💬 Your question:",
        key="ai_query_textbox",
        placeholder="e.g. Which category had the highest return rate last quarter?"
    )
    if st.button("🤖 Ask AI"):
        query = (st.session_state.get("ai_query_textbox") or "").strip()
        if not query:
            st.warning("Please type a question first.")
        else:
            with st.spinner("🔍 Querying Cortex AI..."):
                try:
                    meta_lines = []
                    for tbl in selected_tables:
                        try:
                            df_meta, _ = run_query(
                                f"SHOW COLUMNS IN {sf_schema}.{tbl};", fetch=True)
                            if not df_meta.empty:
                                cols = ", ".join(df_meta['column_name'].astype(str).tolist())
                                meta_lines.append(f"{tbl}: {cols}")
                        except Exception:
                            pass
                    tbl_info = ("\n\nTable metadata:\n" +
                                "\n".join(meta_lines)) if meta_lines else ""
                    prompt_qna = (
                        "You are a Snowflake Cortex AI analyst for an ECommerce platform. "
                        "Answer using Orders, Inventory, Returns, Customers data. "
                        "Include reasoning, metrics, and runnable SQL when applicable.\n\n"
                        f"User Question: {query}{tbl_info}"
                    )
                    safe_p = prompt_qna.replace("'","''").replace("\\","\\\\").replace("\n","\\n")
                    qna_sql = f"""
                    SELECT SNOWFLAKE.CORTEX.COMPLETE(
                        'mistral-large', '{safe_p}'
                    ) AS AI_RESPONSE;
                    """
                    df_qna, _ = run_query(qna_sql, fetch=True)
                    if not df_qna.empty:
                        ai_ans = df_qna.iloc[0,0]
                        st.success("✅ Answer Generated")
                        st.markdown("### 🧾 AI Analytical Response")
                        st.markdown(ai_ans)
                        import re
                        sql_matches = re.findall(r"(?i)(SELECT[\s\S]*?;)", ai_ans)
                        if sql_matches:
                            st.markdown("### 🧮 Suggested SQL")
                            st.code(sql_matches[0], language="sql")
                        else:
                            st.info("No explicit SQL found. Try: 'Show SQL for this metric.'")
                    else:
                        st.warning("No response from Cortex AI.")
                except Exception as ex:
                    st.error(f"Error: {ex}")

    st.markdown("---")

    # Visual Insights
    st.markdown("### 📊 Cortex AI — Visual Insights")
    sel_vis_tbl = st.selectbox("Table for AI visual exploration:",
                               ["FCT_ORDERS","FCT_INVENTORY","FCT_RETURNS"])
    if st.button("📈 Generate AI Visual Insights", key="gen_vis"):
        with st.spinner("Analyzing with Cortex AI..."):
            try:
                p_vis = (
                    "Analyze this ECommerce table and suggest 2-3 visualizations. "
                    "Focus on trends, correlations, and actionable metrics. "
                    "Output each as a short markdown summary with chart type."
                    f" Table: {sel_vis_tbl}"
                )
                safe_pv = p_vis.replace("'","''").replace("\n","\\n")
                df_vis, _ = run_query(
                    f"SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large','{safe_pv}') AS V;",
                    fetch=True)
                if not df_vis.empty:
                    st.success("✅ Cortex Visual Insights Ready")
                    st.markdown("### 🧭 Suggested Visualizations")
                    st.markdown(df_vis.iloc[0,0])
                else:
                    st.warning("No visual recommendations returned.")
            except Exception as ex:
                st.error(f"Error: {ex}")

    # KPI Recommendations
    st.markdown("---")
    st.markdown("### 💡 Cortex AI — Suggested KPIs")
    if st.button("💼 Generate KPI Recommendations", key="gen_kpi"):
        with st.spinner("Generating KPI suggestions..."):
            try:
                p_kpi = (
                    "You are an AI analytics expert for an ECommerce company. "
                    "Based on orders, inventory, returns, and customer data, "
                    "suggest 6-8 actionable KPIs with short business rationale. "
                    "Each KPI must include a formula or definition implementable in SQL."
                )
                safe_pk = p_kpi.replace("'","''").replace("\n","\\n")
                df_kpi_ai, _ = run_query(
                    f"SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large','{safe_pk}') AS K;",
                    fetch=True)
                if not df_kpi_ai.empty:
                    st.success("✅ KPI Recommendations Generated")
                    st.markdown("### 📊 Recommended KPIs")
                    st.markdown(df_kpi_ai.iloc[0,0])
                else:
                    st.warning("No KPI suggestions returned.")
            except Exception as ex:
                st.error(f"Error: {ex}")

    st.markdown("---")
    st.caption("🧠 Powered by Snowflake Cortex AI | Model: mistral-large | ECommerce Analytics")

# ============================================================
# FOOTER
# ============================================================
st.markdown("---")
st.caption("🛒 ECommerce Analytics | Built with ❤️ using Snowflake, Streamlit & Python | © 2025 Trainer Demo")
