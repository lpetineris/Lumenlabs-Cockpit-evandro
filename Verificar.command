#!/bin/zsh
# ─────────────────────────────────────────────────────────────────────────────
# Diagnóstico do Lumen Cockpit, por duplo clique.
#
# Existe porque "o iPad não abre" tem meia dúzia de causas possíveis e nenhuma
# delas dá para adivinhar de longe. Este arquivo responde, em ordem, as
# perguntas que separam uma da outra: o serviço está carregado? a página
# responde no próprio Mac? qual é o endereço de hoje? o Mac está no Wi-Fi?
#
# Só lê e imprime. Não muda nada, não instala nada, não desliga nada.
# ─────────────────────────────────────────────────────────────────────────────

RAIZ="$(cd "$(dirname "$0")" && pwd)"
AGENTE="$HOME/Library/LaunchAgents/com.lumenlabs.cockpit-ponte.plist"
PROBLEMAS=0

echo
echo "  ┌──────────────────────────────────────────┐"
echo "  │        LUMEN COCKPIT — Verificação       │"
echo "  └──────────────────────────────────────────┘"
echo

# ── 1. O projeto está no lugar certo? ────────────────────────────────────────
echo "  1. Pasta do projeto"
if [ "$RAIZ" = "$HOME/LumenCockpit" ]; then
  echo "     OK — $RAIZ"
else
  echo "     ATENÇÃO — este arquivo está em:"
  echo "     $RAIZ"
  echo "     A instalação de verdade fica em ~/LumenCockpit."
  echo "     Se você está rodando isto da pasta de Downloads, rode o"
  echo "     Instalar.command primeiro."
  PROBLEMAS=$((PROBLEMAS+1))
fi
echo

# ── 2. O serviço está carregado? ─────────────────────────────────────────────
echo "  2. Serviço da ponte"
if [ ! -f "$AGENTE" ]; then
  echo "     FALHOU — o serviço nunca foi instalado."
  echo "     Rode o Instalar.command."
  PROBLEMAS=$((PROBLEMAS+1))
elif launchctl list 2>/dev/null | grep -q "com.lumenlabs.cockpit-ponte"; then
  # A segunda coluna do launchctl é o último código de saída. Diferente de 0
  # quer dizer que o serviço subiu e morreu — quase sempre erro de Python.
  SAIDA=$(launchctl list 2>/dev/null | grep "com.lumenlabs.cockpit-ponte" | awk '{print $2}')
  if [ "$SAIDA" = "0" ]; then
    echo "     OK — carregado e sem erro"
  else
    echo "     FALHOU — o serviço subiu e morreu (código $SAIDA)."
    echo "     O motivo costuma estar no log, no fim desta tela."
    PROBLEMAS=$((PROBLEMAS+1))
  fi
else
  echo "     FALHOU — o serviço não está carregado."
  echo "     Rode o Instalar.command."
  PROBLEMAS=$((PROBLEMAS+1))
fi
echo

# ── 3. A página responde aqui no próprio Mac? ────────────────────────────────
#
# Este é o teste que separa "o painel está quebrado" de "o iPad não chega até
# ele": se responde aqui e não no iPad, o problema é de rede, não do Cockpit.
echo "  3. A página responde no Mac"
CODIGO=$(curl -s -o /dev/null --max-time 5 -w "%{http_code}" http://localhost:8787/ 2>/dev/null)
if [ "$CODIGO" = "200" ]; then
  echo "     OK — o painel está no ar nesta máquina"
else
  echo "     FALHOU — nada respondeu na porta 8787."
  PROBLEMAS=$((PROBLEMAS+1))
fi
echo

# ── 4. O endereço para digitar no iPad ───────────────────────────────────────
echo "  4. Endereço do iPad"
NOME=$(scutil --get LocalHostName 2>/dev/null)
if [ -n "$NOME" ]; then
  echo "     http://$NOME.local:8787"
else
  echo "     Não consegui descobrir o nome desta máquina."
  PROBLEMAS=$((PROBLEMAS+1))
fi
echo

# ── 5. Rede ──────────────────────────────────────────────────────────────────
#
# O nome .local só é resolvido dentro da mesma rede. Mac no cabo e iPad no
# Wi-Fi de visitantes é a causa mais comum de "não abre" com tudo funcionando.
echo "  5. Rede"
RESUMO=""
for IFACE in en0 en1 en2; do
  IP=$(ipconfig getifaddr $IFACE 2>/dev/null)
  if [ -n "$IP" ]; then
    WIFI=$(networksetup -getairportnetwork $IFACE 2>/dev/null | sed 's/^Current Wi-Fi Network: //')
    case "$WIFI" in
      *"not associated"*|*"disabled"*|"") RESUMO="$RESUMO\n     $IFACE: $IP (cabo)" ;;
      *) RESUMO="$RESUMO\n     $IFACE: $IP · Wi-Fi \"$WIFI\"" ;;
    esac
  fi
done
if [ -n "$RESUMO" ]; then
  printf "$RESUMO\n"
  echo
  echo "     O iPad precisa estar nesta MESMA rede."
else
  echo "     FALHOU — este Mac não está em rede nenhuma."
  PROBLEMAS=$((PROBLEMAS+1))
fi
echo

# ── 6. Sono ──────────────────────────────────────────────────────────────────
echo "  6. Sono do Mac"
if pmset -g 2>/dev/null | grep -qE "^ *sleep +0"; then
  echo "     OK — este Mac não dorme sozinho"
else
  MIN=$(pmset -g 2>/dev/null | grep -E "^ *sleep " | awk '{print $2}')
  echo "     Este Mac dorme depois de ${MIN:-?} minutos."
  echo "     Enquanto ele dorme, o painel some do iPad. Se isso incomodar:"
  echo "     Ajustes do Sistema → Bateria (ou Economia de Energia)."
fi
echo

# ── 7. Log ───────────────────────────────────────────────────────────────────
echo "  7. Últimas linhas do log"
if [ -f /tmp/cockpit-ponte.log ]; then
  tail -12 /tmp/cockpit-ponte.log | sed 's/^/     /'
else
  echo "     (o log ainda não existe)"
fi
echo

# ── Veredito ─────────────────────────────────────────────────────────────────
echo "  ────────────────────────────────────────────"
if [ "$PROBLEMAS" -eq 0 ]; then
  echo "  Nada errado deste lado."
  echo
  echo "  O painel está no ar. Se o iPad ainda não abre, o problema"
  echo "  está entre os dois: rede diferente, ou o endereço digitado"
  echo "  sem o http:// na frente ou sem o :8787 no fim."
  echo
  echo "  Teste no próprio Mac, no navegador:  http://localhost:8787"
else
  echo "  $PROBLEMAS ponto(s) para resolver, marcados acima."
fi
echo "  ────────────────────────────────────────────"
echo
echo "  Pressione Enter para fechar."
read _ || true
