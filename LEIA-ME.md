# Lumen Cockpit — instalação

Este guia é para quem vai instalar o painel e nunca precisou abrir o Terminal.
Não é preciso saber nada de programação. São 5 passos e leva uns 10 minutos.

## O que isso faz

O **Mac** passa a mostrar um painel de botões no **iPad**. Cada toque no iPad
faz alguma coisa acontecer **no Mac** — abre um site no navegador do Mac, por
exemplo.

O iPad não mostra a tela do Mac. Ele é só um controle remoto, como aqueles
painéis de botões que streamers usam.

```
   iPad                              Mac
  (só o Safari)   ──── Wi-Fi ────>  (o site abre aqui)
   você toca                         a ação acontece
```

## Antes de começar

- O Mac e o iPad precisam estar **na mesma rede Wi-Fi**. É o único requisito.
- Tudo acontece dentro da sua casa. Nada é publicado na internet.

---

## Passo 1 — Baixar

Abra este endereço no navegador do **Mac**:

```
https://github.com/lpetineris/Lumenlabs-Cockpit-evandro
```

Clique no botão verde **Code** e depois em **Download ZIP**.

O arquivo vai para a pasta Downloads.

## Passo 2 — Abrir o arquivo baixado

Na pasta **Downloads**, dê **duplo clique** no arquivo `.zip` que acabou de
baixar. Ele vira uma pasta.

Abra essa pasta. Dentro dela existe um arquivo chamado **`Instalar.command`**.

## Passo 3 — Rodar o instalador

Aqui tem um detalhe do macOS que assusta, mas é normal.

Como este arquivo veio da internet e não é de uma loja da Apple, o Mac vai
desconfiar dele na primeira vez. **Não dê duplo clique ainda.** Faça assim:

1. Clique no `Instalar.command` segurando a tecla **Control** (ou clique com o
   botão direito).
2. Escolha **Abrir** no menu que aparecer.
3. Vai surgir um aviso dizendo que a Apple não conseguiu verificar o
   desenvolvedor. Clique em **Abrir** de novo.

**Se não aparecer a opção "Abrir"**, ou se o aviso só tiver o botão "OK", o seu
macOS é de uma versão mais nova e o caminho é outro:

1. Dê duplo clique normalmente e clique em **OK** no aviso.
2. Abra **Ajustes do Sistema** → **Privacidade e Segurança**.
3. Role até o fim. Vai ter uma linha dizendo que o `Instalar.command` foi
   bloqueado, com um botão **Abrir Assim Mesmo**. Clique nele.
4. Confirme com a sua senha ou Touch ID.

Isso é só na primeira vez.

Uma janela preta de texto vai abrir e o instalador começa a trabalhar sozinho.
Ele coloca o projeto no lugar certo e liga o painel.

> Se aparecer uma janela pedindo para instalar as **"Ferramentas de Linha de
> Comando"**, clique em **Instalar** e espere terminar — leva alguns minutos.
> Quando acabar, rode o `Instalar.command` de novo. Isso acontece em Macs que
> nunca foram usados para programar.

## Passo 4 — Anotar o endereço

Quando terminar, a janela preta vai mostrar um endereço parecido com este:

```
http://MacBook-de-Fulano.local:8787
```

**Anote esse endereço**, com o nome exato que apareceu na sua tela. Ele é
diferente em cada Mac.

Pode fechar a janela preta.

## Passo 5 — Colocar no iPad

No **iPad**:

1. Abra o **Safari**.
2. Digite o endereço que você anotou, com o `http://` na frente.
3. O painel aparece.
4. Toque no botão de **Compartilhar** (o quadrado com a seta para cima, no alto
   da tela).
5. Role e escolha **Adicionar à Tela de Início**.
6. Toque em **Adicionar**.

Agora existe um ícone do Cockpit na tela do iPad. Abrindo por ele, o painel
ocupa a tela inteira, sem a barra do Safari em cima.

**Use sempre o ícone**, não o Safari.

---

## Pronto. Duas dicas que fazem diferença

**Deixe o iPad sem apagar a tela.** Em Ajustes → Tela e Brilho → Bloqueio
Automático → **Nunca**. Sem isso o iPad apaga sozinho no meio do uso e você
precisa desbloquear toda hora.

**O painel liga sozinho.** Toda vez que o Mac liga, o painel volta ao ar. Você
não precisa rodar o instalador de novo, nunca mais.

## Trocar os botões

Toque na **engrenagem ⚙** no alto do painel. Dá para mudar nome, ícone, cor,
descrição e endereço de cada botão, mudar a ordem, acrescentar e apagar.

**Faça isso no Mac, não no iPad.** Abra `http://localhost:8787` no navegador do
Mac e mexa por lá. Digitar endereço de site no teclado da tela do iPad é
sofrimento.

São três listas, com os mesmos nomes que aparecem no painel: **Web** (os botões
grandes), **APPs** e **Extras** (os dois grupos de atalhos do lado). Salvou, o
iPad já obedece — é só recarregar.

## A cidade do clima

A barra de cima mostra o tempo. A cidade já vem configurada, mas se estiver
errada, peça para quem te passou o projeto trocar — é uma linha no arquivo
`blocos.json`, dentro da pasta `LumenCockpit` na sua Pasta Pessoal.

---

## Se der problema

**O painel não abre no iPad.**
Confirme que os dois estão na mesma rede Wi-Fi. Muita casa tem duas redes (uma
normal e uma "5G") — precisam ser a mesma. Confirme também que o Mac está
ligado e acordado: se o Mac dorme, o painel some.

**Aparece "não é possível conectar".**
Você provavelmente digitou o endereço sem o `http://` na frente, ou esqueceu o
`:8787` no fim. Os dois são obrigatórios.

**Funcionava e parou.**
Reinicie o Mac. O painel sobe sozinho no login.

**Toquei num botão e não aconteceu nada no Mac.**
O painel avisa na tela quando a ação dá certo ou falha. Se ele disser que o
programa não está instalado, é isso mesmo: aquele botão aponta para um
aplicativo que não existe nesse Mac. Troque o endereço do botão pela
engrenagem ⚙.

**Quero desligar tudo.**
O painel não instala nada pesado nem mexe em ajuste nenhum do sistema. Para
parar, apague a pasta `LumenCockpit` da sua Pasta Pessoal e reinicie o Mac.
