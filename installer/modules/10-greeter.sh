#!/usr/bin/env bash
# 10-greeter.sh - Deploy das configurações do greetd / Noctalia Greeter

log_info "Configurando arquivos de sistema do greetd..."

mkdir -p /etc/greetd
cp "$REPO_DIR/.config/greetd/config.toml" /etc/greetd/config.toml
cp "$REPO_DIR/.config/greetd/pam_greetd" /etc/pam.d/greetd

mkdir -p /var/lib/noctalia-greeter
cp "$REPO_DIR/.config/greetd/greeter.toml" /var/lib/noctalia-greeter/greeter.toml
chown -R greeter:greeter /var/lib/noctalia-greeter 2>/dev/null || true
chmod 644 /var/lib/noctalia-greeter/greeter.toml

log_success "Greeter configurado."
