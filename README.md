# Lumen Cockpit

Painel de botões do Mac, comandado de um iPad. O iPad mostra os blocos; cada
toque executa a ação **no Mac** — abre o site no navegador do Mac, ou abre o
Claude Code.

É um Stream Deck. Nada da tela do Mac é exibido no iPad.

Sem Duet, sem segunda tela, sem assinatura. O iPad precisa só do Safari.

## Instalar

**Se você não usa Terminal:** siga o [LEIA-ME.md](LEIA-ME.md). É um guia de
5 passos, sem uma linha de comando.

**Se você usa:**

```bash
./ponte/instalar.sh
```

O `Instalar.command` da raiz é a versão de duplo clique do mesmo processo, e
faz três coisas a mais: move o projeto para `~/LumenCockpit` (o ZIP do GitHub
cai em Downloads, onde o serviço não pode morar), tira a marca de quarentena
da cópia, e explica a instalação das Ferramentas de Linha de Comando quando
elas faltam.

Sobe sozinho no login daí em diante. Rode de novo só se mudar de pasta ou se o
serviço cair — **editar a página não exige reinstalar**, porque o servidor lê o
arquivo do disco a cada pedido.

## Como funciona

O Mac roda um servidor pequeno na porta 8787 que serve esta página para o iPad
e executa a ação de cada bloco tocado. Detalhes em
[ponte/LEIA-ME.md](ponte/LEIA-ME.md).

```
iPad (só o Safari)  ──HTTP──>  Mac (ponte + ação)
    toca no bloco              abre o site / abre o Claude Code
```

O endereço é o nome `.local` do Mac, nunca o IP — o roteador troca o número sem
avisar, e o atalho salvo no iPad para de abrir. Para descobrir o nome:
`scutil --get LocalHostName`.

## Arquivos

| Arquivo | O que faz |
|---|---|
| `LEIA-ME.md` | O guia de instalação, para quem nunca usou Terminal |
| `Instalar.command` | Instalação por duplo clique |
| `Verificar.command` | Diagnóstico por duplo clique, quando o iPad não abre |
| `blocos.json` | Modelo dos botões, de onde uma instalação nova parte |
| `blocos.local.json` | Os botões desta máquina — fora do git, criado na 1ª execução |
| `index.html` | A página: estrutura, estilo e a montagem da grade |
| `ponte/` | O servidor que roda no Mac, executa as ações e grava os botões |
| `manifest.webmanifest` | Dá nome e ícone ao atalho na Tela de Início do iPad |
| `favicon.svg`, `icon-*.png` | Marca das 5 barras em verde petróleo e laranja |

## Mexer nos botões

**Pela tela de ajuste**, que é o jeito normal: toque na engrenagem ⚙ no alto da
página. Ela cobre as três listas, com os mesmos nomes que aparecem no painel —
**Web** (a grade), **APPs** e **Extras** (os dois grupos de atalhos). Dá para
trocar nome, descrição, ícone, cor e endereço, mudar a ordem, acrescentar e
apagar. Salvou, o iPad já obedece.

A engrenagem vem da ponte, não do `index.html`: ela só existe na página servida
pelo Mac.

Faça isso no navegador do Mac (`localhost:8787`), não no iPad — digitar endereço
em teclado de tela é sofrimento.

A grade se reorganiza sozinha: 8 botões viram 4x2, 12 viram 4x3. O limite é 24.

**Pelo arquivo**, se preferir: os botões desta máquina vivem em
`blocos.local.json`, que a ponte cria na primeira execução copiando o
[blocos.json](blocos.json) do repositório. É o mesmo arquivo que a tela de
ajuste grava, que desenha a página e de onde a ponte tira os endereços que pode
abrir — uma fonte só, por máquina.

Como a configuração fica fora do git, `git pull` nunca esbarra nos seus botões,
e o modelo versionado não é mais tocado depois daquela primeira cópia.

Nem todo bloco precisa ser um site. Existem dois marcadores que a ponte traduz
em comando: `#claude-app` abre o aplicativo do Claude no Mac pelo identificador
— o Claude Code mora na aba Code desse aplicativo — e `#claude-code` abre o
Claude Code no Terminal. Digitar um deles no campo de endereço de qualquer
bloco faz esse bloco passar a fazer isso.

O modelo não usa nenhum dos dois: são só links, para uma instalação nova não
começar com um botão que depende de um programa instalado. Se o programa não
existir na máquina, o toque devolve uma mensagem explicando, em vez de falhar
em silêncio.

Cores disponíveis: `vermelho`, `amarelo`, `azul`, `laranja`, `verde`,
`violeta`, `coral`, `ambar`, `lima`, `turquesa`, `anil`, `magenta`, `vinho`,
`terra`, `musgo`, `marinho`, `grafite`, `chumbo`, `ardosia`, `pedra`.

## Clima

A barra de cima mostra a temperatura de agora, a condição e a máxima/mínima do
dia. Quem consulta é o navegador que está exibindo o painel, direto na
[open-meteo.com](https://open-meteo.com) — aberta, sem cadastro nem chave. A
ponte não participa: nenhuma rota nova no servidor, nenhum acesso ao Mac.

A cidade fica no `clima`, dentro do arquivo de configuração:

```json
"clima": { "nome": "São Paulo", "lat": -23.5505, "lon": -46.6333 }
```

A tela de ajuste não edita esse trecho, mas preserva as chaves que não conhece
— então ele sobrevive a qualquer gravação de botões. Para trocar de cidade,
edite o `blocos.local.json` e recarregue a página.

Se a consulta falhar, por falta de internet ou pela api fora do ar, o bloco some
e o resto do painel segue. Em pé a cidade e o subtítulo da marca saem, porque a
barra tem 1080 de largura em vez de 1920.

## No iPad

O atalho na Tela de Início é o que faz o painel ocupar a tela inteira. O iOS
ignora o `manifest.webmanifest` nessa hora — quem manda são as metatags
`apple-mobile-web-app-*` no `index.html`.

O botão ⛶ de tela cheia não aparece no iPad: o Safari não implementa a API de
tela cheia para elementos comuns, então lá ele não teria o que fazer. No
navegador do Mac ele continua.

Vale desligar o bloqueio automático do iPad (Ajustes → Tela e Brilho), senão a
tela apaga no meio do uso.

## O painel roda num iPad de 2012

Isto manda em decisões que de outro modo pareceriam esquisitas. O iPad que usa
este Cockpit está preso no **iOS 9.3.5** — a última versão dos iPads de 32 bits.
O Safari dele é de 2015 e não tem coisas que hoje são banais:

| Recurso | Chegou no Safari | O que se usa aqui |
|---|---|---|
| `fetch` | 10.1 | `XMLHttpRequest`, no `buscarJSON` e no `pedir` da ponte |
| CSS Grid | 10.1 | flexbox em todo o layout |
| `gap` em flexbox | 14.1 | `> * + * { margin-left }` |
| `aspect-ratio` | 15 | altura em pixels, que o canvas de largura fixa permite |
| `{once:true}` em listener | 10 | `removeEventListener` na mão |
| `Element.closest` | instável no 9 | subida manual pela árvore, no `ponte.js` |

**O `fetch` era o pior de todos**, e valeu um diagnóstico longo: ele não degrada
nada, ele derruba. Não existindo a função, a linha que carregava os botões
lançava `ReferenceError` e **o script inteiro parava ali** — inclusive o
dimensionamento do canvas, várias linhas abaixo. Sem ele a página ficava nos
1920px fixos e o iPad mostrava só o canto superior esquerdo, o que parecia
"o cabeçalho não aparece" e mandou a investigação para o lado errado duas vezes.

Se for mexer aqui: nada de `grid`, `gap`, `aspect-ratio`, `fetch`, arrow
functions, `let`/`const`, template literals ou spread. O que está escrito é ES5
e flexbox de propósito, e funciona igual nos navegadores de hoje — é um arquivo
só para os dois mundos, não uma versão degradada.

Variáveis CSS (`var(--cor)`) ficaram: essas o iOS 9.3 já tem.

## Layout

A página é desenhada numa largura fixa e ampliada por JS até preencher a
janela. Deitado essa largura é 1920, e numa tela 4K a escala é exatamente 2x. A
altura acompanha a janela, então não sobram faixas pretas em tela nenhuma.

**Em pé o layout muda.** Quando a janela fica mais alta que larga — o iPad
girado —, a largura base passa a 1080, a coluna lateral desce para baixo da
grade e os dois cartões dividem a largura. É só CSS sob `#canvas.retrato`; o JS
apenas marca a classe e mede.

**Tamanho dos blocos:** `.launch-grid`, em `grid-template-columns` — deitado,
colunas fixas de 200px, com quantas couberem por linha; em pé, 3 colunas
dividindo a largura, em `#canvas.retrato .launch-grid`.

## Por que o projeto mora em ~/LumenCockpit

A pasta Documentos é protegida pelo macOS: um serviço que inicia sozinho no
login não consegue ler nada de lá. Morando em `~/LumenCockpit`, o serviço lê o
projeto direto — uma fonte só.

O `instalar.sh` recusa rodar de Documentos, Área de Trabalho ou Downloads. O
`Instalar.command` não recusa: ele move o projeto para o lugar certo e segue.

## Isolamento

Repositório próprio, sem integração, sem chave de API. Os blocos são links; a
ponte só sabe abrir os endereços que estão na configuração desta máquina.
