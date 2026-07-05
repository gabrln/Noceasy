#!/usr/bin/env bash
# 10-greeter.sh - Deploy das configurações do greetd / Noctalia Greeter

log_info "Configurando arquivos de sistema do greetd..."

# Garante que o usuário greeter exista
if ! id -u greeter &>/dev/null; then
  log_info "Criando usuário greeter..."
  useradd -r -s /usr/bin/nologin greeter
fi

mkdir -p /etc/greetd
cp "$REPO_DIR/.config/greetd/config.toml" /etc/greetd/config.toml
cp "$REPO_DIR/.config/greetd/pam_greetd" /etc/pam.d/greetd

mkdir -p /var/lib/noctalia-greeter
cp "$REPO_DIR/.config/greetd/greeter.toml" /var/lib/noctalia-greeter/greeter.toml
chown -R greeter:greeter /var/lib/noctalia-greeter 2>/dev/null || true
chmod 644 /var/lib/noctalia-greeter/greeter.toml

# Garante arquivos de log exigidos pelo Noctalia Greeter
touch /var/log/noctalia-greeter.log
chown greeter:greeter /var/log/noctalia-greeter.log 2>/dev/null || true
chmod 644 /var/log/noctalia-greeter.log

touch /var/lib/noctalia-greeter/greeter.log
chown greeter:greeter /var/lib/noctalia-greeter/greeter.log 2>/dev/null || true
chmod 644 /var/lib/noctalia-greeter/greeter.log

log_success "Greeter configurado."
