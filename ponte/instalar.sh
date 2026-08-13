#!/bin/zsh
# Liga a ponte do Cockpit no MacBook, ou reinicia depois de uma mudança.
#
# A ponte roda direto desta pasta — não existe cópia em outro lugar.
# É por isso que o projeto mora fora de Documentos: aquela pasta é protegida
# pelo macOS, e um serviço que sobe no login não consegue ler nada de lá.

set -e

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
AGENTE="$HOME/Library/LaunchAgents/com.lumenlabs.cockpit-ponte.plist"

# Guarda contra o erro que já nos custou tempo uma vez.
case "$RAIZ" in
  "$HOME/Documents"*|"$HOME/Desktop"*|"$HOME/Downloads"*)
    echo "ERRO: o projeto está em $RAIZ."
    echo "O macOS protege essa pasta e o serviço não conseguirá ler os arquivos"
    echo "quando iniciar sozinho no login. Mova o projeto para ~/LumenCockpit."
    exit 1
    ;;
esac

chmod +x "$RAIZ/ponte/abrir-claude-code.command"

cat > "$AGENTE" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lumenlabs.cockpit-ponte</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$RAIZ/ponte/servidor.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/cockpit-ponte.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/cockpit-ponte.log</string>
</dict>
</plist>
PLIST

launchctl unload "$AGENTE" 2>/dev/null || true
launchctl load "$AGENTE"

sleep 2
if curl -s -o /dev/null --max-time 5 http://localhost:8787/; then
  NOME=$(scutil --get LocalHostName 2>/dev/null)
  IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
  echo "Ponte no ar, servindo de $RAIZ"
  echo
  # O nome .local é o endereço a usar: o roteador pode trocar o IP a qualquer
  # momento (já trocou uma vez), e aí o app instalado no notebook para de abrir.
  echo "No notebook, use SEMPRE este endereço:"
  echo "    http://$NOME.local:8787"
  echo
  echo "  (o IP de hoje é $IP, mas ele muda — não use)"
else
  echo "A ponte não respondeu. Veja o log: cat /tmp/cockpit-ponte.log"
  exit 1
fi
