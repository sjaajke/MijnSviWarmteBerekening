"""
Report generation: JSON and PDF exports.
"""

import json
from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from core.iec60890_calculation import CalculationInput, CalculationResult
    from input.component_losses import ComponentTable


def generate_json_report(
    inp: "CalculationInput",
    result: "CalculationResult",
    components: "ComponentTable",
) -> str:
    """Generate a JSON string with all inputs and results."""
    geo = inp.geometry
    data = {
        "meta": {
            "standard": "IEC TR 60890:2022",
            "generated_at": datetime.now().isoformat(),
        },
        "input": {
            "geometry": {
                "height_mm": geo.height * 1000,
                "width_mm": geo.width * 1000,
                "depth_mm": geo.depth * 1000,
                "top_exposed": geo.top_exposed,
                "front_exposed": geo.front_exposed,
                "rear_exposed": geo.rear_exposed,
                "left_exposed": geo.left_exposed,
                "right_exposed": geo.right_exposed,
            },
            "installation_type": inp.installation_type.name,
            "ventilation": {
                "type": inp.ventilation.type.value,
                "opening_area_cm2": inp.ventilation.opening_area_cm2,
            },
            "total_power_loss_W": inp.total_power_loss_W,
            "num_horizontal_partitions": inp.num_horizontal_partitions,
            "ambient_temperature_C": inp.ambient_temperature_C,
            "solar_radiation": inp.solar_radiation,
        },
        "results": {
            "Ae_m2": result.Ae,
            "Ab_m2": result.Ab,
            "k": result.k,
            "f": result.f,
            "c": result.c,
            "x": result.x,
            "d": result.d,
            "delta_t_05_K": result.delta_t_05,
            "delta_t_075_K": result.delta_t_075,
            "delta_t_10_K": result.delta_t_10,
            "delta_t_solar_K": result.delta_t_solar,
            "T_ambient_C": result.T_ambient,
            "T_int_mid_C": result.T_int_mid,
            "T_int_top_C": result.T_int_top,
        },
        "components": [
            {
                "description": c.description,
                "power_loss_W": c.power_loss_W,
                "max_temperature_C": c.max_temperature_C,
                "verification": (
                    "PASS" if c.max_temperature_C and result.T_int_top <= c.max_temperature_C
                    else ("FAIL" if c.max_temperature_C else "N/A")
                ),
            }
            for c in components.components
        ],
    }
    return json.dumps(data, indent=2, ensure_ascii=False)


def generate_pdf_report(
    inp: "CalculationInput",
    result: "CalculationResult",
    components: "ComponentTable",
) -> bytes:
    """
    Generate a PDF report using reportlab.
    Raises ImportError if reportlab is not installed.
    """
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import mm
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors
    from reportlab.platypus import (
        SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
    )
    from io import BytesIO

    buf = BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4,
                            leftMargin=20*mm, rightMargin=20*mm,
                            topMargin=20*mm, bottomMargin=20*mm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("title", parent=styles["Title"], fontSize=16, spaceAfter=4)
    h2 = ParagraphStyle("h2", parent=styles["Heading2"], fontSize=12, spaceAfter=4)
    body = styles["Normal"]

    geo = inp.geometry
    elements = []

    elements.append(Paragraph("IEC TR 60890:2022 — Warmteberekening", title_style))
    elements.append(Paragraph(
        f"Gegenereerd op: {datetime.now().strftime('%d-%m-%Y %H:%M')}",
        body
    ))
    elements.append(HRFlowable(width="100%"))
    elements.append(Spacer(1, 4*mm))

    # --- Input summary ---
    elements.append(Paragraph("Invoergegevens", h2))
    input_data = [
        ["Parameter", "Waarde"],
        ["Hoogte H", f"{geo.height * 1000:.0f} mm"],
        ["Breedte W", f"{geo.width * 1000:.0f} mm"],
        ["Diepte D", f"{geo.depth * 1000:.0f} mm"],
        ["Installatietype", inp.installation_type.name.replace("_", " ")],
        ["Ventilatie", inp.ventilation.type.value],
        ["Vermogensverlies P", f"{inp.total_power_loss_W:.2f} W"],
        ["Omgevingstemperatuur Ta", f"{inp.ambient_temperature_C:.1f} °C"],
        ["Horizontale schotten", str(inp.num_horizontal_partitions)],
    ]
    t_input = Table(input_data, colWidths=[80*mm, 80*mm])
    t_input.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2563eb")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0f4f8")]),
    ]))
    elements.append(t_input)
    elements.append(Spacer(1, 4*mm))

    # --- Results ---
    elements.append(Paragraph("Berekeningsresultaten", h2))
    result_data = [
        ["Parameter", "Waarde", "Eenheid"],
        ["Effectief koeloppervlak Ae", f"{result.Ae:.4f}", "m²"],
        ["Grondoppervlak Ab", f"{result.Ab:.4f}", "m²"],
        ["Omhullingscoëfficiënt k", f"{result.k:.6f}", "K/W^x"],
        ["Hoogte/grond factor f", f"{result.f:.6f}", "—"],
        ["Temp. verdelingsfactor c", f"{result.c:.6f}", "—"],
        ["Exponent x", f"{result.x:.3f}", "—"],
        ["Schottenfactor d", f"{result.d:.1f}", "—"],
        ["Δt op halve hoogte Δt₀.₅", f"{result.delta_t_05:.3f}", "K"],
        ["Δt op 75% hoogte Δt₀.₇₅", f"{result.delta_t_075:.3f}", "K"],
        ["Δt bovenin Δt₁.₀", f"{result.delta_t_10:.3f}", "K"],
        ["Interne temp. (top) Tint", f"{result.T_int_top:.2f}", "°C"],
    ]
    t_result = Table(result_data, colWidths=[90*mm, 50*mm, 20*mm])
    t_result.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a7f4e")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0faf5")]),
    ]))
    elements.append(t_result)

    doc.build(elements)
    return buf.getvalue()
