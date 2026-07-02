#!/bin/bash
set -e

echo "=== Iniciando Configuração do decman ==="

# 1. Verificar se o yay está instalado
if ! command -v yay &>/dev/null; then
    echo "Erro: 'yay' não encontrado. Por favor, instale o yay primeiro." >&2
    exit 1
fi

# 2. Instalar o decman do AUR caso não esteja instalado
if ! command -v decman &>/dev/null; then
    echo "Instalando decman do AUR..."
    yay -S --needed --noconfirm decman
else
    echo "decman já está instalado."
fi

# 3. Informar próximos passos
echo ""
echo "=== Instalação Concluída ==="
echo "Para simular as alterações e verificar as diferenças:"
echo "  sudo decman --source $(pwd)/source.py --dry-run"
echo ""
echo "Para aplicar as configurações declarativas (requer permissão de root):"
echo "  sudo decman --source $(pwd)/source.py"
echo "========================================"
