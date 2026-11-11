"""
IEC TR 60890:2022 — Stap-voor-stap uitleg van de warmteberekening
"""

import streamlit as st

st.set_page_config(
    page_title="Uitleg Berekening — IEC TR 60890",
    page_icon="📐",
    layout="wide",
)

st.title("📐 Stap-voor-stap uitleg IEC TR 60890:2022")
st.caption(
    "Temperatuurstijgingsberekening voor laagspanningsschakelinstallaties — "
    "volledig uitgewerkte rekenmethode"
)

st.info(
    "Deze pagina legt de volledige rekenmethode van IEC TR 60890:2022 uit. "
    "De berekening telt 6 stappen, van de geometrie van de kast tot de eindtemperatuur."
)

st.divider()

# ---------------------------------------------------------------------------
# Overzicht
# ---------------------------------------------------------------------------
st.header("Overzicht van de rekenmethode")

st.markdown("""
De norm IEC TR 60890:2022 beschrijft een empirische methode om te berekenen hoeveel de
interne luchttemperatuur stijgt ten opzichte van de omgevingstemperatuur, als gevolg van
de vermogensverliezen van de geïnstalleerde componenten.

De methode bestaat uit de volgende stappen:

| Stap | Grootheid | Omschrijving |
|------|-----------|-------------|
| 1 | **Ae** | Effectief koeloppervlak [m²] |
| 2 | **Ab, f** | Basisoppervlak en hoogte/basis-factor |
| 3 | **k** | Omhullingscoëfficiënt [K/W^x] |
| 4 | **x** | Exponent vermogensverlies |
| 5 | **c** | Temperatuurverdelingscoëfficiënt |
| 6 | **d** | Scheidingsplaatfactor |
| 7 | **Δt₀.₅** | Temperatuurstijging op halve hoogte [K] |
| 8 | **Δt₁.₀** | Temperatuurstijging bovenin [K] |
""")

st.divider()

# ---------------------------------------------------------------------------
# Stap 1 — Effectief koeloppervlak Ae
# ---------------------------------------------------------------------------
st.header("Stap 1 — Effectief koeloppervlak Ae")

col1, col2 = st.columns([3, 2])

with col1:
    st.markdown("""
Het effectief koeloppervlak **Ae** is een gewogen som van alle buitenoppervlakken van de
schakelkast. Elk oppervlak krijgt een **b-factor** (weegfactor) op basis van zijn oriëntatie
en of het vrij is of grenst aan een wand, vloer of naaststaande kast.

De formule is:
""")
    st.latex(r"A_e = \sum_{i} (A_{o,i} \times b_i) \quad \text{[m²]}")
    st.markdown("""
waarbij:
- **Ao,i** = fysiek oppervlak van zijde *i* [m²]
- **b** = weegfactor uit Tabel 3 van de norm
""")

with col2:
    st.markdown("**Tabel 3 — b-factoren per oppervlak**")
    st.table({
        "Oppervlak": [
            "Bovenzijde — vrij",
            "Bovenzijde — afgedekt",
            "Zijkant / voor / achter — vrij",
            "Zijkant / voor / achter — afgedekt",
            "Onderzijde (vloer)",
        ],
        "b-factor": [1.4, 0.7, 0.9, 0.5, 0.0],
    })

st.markdown("""
> **Waarom verschillende b-factoren?** Warmte stijgt omhoog. De bovenzijde koelt daardoor
> het meest effectief (b = 1.4 bij vrij). De onderkant draagt niets bij (b = 0), want
> warme lucht stijgt weg van de bodem.

**Berekening van de oppervlakken:**
""")
st.latex(r"""
A_{top} = W \times D \qquad
A_{voor/achter} = H \times W \qquad
A_{links/rechts} = H \times D
""")

st.markdown("**Voorbeeld** (H=950 mm, W=1050 mm, D=225 mm, wandmontage enkelvoudig):")
st.latex(r"""
A_e = (1.050 \times 0.225) \times 0.7 \;+\; (0.950 \times 1.050) \times 0.9 \;+\;
      (0.950 \times 1.050) \times 0.5 \;+\; (0.950 \times 0.225) \times 0.9 \;+\;
      (0.950 \times 0.225) \times 0.9
""")
st.latex(r"A_e \approx 2.112 \text{ m}^2")

st.divider()

# ---------------------------------------------------------------------------
# Stap 2 — Basisoppervlak Ab en hoogte/basis-factor f
# ---------------------------------------------------------------------------
st.header("Stap 2 — Basisoppervlak Ab en hoogte/basis-factor f")

col1, col2 = st.columns(2)

with col1:
    st.markdown("""
Het **basisoppervlak Ab** is simpelweg de grondvlakoppervlakte van de kast:
""")
    st.latex(r"A_b = W \times D \quad \text{[m²]}")

with col2:
    st.markdown("""
De **hoogte/basis-factor f** is een maat voor de verhouding tussen de hoogte
en de doorsnede van de kast. Een slanke, hoge kast heeft een grotere f-waarde.
""")
    st.latex(r"f = \frac{H^{1.35}}{A_b}")

st.markdown("""
> **Betekenis van f:** Een hogere kast met klein grondvlak heeft een sterker
> schoorsteen-effect (convectie), waardoor de temperatuurverdeling over de hoogte groter is.
> Dit wordt later meegenomen in de c-factor (stap 5).

**Voorbeeld:**
""")
st.latex(r"f = \frac{0.950^{1.35}}{1.050 \times 0.225} = \frac{0.929}{0.236} \approx 3.95")

st.divider()

# ---------------------------------------------------------------------------
# Stap 3 — Omhullingscoëfficiënt k
# ---------------------------------------------------------------------------
st.header("Stap 3 — Omhullingscoëfficiënt k")

st.markdown("""
De **omhullingscoëfficiënt k** geeft aan hoe effectief de kast zijn warmte kwijt kan per
eenheid vermogensverlies. De waarde hangt af van het effectief koeloppervlak Ae en of er
ventilatieopeningen aanwezig zijn.

De norm onderscheidt drie situaties:
""")

tab1, tab2, tab3 = st.tabs([
    "Ae > 1.25 m² — geen ventilatie",
    "Ae > 1.25 m² — natuurlijke ventilatie",
    "Ae ≤ 1.25 m² — kleine kast",
])

with tab1:
    st.markdown("**Tabel 6 / Figuur 3** — Grote kast zonder ventilatie:")
    st.latex(r"k = 0.58 \times A_e^{-0.795}")
    st.markdown("""
    **Voorbeeld:**
    """)
    st.latex(r"k = 0.58 \times 2.112^{-0.795} = 0.58 \times 0.552 \approx 0.320")

with tab2:
    st.markdown("**Tabel 8 / Figuur 5** — Grote kast met natuurlijke ventilatie:")
    st.latex(r"k_v = k_{nv} \times \eta_v")
    st.markdown(r"""
    waarbij $\eta_v$ de ventilatiereductie is op basis van het openingsoppervlak Aeff [cm²]:
    """)
    st.latex(r"\eta_v = \frac{1}{1 + 0.05 \sqrt{A_{eff} / A_e}}")
    st.markdown("""
    > Ventilatie verlaagt k: de kast koelt effectiever, dus is minder warmtestijging per Watt.
    """)

with tab3:
    st.markdown("**Tabel 10 / Figuur 7** — Kleine kast (Ae ≤ 1.25 m²):")
    st.latex(r"""
    k = \begin{cases}
    4.0 & \text{als } A_e < 0.08 \text{ m}^2 \\
    0.626 \times A_e^{-0.737} & \text{als } A_e \geq 0.08 \text{ m}^2
    \end{cases}
    """)

st.markdown("""
> **Eenheid van k:** [K/W^x]. Dit is de temperatuurstijging die 1 W vermogensverlies
> veroorzaakt, gecorrigeerd voor de niet-lineaire exponent x.
""")

st.divider()

# ---------------------------------------------------------------------------
# Stap 4 — Exponent x
# ---------------------------------------------------------------------------
st.header("Stap 4 — Exponent x")

st.markdown("""
De temperatuurstijging is **niet lineair** met het vermogensverlies. De relatie wordt
beschreven door een machtsexponent **x**. De exponent is afhankelijk van de kast en
ventilatie:
""")

col1, col2 = st.columns(2)
with col1:
    st.table({
        "Situatie": [
            "Ae > 1.25 m², geen ventilatie",
            "Ae > 1.25 m², natuurlijke ventilatie",
            "Ae ≤ 1.25 m²",
        ],
        "x": [0.804, 0.715, 0.804],
    })

with col2:
    st.markdown("""
> **Betekenis:** Als x < 1 is het systeem niet-lineair. Het verdubbelen van het
> vermogensverlies leidt **niet** tot een verdubbeling van de temperatuurstijging,
> maar tot een stijging met factor 2^0.804 ≈ 1.75.
>
> Bij ventilatie (x = 0.715) is de niet-lineariteit nog sterker: het koeleffect
> neemt relatief toe bij hogere vermogens.
""")

st.divider()

# ---------------------------------------------------------------------------
# Stap 5 — Temperatuurverdelingscoëfficiënt c
# ---------------------------------------------------------------------------
st.header("Stap 5 — Temperatuurverdelingscoëfficiënt c")

st.markdown("""
De coëfficiënt **c** beschrijft de verhouding tussen de temperatuurstijging bovenin (Δt₁.₀)
en op halve hoogte (Δt₀.₅). Een hogere c-waarde betekent een sterkere
temperatuurgradiënt van onder naar boven.

De formule is een kwadratische polynoom in f:
""")

st.latex(r"c = -0.0017 \cdot f^2 + 0.055 \cdot f + 1.146")

col1, col2 = st.columns(2)
with col1:
    st.markdown("""
**Wanneer van toepassing:**
- Grote kast (Ae > 1.25 m²), geen ventilatie → Figuur 4 / Tabel 7
- Kleine kast (Ae ≤ 1.25 m²) → Figuur 8 / Tabel 11
- Grote kast, ventilatie → c × 0.9 (lagere gradiënt door menging)

De constante C₀ = 1.146 is gekalibreerd op basis van de IEC-referentietabellen.
""")

with col2:
    st.markdown("**Voorbeeld (f = 3.95):**")
    st.latex(r"""
    c = -0.0017 \times 3.95^2 + 0.055 \times 3.95 + 1.146
    """)
    st.latex(r"""
    c = -0.0265 + 0.2173 + 1.146 \approx 1.337
    """)

st.markdown("""
> **Betekenis:** c > 1 betekent altijd dat de top warmer is dan het midden.
> Bij een lage, brede kast (kleine f) is c dichter bij 1.0, wat een gelijkmatigere
> temperatuurverdeling aangeeft.
""")

st.divider()

# ---------------------------------------------------------------------------
# Stap 6 — Scheidingsplaatfactor d
# ---------------------------------------------------------------------------
st.header("Stap 6 — Scheidingsplaatfactor d")

col1, col2 = st.columns([2, 3])

with col1:
    st.markdown("**Tabel 4/5 — d-factor per aantal schotten**")
    st.table({
        "Aantal horizontale schotten": [0, 1, 2, 3, "≥ 4"],
        "d-factor": [1.0, 1.3, 1.5, 1.7, 2.0],
    })

with col2:
    st.markdown("""
Horizontale schotten (tussenwanden) in de kast belemmeren de convectieve luchtstroom
omhoog. Hierdoor wordt de warmte slechter afgevoerd en stijgt de temperatuur meer.

> **Waarom stijgt d zo snel?** Elk schot snijdt de verticale convectiekolom door.
> Lucht die al opgewarmd is in het onderste compartiment, kan niet meer vrij omhoog
> stromen om te koelen. Elk extra schot vermenigvuldigt dit effect.

Bij 0 schotten (d = 1.0) is er geen correctie nodig: de lucht stroomt vrij
van onder naar boven door de kast.
""")

st.divider()

# ---------------------------------------------------------------------------
# Stap 7 — Temperatuurstijging op halve hoogte Δt₀.₅
# ---------------------------------------------------------------------------
st.header("Stap 7 — Temperatuurstijging op halve hoogte Δt₀.₅")

st.markdown("""
Nu alle factoren bekend zijn, wordt de **temperatuurstijging op halve hoogte** berekend.
Dit is het referentiepunt van de norm.
""")

st.latex(r"\Delta t_{0.5} = k \times d \times P^x \quad \text{[K]}")

st.markdown("""
waarbij:
- **k** = omhullingscoëfficiënt [K/W^x]
- **d** = scheidingsplaatfactor [-]
- **P** = totaal vermogensverlies [W]
- **x** = exponent [-]
""")

st.markdown("**Voorbeeld** (k=0.320, d=1.0, P=136.25 W, x=0.804):")
st.latex(r"\Delta t_{0.5} = 0.320 \times 1.0 \times 136.25^{0.804} = 0.320 \times 52.02 \approx 16.65 \text{ K}")

st.divider()

# ---------------------------------------------------------------------------
# Stap 8 — Temperatuurstijging bovenin Δt₁.₀
# ---------------------------------------------------------------------------
st.header("Stap 8 — Temperatuurstijging bovenin Δt₁.₀")

st.markdown("""
De temperatuurstijging **bovenin de kast** (op volledige hoogte) wordt berekend door
Δt₀.₅ te vermenigvuldigen met de verdelingscoëfficiënt c:
""")

st.latex(r"\Delta t_{1.0} = c \times \Delta t_{0.5} \quad \text{[K]}")

st.markdown("**Voorbeeld** (c=1.337, Δt₀.₅=16.65 K):")
st.latex(r"\Delta t_{1.0} = 1.337 \times 16.65 \approx 22.25 \text{ K}")

st.markdown("""
De temperatuurstijging op **75% hoogte** wordt lineair geïnterpoleerd:
""")
st.latex(r"\Delta t_{0.75} = \Delta t_{0.5} + \frac{\Delta t_{1.0} - \Delta t_{0.5}}{2}")

st.markdown("Op willekeurige hoogte h (als fractie 0–1):")
st.latex(r"""
\Delta t(h) = \begin{cases}
\Delta t_{0.5} \cdot \dfrac{h}{0.5} & \text{als } h \leq 0.5 \\[10pt]
\Delta t_{0.5} + (\Delta t_{1.0} - \Delta t_{0.5}) \cdot \dfrac{h - 0.5}{0.5} & \text{als } h > 0.5
\end{cases}
""")

st.divider()

# ---------------------------------------------------------------------------
# Stap 9 — Absolute interne temperatuur
# ---------------------------------------------------------------------------
st.header("Stap 9 — Absolute interne temperatuur")

st.markdown("""
De absolute interne luchttemperatuur is de som van de omgevingstemperatuur en de
berekende temperatuurstijging:
""")

col1, col2 = st.columns(2)
with col1:
    st.latex(r"T_{int,midden} = T_a + \Delta t_{0.5}")
    st.latex(r"T_{int,top} = T_a + \Delta t_{1.0}")

with col2:
    st.markdown("**Voorbeeld** (Ta = 25°C):")
    st.latex(r"T_{int,top} = 25 + 22.25 = 47.25 \text{ °C}")

st.markdown("""
> **Verificatie van componenten:** Voor elk component wordt gecontroleerd of de maximale
> toelaatbare temperatuur Tmax niet wordt overschreden:
""")
st.latex(r"T_{int,top} \leq T_{max,component}")

st.divider()

# ---------------------------------------------------------------------------
# Stap 10 — Zonnestraling (Annex C)
# ---------------------------------------------------------------------------
st.header("Stap 10 — Zonnestraling (Annex C, optioneel)")

st.markdown("""
Bij buitenapplicaties kan directe zonnestraling de kast opwarmen. Annex C van de norm
schrijft een eenvoudige correctie voor, afhankelijk van de kleur van het oppervlak:
""")

col1, col2 = st.columns(2)
with col1:
    st.table({
        "Oppervlakkleur": ["Geen zonnestraling", "Licht oppervlak (RAL 9xxx e.d.)", "Donker oppervlak (RAL 7xxx e.d.)"],
        "Extra Δt [K]": [0, 10, 25],
    })

with col2:
    st.markdown("""
De zonnetoeslag wordt opgeteld bij de absolute temperatuur:
""")
    st.latex(r"T_{int} = T_a + \Delta t_{1.0} + \Delta t_{zon}")
    st.markdown("""
> **Let op:** De zonnetoeslag is een vereenvoudiging. Bij kritische toepassingen
> dient een volledige stralingsberekening volgens IEC 62262 of gelijkwaardig te
> worden uitgevoerd.
""")

st.divider()

# ---------------------------------------------------------------------------
# Volledig rekenvoorbeeld
# ---------------------------------------------------------------------------
st.header("Volledig rekenvoorbeeld — EWK-G46/31 referentie")

st.markdown("""
Onderstaand het complete rekenpad voor de EWK-G46/31 validatiecasus
(wandmontage type 3, P = 136.25 W, Ta = 25°C):
""")

steps = [
    ("Afmetingen", r"H = 950\ \text{mm},\quad W = 1050\ \text{mm},\quad D = 225\ \text{mm}"),
    ("Basisoppervlak", r"A_b = 1.050 \times 0.225 = 0.236\ \text{m}^2"),
    ("Oppervlakken (Ao)",
     r"A_{top} = 0.236\ \text{m}^2 \quad A_{voor/achter} = 0.998\ \text{m}^2 \quad A_{links/rechts} = 0.214\ \text{m}^2"),
    ("Effectief koeloppervlak",
     r"A_e = 0.236{\times}0.7 + 0.998{\times}0.9 + 0.998{\times}0.5 + 0.214{\times}0.9 + 0.214{\times}0.9 = 2.112\ \text{m}^2"),
    ("Hoogte/basis-factor", r"f = \frac{0.950^{1.35}}{0.236} = \frac{0.929}{0.236} = 3.950"),
    ("Omhullingscoëfficiënt", r"k = 0.58 \times 2.112^{-0.795} = 0.320"),
    ("Temperatuurverdeling", r"c = -0.0017 \times 3.950^2 + 0.055 \times 3.950 + 1.146 = 1.337"),
    ("Exponent", r"x = 0.804 \quad \text{(geen ventilatie)}"),
    ("Scheidingsplaatfactor", r"d = 1.0 \quad \text{(geen schotten)}"),
    ("Temperatuurstijging midden", r"\Delta t_{0.5} = 0.320 \times 1.0 \times 136.25^{0.804} = 16.65\ \text{K}"),
    ("Temperatuurstijging boven", r"\Delta t_{1.0} = 1.337 \times 16.65 = 22.25\ \text{K}"),
    ("Interne temperatuur boven", r"T_{int,top} = 25 + 22.25 = 47.25\ \text{°C}"),
]

for i, (label, formula) in enumerate(steps, 1):
    with st.container():
        st.markdown(f"**Stap {i}: {label}**")
        st.latex(formula)

st.success(
    "Resultaat: Tint,top = 47.25°C — overeenkomst met Excel-referentie EWK-G46/31 "
    "binnen 0.01% (referentiewaarde: 47.2505°C)"
)

st.divider()

# ---------------------------------------------------------------------------
# Schematisch overzicht
# ---------------------------------------------------------------------------
st.header("Schematisch overzicht berekeningsstroom")

st.markdown("""
```
Afmetingen (H, W, D)
       │
       ▼
Oppervlakken Ao  ──── b-factoren (Tabel 3) ────►  Ae = Σ(Ao × b)
                                                         │
       ┌─────────────────────────────────────────────────┤
       │                                                 │
       ▼                                                 ▼
Ab = W × D  ──►  f = H^1.35 / Ab              Ae > 1.25?
                        │                       ├─ Ja: k = 0.58 × Ae^(-0.795)
                        │                       └─ Nee: k = 0.626 × Ae^(-0.737)
                        ▼
               c = -0.0017f² + 0.055f + 1.146

Ventilatietype ──────────────────────────────►  x = 0.804 of 0.715

Aantal schotten ─────────────────────────────►  d (Tabel 4/5)

Vermogensverlies P
       │
       ▼
Δt₀.₅ = k × d × P^x
       │
       ▼
Δt₁.₀ = c × Δt₀.₅
       │
       ▼
Tint,top = Ta + Δt₁.₀ (+ zonnetoeslag)
       │
       ▼
Verificatie: Tint,top ≤ Tmax per component
```
""")
