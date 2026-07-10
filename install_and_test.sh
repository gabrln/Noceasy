#!/bin/bash
source .venv/bin/activate
pip install pytest 2>&1
python3 -m pytest tests/ -v --tb=short 2>&1
