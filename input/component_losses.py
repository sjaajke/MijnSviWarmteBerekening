"""
Component power loss data model.
"""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class ComponentLoss:
    """A single component with its power loss and optional thermal limit."""
    description: str
    power_loss_W: float
    max_temperature_C: Optional[float] = None   # Tmax [°C]
    installation_height_ratio: Optional[float] = None  # 0=bottom, 1=top


class ComponentTable:
    """Collection of components with helpers."""

    def __init__(self):
        self.components: list[ComponentLoss] = []

    def add(self, components: list[ComponentLoss]):
        self.components.extend(components)

    def total_power(self) -> float:
        return sum(c.power_loss_W for c in self.components)

    @staticmethod
    def example_components() -> list[ComponentLoss]:
        """EWK-G46/31 reference components (P_total = 136.25 W)."""
        return [
            ComponentLoss("MCB 3P 25A (PKZM)",        18.0,  max_temperature_C=70),
            ComponentLoss("RCBO 1P+N 16A",             6.5,  max_temperature_C=70),
            ComponentLoss("RCBO 1P+N 16A",             6.5,  max_temperature_C=70),
            ComponentLoss("RCBO 1P+N 10A",             4.5,  max_temperature_C=70),
            ComponentLoss("Rijgklemmen (20×)",         12.0),
            ComponentLoss("Aansluitklemmen",            8.75),
            ComponentLoss("Kabels en bedrading",       80.0),
        ]
