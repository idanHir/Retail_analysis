import os
from pathlib import Path
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

st.set_page_config(page_title="Retail SQL Analytics Dashboard", layout="wide")

# =========================
# Configuration
# =========================

DEFAULT_DATA_DIR = r"../retail"

EXPECTED_FILES = {
    "q2_monthly_sales": "q2_monthly_sales.csv",
    "q7_segment_analysis": "q7_segment_analysis.csv",
    "q5_top_stores_quarter": "q5_top_stores_quarter.csv",
    "q9_macro_grid": "q9_macro_grid.csv",
    "q10_store_summary": "q10_store_summary.csv",
}

st.title("Retail SQL Analytics Dashboard")
st.caption("Built from PostgreSQL query outputs exported as CSV files.")
data_dir = DEFAULT_DATA_DIR

def load_csvs(folder: str):
    folder_path = Path(folder)
    missing = []
    dfs = {}
    for key, fname in EXPECTED_FILES.items():
        fpath = folder_path / fname
        if not fpath.exists():
            missing.append(str(fpath))
        else:
            dfs[key] = pd.read_csv(fpath)
    return dfs, missing


def add_missing_columns_message(df_name, cols, df):
    missing = [c for c in cols if c not in df.columns]
    if missing:
        st.warning(f"{df_name} is missing expected columns: {missing}")
        return False
    return True


def normalize_q2(df):
    if 'month' in df.columns:
        df['month'] = pd.to_datetime(df['month'])
    return df


def normalize_q5(df):
    if 'year_quarter' not in df.columns:
        if 'year' in df.columns and 'quarter' in df.columns:
            df['year_quarter'] = df['year'].astype(str) + ' Q' + df['quarter'].astype(str)
    if 'year_quarter_sort' not in df.columns:
        if 'year' in df.columns and 'quarter' in df.columns:
            df['year_quarter_sort'] = df['year'] * 10 + df['quarter']
    return df


def normalize_q9(df):
    order_map = {'low': 1, 'medium': 2, 'high': 3}
    if 'cpi_bucket' in df.columns:
        df['cpi_bucket_order'] = df['cpi_bucket'].map(order_map)
    if 'unemp_bucket' in df.columns:
        df['unemp_bucket_order'] = df['unemp_bucket'].map(order_map)
    return df


def style_q10(df):
    numeric_cols = [c for c in ['total_sales', 'avg_weekly_sales', 'avg_holiday_sales', 'avg_non_holiday_sales', 'holiday_diff', 'holiday_pct_lift', 'volatility'] if c in df.columns]
    styled = df.copy()
    for c in numeric_cols:
        styled[c] = pd.to_numeric(styled[c], errors='coerce')
    cols_to_show = [c for c in ['sales_rank', 'store_id', 'total_sales', 'avg_weekly_sales', 'avg_holiday_sales', 'avg_non_holiday_sales', 'holiday_pct_lift', 'volatility'] if c in styled.columns]
    return styled[cols_to_show]

csvs, missing_files = load_csvs(data_dir)

if missing_files:
    st.error("Some expected files were not found. Update the folder path or file names.")
    for mf in missing_files:
        st.write(f"- {mf}")
    st.stop()

q2 = normalize_q2(csvs['q2_monthly_sales'])
q7 = csvs['q7_segment_analysis']
q5 = normalize_q5(csvs['q5_top_stores_quarter'])
q9 = normalize_q9(csvs['q9_macro_grid'])
q10 = csvs['q10_store_summary']

# =========================
# Sidebar filters
# =========================
with st.sidebar:
    st.header("Filters")
    selected_store = None
    if 'store_id' in q10.columns:
        store_options = ['All'] + sorted(q10['store_id'].dropna().astype(str).unique().tolist(), key=lambda x: int(x) if x.isdigit() else x)
        selected_store = st.selectbox("Store", store_options)
    selected_yq = None
    if 'year_quarter' in q5.columns:
        yq_options = q5[['year_quarter']].drop_duplicates().copy()
        if 'year_quarter_sort' in q5.columns:
            yq_options = q5[['year_quarter', 'year_quarter_sort']].drop_duplicates().sort_values('year_quarter_sort')
            yq_options = yq_options['year_quarter'].tolist()
        else:
            yq_options = sorted(q5['year_quarter'].dropna().unique().tolist())
        selected_yq = st.selectbox("Year-Quarter", yq_options)

# =========================
# KPI Row from Q10
# =========================
st.subheader("Executive summary")
q10_view = q10.copy()
if selected_store and selected_store != 'All' and 'store_id' in q10_view.columns:
    q10_view = q10_view[q10_view['store_id'].astype(str) == selected_store]

if len(q10_view) == 1:
    row = q10_view.iloc[0]
    c1, c2, c3, c4 = st.columns(4)
    if 'total_sales' in q10_view.columns:
        c1.metric("Total Sales", f"{row['total_sales']:,.0f}")
    if 'avg_weekly_sales' in q10_view.columns:
        c2.metric("Avg Weekly Sales", f"{row['avg_weekly_sales']:,.0f}")
    if 'volatility' in q10_view.columns:
        c3.metric("Volatility (SD)", f"{row['volatility']:,.0f}")
    if 'holiday_pct_lift' in q10_view.columns:
        c4.metric("Holiday % Lift", f"{row['holiday_pct_lift']*100:,.1f}%")
else:
    c1, c2, c3, c4 = st.columns(4)
    if 'total_sales' in q10.columns:
        c1.metric("Total Sales (All Stores)", f"{q10['total_sales'].sum():,.0f}")
    if 'avg_weekly_sales' in q10.columns:
        c2.metric("Mean of Store Avg Weekly Sales", f"{q10['avg_weekly_sales'].mean():,.0f}")
    if 'volatility' in q10.columns:
        c3.metric("Mean Volatility", f"{q10['volatility'].mean():,.0f}")
    if 'holiday_pct_lift' in q10.columns:
        c4.metric("Mean Holiday % Lift", f"{q10['holiday_pct_lift'].mean()*100:,.1f}%")

# =========================
# Main visuals
# =========================
Q2_k_top = 15
left, right = st.columns((1.4, 1))

with left:
    st.markdown(f"Monthly sales trend top {Q2_k_top} stores")
    if add_missing_columns_message('q2_monthly_sales', ['store_id', 'month', 'monthly_sales'], q2):
        q2_plot = q2.copy()
        if selected_store and selected_store != 'All':
            q2_plot = q2_plot[q2_plot['store_id'].astype(str) == selected_store]
        else:
            top_stores = (
                q10.sort_values('total_sales', ascending=False)['store_id'].astype(str).head(Q2_k_top).tolist()
                if 'total_sales' in q10.columns and 'store_id' in q10.columns else []
            )
            if top_stores:
                q2_plot = q2_plot[q2_plot['store_id'].astype(str).isin(top_stores)]
        fig_q2 = px.line(
            q2_plot,
            x='month',
            y='monthly_sales',
            color=q2_plot['store_id'].astype(str),
            markers=True,
            labels={'color': 'Store ID', 'monthly_sales': 'Monthly Sales', 'month': 'Month'}
        )
        fig_q2.update_layout(legend_title_text='Store ID', margin=dict(l=10, r=10, t=20, b=10))
        st.plotly_chart(fig_q2, use_container_width=True)

with right:
    st.markdown("###Top 3 stores by selected quarter")
    if add_missing_columns_message('q5_top_stores_quarter', ['store_id', 'total_sales'], q5):
        q5_plot = q5.copy()
        if selected_yq and 'year_quarter' in q5_plot.columns:
            q5_plot = q5_plot[q5_plot['year_quarter'] == selected_yq]
        if 'rank' in q5_plot.columns:
            q5_plot = q5_plot[q5_plot['rank'] <= 3]
        fig_q5 = px.bar(
            q5_plot.sort_values('total_sales', ascending=True),
            x='total_sales',
            y=q5_plot['store_id'].astype(str),
            orientation='h',
            text='total_sales',
            labels={'y': 'Store ID', 'total_sales': 'Quarterly Sales'}
        )
        fig_q5.update_traces(texttemplate='%{text:,.0f}', textposition='outside')
        fig_q5.update_layout(showlegend=False, margin=dict(l=10, r=10, t=20, b=10))
        st.plotly_chart(fig_q5, use_container_width=True)

left2, right2 = st.columns((1, 1.2))

with left2:
    st.markdown("Holiday / promo impact by store size")

    required_cols = ['size_segment', 'avg_promo_sales', 'avg_non_promo_sales']
    if all(col in q7.columns for col in required_cols):
        q7_plot = q7.copy()

        size_order = ['small', 'medium', 'large']
        q7_plot['size_segment'] = pd.Categorical(
            q7_plot['size_segment'],
            categories=size_order,
            ordered=True
        )
        q7_plot = q7_plot.sort_values('size_segment')

        q7_long = q7_plot.melt(
            id_vars=['size_segment'],
            value_vars=['avg_promo_sales', 'avg_non_promo_sales'],
            var_name='week_type',
            value_name='avg_sales'
        )

        q7_long['week_type'] = q7_long['week_type'].map({
            'avg_promo_sales': 'Holiday / promo weeks',
            'avg_non_promo_sales': 'Non-holiday / non-promo weeks'
        })

        if 'pct_lift' in q7_plot.columns:
            q7_long = q7_long.merge(
                q7_plot[['size_segment', 'pct_lift', 'diff']],
                on='size_segment',
                how='left'
            )

        fig_q7 = px.bar(
            q7_long,
            x='size_segment',
            y='avg_sales',
            color='week_type',
            barmode='group',
            category_orders={'size_segment': size_order},
            labels={
                'size_segment': 'Store Size Segment',
                'avg_sales': 'Average Weekly Sales',
                'week_type': 'Week Type'
            },
            title=None,
            hover_data={
                'size_segment': True,
                'avg_sales': ':.0f',
                'pct_lift': ':.2%' if 'pct_lift' in q7_long.columns else False,
                'diff': ':.0f' if 'diff' in q7_long.columns else False
            }
        )

        fig_q7.update_layout(
            margin=dict(l=10, r=10, t=20, b=10),
            legend_title_text='',
            xaxis_title='Store Size Segment',
            yaxis_title='Average Weekly Sales'
        )

        st.plotly_chart(fig_q7, use_container_width=True)

        if 'pct_lift' in q7_plot.columns:
            st.markdown("**Holiday / promo lift by size segment**")
            fig_q7_lift = px.bar(
                q7_plot,
                x='size_segment',
                y='pct_lift',
                category_orders={'size_segment': size_order},
                text='pct_lift',
                labels={
                    'size_segment': 'Store Size Segment',
                    'pct_lift': 'Percentage Lift'
                }
            )

            fig_q7_lift.update_traces(
                texttemplate='%{text:.1%}',
                textposition='outside',
                marker_color='#2E8B57'
            )

            fig_q7_lift.update_layout(
                margin=dict(l=10, r=10, t=10, b=10),
                xaxis_title='Store Size Segment',
                yaxis_title='Percentage Lift'
            )

            st.plotly_chart(fig_q7_lift, use_container_width=True)

    else:
        st.warning(
            "q3_promo_impact.csv should include: "
            "size_segment, avg_promo_sales, avg_non_promo_sales, and optionally diff, pct_lift."
        )
with right2:
    st.markdown("CPI / unemployment grid of average weekly sales")
    if add_missing_columns_message('q9_macro_grid', ['cpi_bucket', 'unemp_bucket', 'avg_weekly_sales'], q9):
        q9_plot = q9.copy()
        if 'cpi_bucket_order' in q9_plot.columns:
            q9_plot = q9_plot.sort_values(['cpi_bucket_order', 'unemp_bucket_order'])
        pivot = q9_plot.pivot(index='cpi_bucket', columns='unemp_bucket', values='avg_weekly_sales')
        desired_order = ['low', 'medium', 'high']
        pivot = pivot.reindex(index=[x for x in desired_order if x in pivot.index], columns=[x for x in desired_order if x in pivot.columns])
        fig_q9 = go.Figure(data=go.Heatmap(
            z=pivot.values,
            x=list(pivot.columns),
            y=list(pivot.index),
            text=[[f"{v:,.0f}" if pd.notna(v) else '' for v in row] for row in pivot.values],
            texttemplate="%{text}",
            colorscale='Blues'
        ))
        fig_q9.update_layout(
            xaxis_title='Unemployment Bucket',
            yaxis_title='CPI Bucket',
            margin=dict(l=10, r=10, t=20, b=10)
        )
        st.plotly_chart(fig_q9, use_container_width=True)

st.markdown("Store summary table")
q10_table = style_q10(q10)
if selected_store and selected_store != 'All' and 'store_id' in q10_table.columns:
    q10_table = q10_table[q10_table['store_id'].astype(str) == selected_store]
if 'sales_rank' in q10_table.columns:
    q10_table = q10_table.sort_values('sales_rank')

styled = q10_table.style
if 'holiday_pct_lift' in q10_table.columns:
    styled = styled.background_gradient(subset=['holiday_pct_lift'], cmap='YlGn')
if 'volatility' in q10_table.columns:
    styled = styled.background_gradient(subset=['volatility'], cmap='OrRd')

st.dataframe(styled, use_container_width=True)

with st.expander("Expected CSV schemas"):
    st.markdown(
        """
**q2_monthly_sales.csv**
- `store_id`, `month`, `monthly_sales`

**q7_segment_analysis.csv**
- `size_segment`, `avg_promo_sales`, `avg_non_promo_sales`, `diff`, `pct_lift`

**q5_top_stores_quarter.csv**
- `store_id`, `year`, `quarter`, `total_sales`, `rank`
- optional: `year_quarter`, `year_quarter_sort`

**q9_macro_grid.csv**
- `cpi_bucket`, `unemp_bucket`, `avg_weekly_sales`, optional `weeks_count`

**q10_store_summary.csv**
- `store_id`, `total_sales`, `avg_weekly_sales`, `volatility`, `sales_rank`,
  `avg_holiday_sales`, `avg_non_holiday_sales`, `holiday_diff`, `holiday_pct_lift`
        """
    )

st.caption("Tip: run with `streamlit run retail_dashboard.py`")