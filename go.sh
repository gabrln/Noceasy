#!/bin/bash
. /home/gabrln/Projects/Noceasy/.venv/bin/activate
pip install pytest
python3 -m pytest tests/ -v --tb=short
