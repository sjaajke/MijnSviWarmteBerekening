"""
Validation tests against Excel reference: EWK-G46/31
Temperature Assessment v7.8 - EWK met RCBO en rijgklemmen.xlsx

Reference values extracted from 'Temperature verification' sheet:
  Enclosure:  EWK-G46/31, H=950mm, W=1050mm, D=225mm
  Installation: type 3 (wall-mounted, single)
  No ventilation, 0 horizontal partitions
  P_total = 136.25 W
  Ae     = 2.112 m²
  k      = 0.320107855580432
  f      = 3.949617604285517
  c      = 1.3367098535615638
  x      = 0.804, d = 1.0
  Δt0.5  = 16.6457315680574 K
  Δt0.75 = 19.448122487410252 K
  Δt1.0  = 22.25051340676311 K
  Ta     = 25°C → T_int_top = 47.250513406763105°C

Tolerance: < 2% relative error on key values.
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from core.iec60890_calculation import (
    CalculationInput, EnclosureGeometry, VentilationData,
    InstallationType, VentilationType, calculate,
)

TOLERANCE = 0.02  # 2% relative


def relative_error(computed: float, reference: float) -> float:
    return abs(computed - reference) / abs(reference)


def test_ewk_geometry():
    """Test effective cooling surface Ae for EWK-G46/31."""
    geo = EnclosureGeometry(
        height=0.950, width=1.050, depth=0.225,
        top_exposed=True,
        front_exposed=True,
        rear_exposed=False,   # wall-mounted → rear against wall
        left_exposed=True,
        right_exposed=True,
        bottom_exposed=False,
    )
    Ae = geo.effective_cooling_surface()
    ref_Ae = 2.112
    err = relative_error(Ae, ref_Ae)
    print(f"Ae computed: {Ae:.6f}  reference: {ref_Ae}  error: {err:.2%}")
    assert err < TOLERANCE, f"Ae error {err:.2%} exceeds tolerance {TOLERANCE:.2%}"


def test_ewk_full_calculation():
    """Full calculation for EWK-G46/31 with P=136.25W, Ta=25°C."""
    geo = EnclosureGeometry(
        height=0.950, width=1.050, depth=0.225,
        top_exposed=True,
        front_exposed=True,
        rear_exposed=False,
        left_exposed=True,
        right_exposed=True,
        bottom_exposed=False,
    )
    inp = CalculationInput(
        geometry=geo,
        installation_type=InstallationType.WALL_MOUNTED_SINGLE,
        ventilation=VentilationData(type=VentilationType.NONE),
        total_power_loss_W=136.25,
        num_horizontal_partitions=0,
        ambient_temperature_C=25.0,
    )
    result = calculate(inp)

    # Reference values
    refs = {
        "Ae":        (result.Ae,        2.112),
        "k":         (result.k,         0.320107855580432),
        "f":         (result.f,         3.949617604285517),
        "c":         (result.c,         1.3367098535615638),
        "delta_t05": (result.delta_t_05, 16.6457315680574),
        "delta_t10": (result.delta_t_10, 22.25051340676311),
        "T_int_top": (result.T_int_top,  47.250513406763105),
    }

    print("\n--- EWK-G46/31 Validation ---")
    all_pass = True
    for name, (computed, reference) in refs.items():
        err = relative_error(computed, reference)
        status = "PASS" if err < TOLERANCE else "FAIL"
        if err >= TOLERANCE:
            all_pass = False
        print(f"  {name:12s}: computed={computed:12.6f}  ref={reference:12.6f}  err={err:.2%}  {status}")

    assert all_pass, "One or more validation checks failed (see output above)"


if __name__ == "__main__":
    print("Running EWK validation tests...")
    test_ewk_geometry()
    test_ewk_full_calculation()
    print("\nAll tests passed!")
