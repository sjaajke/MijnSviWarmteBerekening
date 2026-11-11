#!/bin/bash
# Start IEC TR 60890:2022 warmteberekening app
cd "$(dirname "$0")"
python3 -m streamlit run app.py
