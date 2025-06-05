# -*- coding: utf-8 -*-

import streamlit as st
import pandas as pd
import plotly.express as px
import matplotlib.pyplot as plt
import altair as alt
import pycountry

st.set_page_config(
    page_title="Global Port Liner Connectivity Dashboard",
    page_icon="🚢",
    layout="wide",
    initial_sidebar_state="expanded")

alt.themes.enable("dark")
st.title("Global Port Liner Connectivity Dashboard",)
@st.cache_data
def load_data():
  port_liner = pd.read_csv('/workspaces/Port-Dashboard/liner_connectivity.csv')
  df_liner = pd.read_csv('/workspaces/Port-Dashboard/port_liner.csv')
  return port_liner, df_liner
df_liner, port_liner = load_data()

df_liner['quarter_label'] = pd.to_datetime(df_liner['quarter_label'].str.replace(r'(Q\d) (\d+)', r'\2-\1'), errors='coerce')
port_liner['quarter_label'] = pd.to_datetime(port_liner['quarter_label'].str.replace(r'(Q\d) (\d+)', r'\2-\1'), errors='coerce')
df_liner.rename(columns={'index_value':'country_index'},inplace=True)
df_liner.sort_values(['economy_label', 'quarter_label'], inplace=True)
df_liner['rolling_avg'] = df_liner.groupby('economy_label')['country_index'].transform(lambda x: x.rolling(4).mean())
df_liner['pct_change'] = (df_liner['country_index'] - df_liner['rolling_avg']) / df_liner['rolling_avg'] * 100
df_liner['is_disruption'] = df_liner['pct_change'] < -10
disruptions_over_time = df_liner[df_liner['is_disruption']].groupby('quarter_label').size()
disruptions_over_time = disruptions_over_time.reset_index()
disruptions_over_time.columns = ['quarter_label', 'disruption_count']

st.markdown('#### Liner Connectivity Index (LSCI) - Global Overview')
# Convert country names to ISO-3 codes
def get_iso3(name):
    try:
        return pycountry.countries.lookup(name).alpha_3
    except:
        return None

df_liner['iso_code'] = df_liner['economy_label'].apply(get_iso3)

# Drop rows with unmatched countries
df_liner = df_liner.dropna(subset=['iso_code'])

# Plotted using ISO-3
fig = px.choropleth(df_liner,
                    locations='iso_code',
                    color='country_index',
                    hover_name='economy_label',
                    color_continuous_scale='peach',
                    labels={'country_index': 'LSCI Value'})
fig.update_geos(showcoastlines=True, showcountries=True,)
fig.update_layout(
        template='plotly_dark',
        plot_bgcolor='rgba(0, 0, 0, 0)',
        paper_bgcolor='rgba(0, 0, 0, 0)',
        margin=dict(l=0, r=0, t=0, b=0),
        height=350,
        width=800)
st.plotly_chart(fig)

top_disrupted = df_liner[df_liner['is_disruption']].groupby('economy_label').size().sort_values(ascending=False)
fig_2= px.bar(top_disrupted.head(10).reset_index()
              , x='economy_label', y=0, title='Top 10 Disrupted Countries').update_layout(xaxis_title='Country', yaxis_title='Disruption Count')

st.plotly_chart(fig_2)

port_liner.rename(columns={'index_label':'port_index'},inplace=True)
top_ports = port_liner.groupby('port_label')['port_index'].mean().sort_values(ascending=False).head(5)
st.markdown('## Top 5 Ports by LSCI')
st.write(top_ports)
