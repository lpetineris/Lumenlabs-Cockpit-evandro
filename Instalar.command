#!/bin/zsh
# ─────────────────────────────────────────────────────────────────────────────
# Instalador de duplo clique do Lumen Cockpit.
#
# Existe para quem nunca abriu o Terminal. O `ponte/instalar.sh` continua
# valendo e faz o trabalho de fato; este arquivo é a porta de entrada, e cuida
# dos três tropeços que aparecem quando o projeto chega pelo ZIP do GitHub:
#
#   1. O ZIP cai em Downloads, e o instalador recusa rodar de lá — o macOS
#      barra serviços de login nessa pasta. Em vez de mostrar o erro e parar,
#      aqui a gente move o projeto para ~/LumenCockpit e segue.
#   2. A pasta do ZIP vem com nome de release (algo-main). O destino é sempre
#      ~/LumenCockpit, com nome limpo.
#   3. Num Mac que nunca compilou nada falta o /usr/bin/python3 de verdade.
#      A checagem abaixo explica isso em vez de morrer com "command not found".
#
# Reinstalar é seguro: a configuração de botões (blocos.local.json) é
# preservada, porque ela é do dono da máquina e não do repositório.
# ─────────────────────────────────────────────────────────────────────────────

set -e

ORIGEM="$(cd "$(dirname "$0")" && pwd)"
DESTINO="$HOME/LumenCockpit"

# A segunda passagem (depois de mover o projeto) é continuação da primeira, não
# uma instalação nova — repetir o cabeçalho ali daria a impressão de que algo
# recomeçou do zero.
if [ -z "$COCKPIT_CONTINUANDO" ]; then
  echo
  echo "  ┌──────────────────────────────────────────┐"
  echo "  │           LUMEN COCKPIT                  │"
  echo "  │           Instalação                     │"
  echo "  └──────────────────────────────────────────┘"
  echo
fi

# ── 1. Levar o projeto para ~/LumenCockpit ───────────────────────────────────
#
# Só faz sentido se ainda não estivermos lá. Quando o script já roda do
# destino, esta parte inteira é pulada e a instalação segue direto.
if [ "$ORIGEM" != "$DESTINO" ]; then
  echo "  Colocando o projeto em ~/LumenCockpit..."

  if [ -d "$DESTINO" ]; then
    # Já existe uma instalação. Os botões dele ficam em blocos.local.json,
    # fora do git — guardamos para devolver depois da cópia, senão uma
    # atualização apagaria a configuração da pessoa.
    GUARDADO=""
    if [ -f "$DESTINO/blocos.local.json" ]; then
      GUARDADO="$(mktemp)"
      cp "$DESTINO/blocos.local.json" "$GUARDADO"
      echo "  Guardando os seus botões..."
    fi

    # A instalação anterior sai da frente com data no nome, em vez de ser
    # apagada: se algo der errado aqui, nada foi perdido de verdade.
    ANTIGA="$HOME/LumenCockpit-anterior-$(date +%Y%m%d-%H%M%S)"
    mv "$DESTINO" "$ANTIGA"
    echo "  A instalação anterior foi para $(basename "$ANTIGA")"

    mkdir -p "$DESTINO"
    cp -R "$ORIGEM/." "$DESTINO/"

    if [ -n "$GUARDADO" ]; then
      cp "$GUARDADO" "$DESTINO/blocos.local.json"
      rm -f "$GUARDADO"
      echo "  Seus botões foram mantidos."
    fi
  else
    mkdir -p "$DESTINO"
    cp -R "$ORIGEM/." "$DESTINO/"
  fi

  # O macOS marca tudo que veio da internet como "em quarentena" e pede
  # confirmação a cada execução. Como a cópia em ~/LumenCockpit foi feita aqui,
  # por decisão de quem está instalando, a marca sai e o Mac para de perguntar.
  xattr -dr com.apple.quarantine "$DESTINO" 2>/dev/null || true

  chmod +x "$DESTINO/Instalar.command" "$DESTINO/ponte/instalar.sh" \
           "$DESTINO/ponte/abrir-claude-code.command" 2>/dev/null || true

  echo "  Pronto."
  echo

  # Daqui em diante quem manda é a cópia no lugar certo. O `exec` troca este
  # processo por ela, então a instalação continua sem duplicar mensagem.
  COCKPIT_CONTINUANDO=1 exec "$DESTINO/Instalar.command"
fi

# ── 2. O Python que o macOS traz ─────────────────────────────────────────────
#
# /usr/bin/python3 existe em todo Mac, mas num Mac novo ele é só um atalho que
# dispara a instalação das Ferramentas de Linha de Comando da Apple. Sem elas
# a ponte não sobe, e o erro que aparece sozinho não explica nada.
if ! /usr/bin/python3 --version >/dev/null 2>&1; then
  echo "  Falta um componente da Apple neste Mac."
  echo
  echo "  Vai aparecer uma janela pedindo para instalar as"
  echo "  \"Ferramentas de Linha de Comando\". Clique em Instalar,"
  echo "  espere terminar (leva alguns minutos) e depois dê"
  echo "  duplo clique neste instalador de novo."
  echo
  xcode-select --install 2>/dev/null || true
  echo "  Pressione Enter para fechar."
  read _ || true
  exit 1
fi

# ── 3. Ligar a ponte ─────────────────────────────────────────────────────────
echo "  Ligando o painel..."
echo

chmod +x "$DESTINO/ponte/instalar.sh"
"$DESTINO/ponte/instalar.sh"

# ── 4. Dizer o endereço, que é a única coisa que ele precisa anotar ──────────
NOME=$(scutil --get LocalHostName 2>/dev/null)

echo
echo "  ┌──────────────────────────────────────────┐"
echo "  │  No iPad, abra o Safari e digite:        │"
echo "  └──────────────────────────────────────────┘"
echo
echo "      http://$NOME.local:8787"
echo
echo "  Depois toque em Compartilhar e em"
echo "  \"Adicionar à Tela de Início\"."
echo
echo "  O painel sobe sozinho toda vez que o Mac liga."
echo "  Não precisa rodar isto de novo."
echo
echo "  Pressione Enter para fechar."
read _ || true
