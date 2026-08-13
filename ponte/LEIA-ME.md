# A ponte

Faz o iPad virar um painel de botões do Mac — um Stream Deck. Nada da tela do
Mac é exibido no iPad. Ele só mostra o Cockpit e, a cada toque, a ação acontece
no Mac.

Dispensa Duet, dispensa segunda tela, dispensa assinatura.

## Como funciona

O Mac roda um servidor pequeno na porta 8787 que faz três coisas:

1. **Serve a página** do Cockpit para o iPad pela rede local
2. **Executa a ação** de cada bloco tocado — abre o site no navegador do Mac,
   ou abre o Claude Code
3. **Grava as mudanças** feitas na tela de ajuste dos botões

Como a página vem do próprio Mac, o toque e a ação ficam na mesma origem. Não
há navegador bloqueando nada no meio.

A engrenagem ⚙ é injetada aqui, pelo `ponte.js` — ela não existe no
`index.html`. Quem abrir o arquivo direto no disco vê o painel sem a tela de
ajuste, e é assim mesmo: sem a ponte não haveria onde gravar.

## Instalar

```bash
./ponte/instalar.sh
```

Sobe sozinho no login daí em diante.

Quem não usa Terminal instala pelo `Instalar.command` da raiz, que chama este
script depois de resolver o que o duplo clique exige: mover o projeto para
`~/LumenCockpit`, tirar a quarentena e checar as Ferramentas de Linha de
Comando. O guia é o [LEIA-ME.md](../LEIA-ME.md) da raiz.

**Editar a página não exige reinstalar.** O servidor lê o `index.html` do disco
a cada pedido — salvou, recarregou no iPad, já está lá. Só rode de novo se
mudar o projeto de pasta ou se o serviço cair.

## Instalar em outro Mac

Nada no projeto é fixo a uma máquina. O `instalar.sh` descobre a pasta, o nome
do Mac e o caminho do serviço; o app do Claude é aberto pelo identificador, que
o macOS resolve onde quer que ele esteja; e o `abrir-claude-code.command`
escolhe a pasta de trabalho na hora, entre `~/Documents/lumen-labs`,
`~/Projetos`, `~/Documents` e a pasta pessoal — a primeira que existir.

O destino **não pode** ser Documentos, Área de Trabalho ou Downloads — o
`instalar.sh` recusa, porque o macOS barra serviços de login nessas pastas.

Pré-requisito: as Ferramentas de Linha de Comando da Apple, que é o que faz o
`/usr/bin/python3` funcionar. Num Mac que nunca as instalou, o primeiro comando
dispara a instalação sozinho.

**Cada Mac tem a sua configuração.** Na primeira execução a ponte copia o
`blocos.json` para um `blocos.local.json`, que fica fora do git, e daí em diante
lê e grava só nele. O `git pull` nunca esbarra na sua configuração: o modelo
versionado não é mais tocado depois dessa cópia.

## No iPad

Abra no Safari:

```
http://NOME-DO-MAC.local:8787
```

O nome sai do `instalar.sh` ao final, ou de `scutil --get LocalHostName`.

**Use o nome, não o IP.** O roteador troca o IP do Mac sem avisar — já
aconteceu, e o atalho salvo parou de abrir. O nome `.local` é resolvido por
descoberta na rede (Bonjour, que o iOS já traz), então continua valendo
qualquer que seja o número do momento.

Depois, Compartilhar → **Adicionar à Tela de Início**. É o atalho que faz o
painel ocupar a tela inteira; abrindo pelo Safari sobra a barra de endereço.
Quem decide isso são as metatags `apple-mobile-web-app-*` do `index.html`, não
o `manifest.webmanifest` — o iOS ignora o manifest nessa hora.

## Segurança

- Só executa endereços que já estão na configuração desta máquina. A lista é
  lida do próprio arquivo a cada pedido, então não há uma segunda lista para
  manter em dia.
- Não existe caminho para rodar comando arbitrário. Um destino fora da lista é
  recusado.
- Todo pedido exige um token, gerado na primeira execução, guardado em
  `~/.lumen-cockpit-token` e entregue só junto com a página. Isso impede que um
  site qualquer aberto no iPad dispare ações no Mac por conta própria.
- O token é de cada máquina e nunca entra no git.
- O servidor escuta na rede local. Quem estiver na mesma rede e souber o token
  pode acionar os botões. Numa rede doméstica isso é aceitável; numa rede
  pública, desligue.

## Comandos úteis

Ver se está no ar (0 = rodando):

```bash
launchctl list | grep cockpit
```

Ver o log:

```bash
tail -20 /tmp/cockpit-ponte.log
```

Desligar por enquanto:

```bash
launchctl unload ~/Library/LaunchAgents/com.lumenlabs.cockpit-ponte.plist
```

Remover de vez:

```bash
launchctl unload ~/Library/LaunchAgents/com.lumenlabs.cockpit-ponte.plist && rm ~/Library/LaunchAgents/com.lumenlabs.cockpit-ponte.plist && rm ~/.lumen-cockpit-token
```
