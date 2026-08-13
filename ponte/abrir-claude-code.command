#!/bin/zsh
# Aberto pela ponte quando o bloco "Claude Code" é tocado no notebook.
# Usar `open` neste arquivo evita pedir permissão de automação do macOS.
#
# Nada aqui é fixo a uma máquina: a pasta de trabalho é descoberta na hora,
# então o mesmo arquivo serve em qualquer Mac sem edição.

# Um script aberto pela ponte herda um PATH mínimo, sem os lugares onde o
# `claude` costuma ficar: ~/.local/bin no instalador nativo, /opt/homebrew/bin
# no Homebrew do Apple Silicon. Sem esta linha, um Mac com o Claude Code
# instalado seria reportado abaixo como se não tivesse.
PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

for pasta in ~/Documents/lumen-labs ~/Projetos ~/Documents "$HOME"; do
  if [ -d "$pasta" ]; then
    cd "$pasta"
    break
  fi
done

if ! command -v claude >/dev/null 2>&1; then
  echo
  echo "  O Claude Code não está instalado neste Mac."
  echo
  echo "  Para instalar:  curl -fsSL https://claude.ai/install.sh | bash"
  echo
  read "?  Pressione Enter para fechar."
  exit 1
fi

echo "Claude Code em $(pwd)"
exec claude
