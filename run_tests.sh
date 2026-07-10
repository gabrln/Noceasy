#!/bin/bash
set -e

# Activate venv
source .venv/bin/activate

echo "=== Command 1: pip install pytest ==="
pip install pytest

echo ""
echo "=== Command 2: python3 -m pytest tests/ -v --tb=short ==="
python3 -m pytest tests/ -v --tb=short
