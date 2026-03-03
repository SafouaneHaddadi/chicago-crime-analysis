import streamlit as st
import pandas as pd
import plotly.express as px


st.set_page_config(page_title="Chicago Crime & Schools Dashboard", layout="wide")

GITHUB_LINK = 'https://github.com/SafouaneHaddadi/chicago-crime-analysis'


@st.cache_data
def load_data():
    community_df = pd.read_csv('community_data.csv', sep=';', decimal=',') 
    dashboard_df = pd.read_csv('dashboard_data.csv', sep=';', decimal=',')
    return dashboard_df, community_df

dashboard_df, community_df = load_data()

if dashboard_df.empty or community_df.empty:
    st.error("Failed to load data files.")
    st.stop()

data = dashboard_df.iloc[0]


with st.sidebar: 
    st.image("https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Flag_of_Chicago%2C_Illinois.svg/500px-Flag_of_Chicago%2C_Illinois.svg.png", width=100)
    st.title("Chicago Dashboard")
    st.markdown("---")
    st.markdown(f"**Report Date:** {data['Report_date']}")
    st.markdown("**Data Source:** Chicago Crime & Socioeconomic Datasets")
    st.markdown("**Analysis Period:** 2016-2025")
    if GITHUB_LINK:
        st.markdown(f"[View on GitHub]({GITHUB_LINK})")
    st.markdown("---")


st.title("Chicago Crime & Schools Executive Dashboard")
st.markdown("A comprehensive view of crime trends, community risk, and school performance across Chicago's 77 community areas.")
st.markdown("---")

# === KPIs ===
st.subheader("City Overview")
col1, col2, col3, col4, col5 = st.columns(5)

with col1:
    crimes_10yr = f"{int(data['Total_Crimes_2016_2025']):,}"
    st.metric(label="Total Crimes (2016-2025)", value=crimes_10yr, delta=data['Crime_Change_5yr'], delta_color="inverse")

with col2:
    crimes_2025 = f"{int(data['Crimes_In_2025']):,}"
    st.metric(label="Crimes in 2025", value=crimes_2025)

with col3:
    st.metric(label="Total Schools", value=f"{int(data['Total_Schools']):,}")

with col4:
    st.metric(label="Avg Safety Score", value=f"{data['City_Avg_Safety_Score']}")

with col5:
    st.metric(label="Avg Poverty Rate", value=f"{data['City_Avg_Poverty_Rate']}%")

# === COMMUNITY RISK ===
st.subheader("Community Risk Summary")

col1, col2 = st.columns(2)

with col1:
    st.metric(label="High Risk Communities", value=data['High_Risk_Communities'], help="Communities needing immediate attention")
    st.progress(data['High_Risk_Communities']/77, text=f"{data['High_Risk_Communities']}/77 ({data['High_Risk_Communities']/77*100:.1f}%)")

with col2:
    st.metric(label="Critical Risk Communities", value=data['Critical_Risk_Communities'], help="Zero critical communities means we prevented the worst")
    st.progress(data['Critical_Risk_Communities']/77, text=f"{data['Critical_Risk_Communities']}/77 (0%)")

st.markdown(f"**Top Vulnerable Communities:** {data['Top_5_Vulnerable_Areas']}")
st.markdown("---")

# === CRIME TRENDS ===
st.subheader("Crime Trends")

col1, col2 = st.columns(2)

with col1:
    st.markdown("**Fastest Increasing Crimes**")
    st.info(data['Fastest_Increasing_Crimes'])

with col2:
    st.markdown("**Fastest Decreasing Crimes**")
    st.success(data['Biggest_Decreasing_Crimes'])

st.markdown("---")

# === CRIME CONCENTRATION ===
st.subheader("Crime Concentration in Poor vs Rich Areas")

col1, col2 = st.columns(2)

with col1:
    st.markdown("**Most Concentrated in Poor Areas**")
    st.warning(data['Crimes_Most_Concentrated_in_Poor_Areas'])

with col2:
    st.markdown("**More Common in Non-Poor Areas**")
    st.info(data['Crimes_More_Common_in_Non_Poor_Areas'])

st.markdown("---")

# === SCATTER PLOT (using community_df from CSV) ===
st.subheader("Poverty vs Crime: Do poorer neighborhoods have more crime?")
st.markdown("Each dot is one community area. Hover to see details.")

if not community_df.empty:
    fig = px.scatter(
        community_df,
        x='poverty_rate',
        y='total_crimes',
        color='risk_category',
        size='total_crimes',
        hover_name='community_area_name',
        color_discrete_map={
            'CRITICAL RISK': 'darkred',
            'HIGH RISK': 'red',
            'MODERATE RISK': 'orange',
            'AVERAGE RISK': 'gray',
            'LOW RISK': 'lightgreen',
            'VERY LOW RISK': 'green'
        },
        title="Higher poverty tends to mean higher crime (colored by risk level)",
        labels={'poverty_rate': 'Poverty Rate (%)', 'total_crimes': 'Total Crimes'}
    )
    fig.update_layout(height=600, showlegend=True, legend_title_text="Risk Category")
    st.plotly_chart(fig, width='stretch')
else:
    st.warning("Could not load scatter plot data.")

# === SCHOOL SAFETY GAP ===
st.subheader("School Performance Gap")

col1, col2 = st.columns(2)

with col1:
    safety_data = pd.DataFrame({
        'Area': ['High-Crime Areas', 'Low-Crime Areas'],
        'Safety Score': [data['Safety_High_Crime_Areas'], data['Safety_Low_Crime_Areas']]
    })
    fig = px.bar(safety_data, x='Area', y='Safety Score', color='Area',
                color_discrete_map={'High-Crime Areas': 'coral', 'Low-Crime Areas': 'lightgreen'},
                text='Safety Score', title=f"School Safety Scores (Gap: {data['Safety_Gap']:.1f} points)")
    fig.update_traces(textposition='outside')
    fig.update_layout(height=500)
    st.plotly_chart(fig, width='stretch')


with col2:
    math_data = pd.DataFrame({
        'Area': ['High-Crime Areas', 'Low-Crime Areas'],
        'Math Score (%)': [data['Math_High_Crime_Areas'], data['Math_Low_Crime_Areas']]
    })
    fig = px.bar(math_data, x='Area', y='Math Score (%)', color='Area',
                color_discrete_map={'High-Crime Areas': 'coral', 'Low-Crime Areas': 'lightgreen'},
                text='Math Score (%)', title=f"Math Proficiency (Gap: {data['Math_Gap']} points)")
    fig.update_traces(textposition='outside')
    fig.update_layout(height=500)
    st.plotly_chart(fig, width='stretch')


# === FOOTER ===
st.markdown("---")
st.markdown("Dashboard created with Streamlit • Data from Chicago Data Portal")