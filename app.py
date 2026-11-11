"""
IEC TR 60890:2022 Temperature-rise calculator
Streamlit web application for LV switchgear assembly temperature verification.
"""

import streamlit as st
import plotly.graph_objects as go
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from core.iec60890_calculation import (
    CalculationInput, EnclosureGeometry, VentilationData,
    InstallationType, VentilationType, calculate, CalculationResult,
)
from input.component_losses import ComponentLoss, ComponentTable
from report.report_generator import generate_pdf_report, generate_json_report

# ---------------------------------------------------------------------------
# Page config
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="IEC TR 60890 Warmteberekening",
    page_icon="🌡️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ---------------------------------------------------------------------------
# Custom CSS
# ---------------------------------------------------------------------------
st.markdown("""
<style>
.metric-card {
    background: #f0f4f8;
    border-radius: 8px;
    padding: 12px 16px;
    margin: 4px 0;
}
.result-pass { color: #1a7f4e; font-weight: bold; }
.result-fail { color: #c0392b; font-weight: bold; }
.result-warn { color: #e67e22; font-weight: bold; }
</style>
""", unsafe_allow_html=True)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
st.title("🌡️ IEC TR 60890:2022 — Warmteberekening schakelkast")
st.caption("Temperatuurstijgingsberekening voor laagspanningsschakelinstallaties (LV switchgear assemblies)")

st.divider()

# ---------------------------------------------------------------------------
# Sidebar — Enclosure & Installation input
# ---------------------------------------------------------------------------
with st.sidebar:
    st.header("⚙️ Schakelkast parameters")

    st.subheader("Afmetingen")
    H = st.number_input("Hoogte H [mm]", min_value=100, max_value=4000, value=950, step=10)
    W = st.number_input("Breedte W [mm]", min_value=100, max_value=4000, value=1050, step=10)
    D = st.number_input("Diepte D [mm]", min_value=50, max_value=2000, value=225, step=5)

    st.subheader("Installatietype")
    inst_options = {
        "Vrijstaand — enkelvoudig": InstallationType.FREE_STANDING_SINGLE,
        "Vrijstaand — meervoudig": InstallationType.FREE_STANDING_MULTI,
        "Wandmontage — enkelvoudig": InstallationType.WALL_MOUNTED_SINGLE,
        "Wandmontage — meervoudig": InstallationType.WALL_MOUNTED_MULTI,
        "Ingebouwd": InstallationType.BUILT_IN,
    }
    inst_label = st.selectbox("Installatietype", list(inst_options.keys()), index=2)
    inst_type = inst_options[inst_label]

    # Auto-configure exposure based on installation type
    rear_exposed = inst_type in (
        InstallationType.FREE_STANDING_SINGLE,
        InstallationType.FREE_STANDING_MULTI,
    )
    left_exposed = inst_type not in (
        InstallationType.WALL_MOUNTED_MULTI,
        InstallationType.BUILT_IN,
    )
    right_exposed = inst_type not in (
        InstallationType.WALL_MOUNTED_MULTI,
        InstallationType.BUILT_IN,
    )
    top_exposed = inst_type != InstallationType.BUILT_IN

    with st.expander("Oppervlakken (aanpassen indien nodig)"):
        top_exposed = st.checkbox("Bovenzijde vrij", value=top_exposed)
        front_exposed = st.checkbox("Voorzijde vrij", value=True)
        rear_exposed = st.checkbox("Achterzijde vrij", value=rear_exposed)
        left_exposed = st.checkbox("Linkerzijde vrij", value=left_exposed)
        right_exposed = st.checkbox("Rechterzijde vrij", value=right_exposed)

    st.subheader("Ventilatie")
    vent_options = {
        "Geen ventilatie": VentilationType.NONE,
        "Natuurlijke ventilatie": VentilationType.NATURAL,
    }
    vent_label = st.selectbox("Ventilatietype", list(vent_options.keys()))
    vent_type = vent_options[vent_label]
    vent_area_cm2 = 0.0
    if vent_type != VentilationType.NONE:
        vent_area_cm2 = st.number_input(
            "Openingsoppervlak Aeff [cm²]", min_value=0.0, value=100.0, step=10.0
        )

    st.subheader("Horizontale schotten")
    n_partitions = st.number_input(
        "Aantal horizontale schotten", min_value=0, max_value=4, value=0
    )

    st.subheader("Omgevingstemperatuur")
    T_ambient = st.number_input(
        "Omgevingstemperatuur Ta [°C]", min_value=-25, max_value=60, value=35
    )

    st.subheader("Zonnestraling (Annex C)")
    solar_options = {"Geen": None, "Licht oppervlak (+10K)": "light", "Donker oppervlak (+25K)": "dark"}
    solar_label = st.selectbox("Zonnestraling", list(solar_options.keys()))
    solar = solar_options[solar_label]

# ---------------------------------------------------------------------------
# Main area — Component losses table
# ---------------------------------------------------------------------------
col_left, col_right = st.columns([1, 1], gap="large")

with col_left:
    st.subheader("🔌 Vermogensverliezen componenten")

    # Session state for component table
    if "components" not in st.session_state:
        st.session_state.components = ComponentTable()
        # Default examples
        st.session_state.components.add(ComponentTable.example_components())

    comp_table = st.session_state.components

    # Display editable component table
    import pandas as pd

    comp_df = pd.DataFrame([
        {
            "Omschrijving": c.description,
            "Vermogensverlies [W]": c.power_loss_W,
            "Tmax [°C]": c.max_temperature_C if c.max_temperature_C else "",
        }
        for c in comp_table.components
    ])

    edited_df = st.data_editor(
        comp_df,
        num_rows="dynamic",
        column_config={
            "Omschrijving": st.column_config.TextColumn("Omschrijving", width="medium"),
            "Vermogensverlies [W]": st.column_config.NumberColumn(
                "Pv [W]", min_value=0.0, max_value=100000.0, format="%.2f"
            ),
            "Tmax [°C]": st.column_config.NumberColumn(
                "Tmax [°C]", min_value=0.0, max_value=200.0, format="%.0f"
            ),
        },
        use_container_width=True,
        key="comp_editor",
    )

    # Update components from edited table
    new_components = []
    for _, row in edited_df.iterrows():
        desc = str(row["Omschrijving"]) if not pd.isna(row["Omschrijving"]) else "Component"
        pv = float(row["Vermogensverlies [W]"]) if not pd.isna(row["Vermogensverlies [W]"]) else 0.0
        tmax_raw = row["Tmax [°C]"]
        tmax = float(tmax_raw) if not pd.isna(tmax_raw) else None
        new_components.append(ComponentLoss(description=desc, power_loss_W=pv, max_temperature_C=tmax))
    comp_table.components = new_components

    P_total = comp_table.total_power()
    st.metric("Totaal vermogensverlies P", f"{P_total:.2f} W")

# ---------------------------------------------------------------------------
# Build inputs and calculate
# ---------------------------------------------------------------------------
geo = EnclosureGeometry(
    height=H / 1000,
    width=W / 1000,
    depth=D / 1000,
    top_exposed=top_exposed,
    front_exposed=front_exposed,
    rear_exposed=rear_exposed,
    left_exposed=left_exposed,
    right_exposed=right_exposed,
    bottom_exposed=False,
)
vent_data = VentilationData(type=vent_type, opening_area_cm2=vent_area_cm2)
inp = CalculationInput(
    geometry=geo,
    installation_type=inst_type,
    ventilation=vent_data,
    total_power_loss_W=P_total,
    num_horizontal_partitions=n_partitions,
    ambient_temperature_C=T_ambient,
    solar_radiation=solar,
)

result = calculate(inp)

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
with col_right:
    st.subheader("📊 Berekeningsresultaten")

    r1, r2, r3 = st.columns(3)
    r1.metric("Ae [m²]", f"{result.Ae:.4f}")
    r2.metric("k", f"{result.k:.5f}")
    r3.metric("f", f"{result.f:.4f}")

    r4, r5, r6 = st.columns(3)
    r4.metric("c", f"{result.c:.5f}")
    r5.metric("x", f"{result.x:.3f}")
    r6.metric("d", f"{result.d:.1f}")

    st.divider()

    t1, t2, t3 = st.columns(3)
    t1.metric("Δt₀.₅ [K]", f"{result.delta_t_05:.2f}", help="Temperatuurstijging op halve hoogte")
    t2.metric("Δt₀.₇₅ [K]", f"{result.delta_t_075:.2f}", help="Temperatuurstijging op 75% hoogte")
    t3.metric("Δt₁.₀ [K]", f"{result.delta_t_10:.2f}", help="Temperatuurstijging bovenin")

    st.divider()

    ti1, ti2 = st.columns(2)
    ti1.metric("Tint midden [°C]", f"{result.T_int_mid:.2f}")
    ti2.metric("Tint bovenkant [°C]", f"{result.T_int_top:.2f}")

    if solar:
        st.info(f"Zonnecorrectie (Annex C): +{result.delta_t_solar:.0f} K")

# ---------------------------------------------------------------------------
# Temperature profile chart
# ---------------------------------------------------------------------------
st.divider()
st.subheader("📈 Temperatuurprofiel")

chart_col, verify_col = st.columns([1, 1], gap="large")

with chart_col:
    profile = result.temperature_profile(steps=51)
    h_vals = [p[0] * H for p in profile]        # height in mm from bottom
    t_vals = [T_ambient + p[1] for p in profile]  # absolute temperature

    fig = go.Figure()

    # Temperature profile curve
    fig.add_trace(go.Scatter(
        x=t_vals,
        y=h_vals,
        mode="lines",
        name="Temperatuurprofiel",
        line=dict(color="#2563eb", width=3),
    ))

    # Key points
    key_heights = [0, H * 0.5, H * 0.75, H]
    key_temps = [
        T_ambient,
        T_ambient + result.delta_t_05,
        T_ambient + result.delta_t_075,
        T_ambient + result.delta_t_10,
    ]
    key_labels = ["Basis (Δt=0)", "h=0.5 (Δt₀.₅)", "h=0.75 (Δt₀.₇₅)", "Top (Δt₁.₀)"]
    fig.add_trace(go.Scatter(
        x=key_temps,
        y=key_heights,
        mode="markers+text",
        marker=dict(color="#dc2626", size=10),
        text=[f"{t:.1f}°C" for t in key_temps],
        textposition="middle right",
        name="Sleutelpunten",
    ))

    # Ambient temperature line
    fig.add_vline(
        x=T_ambient,
        line_dash="dash",
        line_color="gray",
        annotation_text=f"Ta={T_ambient}°C",
    )

    fig.update_layout(
        xaxis_title="Temperatuur [°C]",
        yaxis_title="Hoogte [mm]",
        height=400,
        margin=dict(l=10, r=10, t=30, b=10),
        legend=dict(orientation="h", yanchor="bottom", y=1.02),
        plot_bgcolor="white",
        paper_bgcolor="white",
    )
    fig.update_xaxes(gridcolor="#e5e7eb", showline=True, linecolor="#9ca3af")
    fig.update_yaxes(gridcolor="#e5e7eb", showline=True, linecolor="#9ca3af")

    st.plotly_chart(fig, use_container_width=True)

# ---------------------------------------------------------------------------
# Component temperature verification
# ---------------------------------------------------------------------------
with verify_col:
    st.subheader("✅ Componentverificatie")
    st.caption("Tint ≤ Tmax per component (op basis van Tint bovenkant)")

    verification_data = []
    for comp in comp_table.components:
        if comp.max_temperature_C and comp.max_temperature_C > 0:
            tint = result.T_int_top + (comp.installation_height_ratio or 1.0) * 0 + result.delta_t_solar
            # Use top temperature as worst case
            tint_use = result.T_int_top
            margin = comp.max_temperature_C - tint_use
            status = "✅ OK" if margin >= 0 else "❌ OVERSCHRIJDING"
            verification_data.append({
                "Component": comp.description,
                "Pv [W]": f"{comp.power_loss_W:.2f}",
                "Tmax [°C]": f"{comp.max_temperature_C:.0f}",
                "Tint [°C]": f"{tint_use:.1f}",
                "Marge [K]": f"{margin:+.1f}",
                "Status": status,
            })

    if verification_data:
        verify_df = pd.DataFrame(verification_data)
        st.dataframe(verify_df, use_container_width=True, hide_index=True)
    else:
        st.info("Voeg Tmax toe aan componenten voor verificatie.")

# ---------------------------------------------------------------------------
# Detailed intermediate values (expander)
# ---------------------------------------------------------------------------
with st.expander("🔍 Tussenliggende berekeningswaarden"):
    areas = geo.surface_areas()
    bmap = {
        "Bovenzijde":    (areas["top"],   1.4 if top_exposed else 0.7),
        "Voorzijde":     (areas["front"], 0.9 if front_exposed else 0.5),
        "Achterzijde":   (areas["rear"],  0.9 if rear_exposed else 0.5),
        "Linkerzijde":   (areas["left"],  0.9 if left_exposed else 0.5),
        "Rechterzijde":  (areas["right"], 0.9 if right_exposed else 0.5),
    }

    detail_rows = []
    for name, (ao, b) in bmap.items():
        detail_rows.append({
            "Oppervlak": name,
            "Ao [m²]": f"{ao:.6f}",
            "b-factor": f"{b:.1f}",
            "Ao×b [m²]": f"{ao * b:.6f}",
        })
    detail_rows.append({
        "Oppervlak": "**Totaal Ae**",
        "Ao [m²]": "",
        "b-factor": "",
        "Ao×b [m²]": f"**{result.Ae:.6f}**",
    })
    st.dataframe(pd.DataFrame(detail_rows), use_container_width=True, hide_index=True)

    st.markdown(f"""
    | Parameter | Formule | Waarde |
    |-----------|---------|--------|
    | Ae | Σ(Ao × b) | {result.Ae:.6f} m² |
    | Ab | W × D | {result.Ab:.6f} m² |
    | f | H^1.35 / Ab | {result.f:.6f} |
    | k | 0.58 × Ae^(-0.795) | {result.k:.6f} |
    | c | −0.0017f² + 0.055f + 1.146 | {result.c:.6f} |
    | x | {'0.804' if result.x == 0.804 else '0.715'} | {result.x} |
    | d | n={n_partitions} → tabel 4/5 | {result.d} |
    | Δt₀.₅ | k × d × P^x | {result.delta_t_05:.6f} K |
    | Δt₁.₀ | c × Δt₀.₅ | {result.delta_t_10:.6f} K |
    """)

# ---------------------------------------------------------------------------
# Export buttons
# ---------------------------------------------------------------------------
st.divider()
st.subheader("📥 Export")

exp_col1, exp_col2, exp_col3 = st.columns(3)

with exp_col1:
    json_data = generate_json_report(inp, result, comp_table)
    st.download_button(
        "⬇️ Download JSON",
        data=json_data,
        file_name="iec60890_resultaat.json",
        mime="application/json",
    )

with exp_col2:
    try:
        pdf_bytes = generate_pdf_report(inp, result, comp_table)
        st.download_button(
            "⬇️ Download PDF rapport",
            data=pdf_bytes,
            file_name="iec60890_rapport.pdf",
            mime="application/pdf",
        )
    except ImportError:
        st.warning("PDF export vereist: pip install reportlab")

with exp_col3:
    st.info("Excel export — coming soon")
