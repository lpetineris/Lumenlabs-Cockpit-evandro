#!/usr/bin/env python3
"""
Ponte do Lumen Cockpit.

Roda no MacBook. Faz duas coisas:

  1. Serve a página do Cockpit para o iPad, pela rede local.
  2. Executa no Mac a ação de cada bloco que for tocado no iPad.
  3. Grava as mudanças feitas na tela de ajuste dos botões.

O iPad não precisa de nada além do Safari. Nada é exibido do Mac
no iPad — ele é só um painel de botões, como um Stream Deck.

Segurança: só executa endereços presentes no blocos.local.json, que é o mesmo
arquivo que desenha a página. Não existe caminho para rodar comando
arbitrário. Todo pedido exige um token que só é entregue junto com a página.
"""

import http.server
import json
import secrets
import subprocess
import sys
from pathlib import Path

PASTA_PONTE = Path(__file__).resolve().parent
RAIZ = PASTA_PONTE.parent
PORTA = 8787
ARQUIVO_TOKEN = Path.home() / ".lumen-cockpit-token"
COMANDO_CLAUDE = PASTA_PONTE / "abrir-claude-code.command"


def obter_token() -> str:
    """Lê o token do disco, ou cria um na primeira execução."""
    if ARQUIVO_TOKEN.exists():
        gravado = ARQUIVO_TOKEN.read_text().strip()
        if gravado:
            return gravado
    novo = secrets.token_urlsafe(24)
    ARQUIVO_TOKEN.write_text(novo)
    ARQUIVO_TOKEN.chmod(0o600)
    return novo


TOKEN = obter_token()


# A configuração é de cada máquina: o iMac e o MacBook têm botões diferentes.
# O repositório traz o `blocos.json` como ponto de partida e não é mais tocado
# depois disso; cada Mac trabalha no seu `blocos.local.json`, que fica fora do
# git. É o que permite atualizar o projeto com `git pull` sem que a configuração
# de uma máquina entre em conflito com a da outra.
ARQUIVO_MODELO = RAIZ / "blocos.json"
ARQUIVO_BLOCOS = RAIZ / "blocos.local.json"


def garantir_config() -> None:
    """
    Na primeira execução desta máquina, parte do modelo do repositório.

    Chamada também a cada leitura, e não só na partida: o arquivo local fica
    fora do git, então nada impede que ele suma no meio do caminho. Sem isto a
    página passaria a mostrar "não consegui ler o blocos.json" até alguém
    reiniciar o serviço na mão.
    """
    if not ARQUIVO_BLOCOS.exists() and ARQUIVO_MODELO.exists():
        ARQUIVO_BLOCOS.write_text(
            ARQUIVO_MODELO.read_text(encoding="utf-8"), encoding="utf-8")


garantir_config()


CORES = {
    # primárias · secundárias · terciárias · profundas · neutras
    "vermelho", "amarelo", "azul",
    "laranja", "verde", "violeta",
    "coral", "ambar", "lima", "turquesa", "anil", "magenta",
    "vinho", "terra", "musgo", "marinho",
    "grafite", "chumbo", "ardosia", "pedra",
}

# Ações que não são um site. O bloco usa o marcador (com #) como endereço; a
# ponte traduz para o comando. Acrescentar uma ação é acrescentar uma linha aqui.
ACOES_LOCAIS = {
    "claude-code": (
        lambda: ["open", str(COMANDO_CLAUDE)],
        "Claude Code abrindo no Terminal",
    ),
    "claude-app": (
        # Pelo identificador, não pelo caminho: o macOS acha o app onde quer
        # que ele esteja, e o mesmo repositório roda em qualquer Mac.
        lambda: ["open", "-b", "com.anthropic.claudefordesktop"],
        "Claude abrindo no Mac",
    ),
}
MARCADORES = {"#" + nome for nome in ACOES_LOCAIS}

# Os marcadores existem sempre, mesmo que o programa não esteja instalado nesta
# máquina. É de propósito: mantém o blocos.json portátil entre Macs, e quem não
# tiver o programa recebe uma mensagem clara em vez de um bloco recusado.
FALHAS = {
    "claude-app": "O app do Claude não está instalado neste Mac",
    "claude-code": "Não consegui abrir o Terminal",
}


def ler_config() -> dict:
    garantir_config()
    return json.loads(ARQUIVO_BLOCOS.read_text(encoding="utf-8"))


def enderecos_permitidos() -> set:
    """
    Lida do blocos.json a cada pedido: é o mesmo arquivo que desenha a página e
    que a tela de ajuste grava. Trocar um link já muda o que a ponte aceita, sem
    nenhuma segunda lista para manter em dia.
    """
    config = ler_config()
    urls = set()
    for chave in ("blocos", "apps", "status"):
        for item in config.get(chave, []):
            acao = item.get("acao", "")
            if acao.startswith("https://"):
                urls.add(acao)
    site = config.get("site", {}).get("acao", "")
    if site.startswith("https://"):
        urls.add(site)
    return urls


def validar_lista(itens, rotulo: str, maximo: int, com_icone: bool, com_cor: bool) -> list:
    """Valida uma das listas editáveis. Devolve uma versão limpa, campo a campo."""
    if not isinstance(itens, list):
        raise ValueError(f"'{rotulo}' precisa ser uma lista")
    if len(itens) > maximo:
        raise ValueError(f"no máximo {maximo} itens em {rotulo}")

    limpos = []
    for i, item in enumerate(itens, 1):
        if not isinstance(item, dict):
            raise ValueError(f"item {i} de {rotulo} malformado")

        nome = str(item.get("nome", "")).strip()
        if not nome:
            raise ValueError(f"o item {i} de {rotulo} está sem nome")

        acao = str(item.get("acao", "")).strip()
        if acao not in MARCADORES and not acao.startswith("https://"):
            marcadores = ", ".join(sorted(MARCADORES))
            raise ValueError(
                f"o endereço de '{nome}' precisa começar com https:// "
                f"ou ser um destes marcadores: {marcadores}")

        limpo = {"nome": nome[:40], "acao": acao}

        if com_cor:
            # A página cai em `pedra` para quem não tem cor gravada; o padrão
            # daqui é o mesmo, senão os atalhos do segundo grupo — que nunca
            # tiveram cor — mudariam de tom sozinhos na primeira gravação.
            cor = str(item.get("cor", "pedra"))
            if cor not in CORES:
                raise ValueError(f"cor desconhecida em '{nome}': {cor}")
            limpo["cor"] = cor

        if com_icone:
            limpo["descricao"] = str(item.get("descricao", "")).strip()[:60]
            limpo["icone"] = (str(item.get("icone", "")).strip() or "•")[:4]
            selo = str(item.get("selo", "")).strip()
            if selo:
                limpo["selo"] = selo[:20]

        limpos.append(limpo)
    return limpos


def validar_config(config) -> dict:
    """Recusa qualquer coisa que não seja uma configuração bem formada."""
    if not isinstance(config, dict):
        raise ValueError("a configuração precisa ser um objeto")

    # parte do arquivo em disco: o que não vier no pedido fica como está
    novo = ler_config()

    novo["blocos"] = validar_lista(
        config.get("blocos"), "botões da grade", 24, com_icone=True, com_cor=True)

    if "apps" in config:
        novo["apps"] = validar_lista(
            config.get("apps"), "seus apps no ar", 20, com_icone=False, com_cor=True)

    # Os dois grupos de atalhos aceitam exatamente os mesmos campos. O segundo
    # já guardou só páginas de status e por isso não tinha cor; o que cada um
    # guarda passou a variar de máquina para máquina, então nenhum dos dois
    # manda menos que o outro.
    if "status" in config:
        novo["status"] = validar_lista(
            config.get("status"), "segundo grupo de atalhos", 20, com_icone=False, com_cor=True)

    return novo


HISTORICO = 5


def gravar_config(config: dict) -> None:
    """
    Grava com troca atômica, para nunca deixar o arquivo pela metade, e guarda
    as últimas versões.

    São cinco cópias, e não uma, porque em 10/08/2026 três cores foram
    corrompidas e o estrago só apareceu no dia seguinte. Com uma cópia só, a
    primeira gravação posterior teria apagado a última versão boa.
    """
    if ARQUIVO_BLOCOS.exists():
        for n in range(HISTORICO - 1, 0, -1):
            anterior = RAIZ / f"{ARQUIVO_BLOCOS.name}.bak{n}"
            if anterior.exists():
                anterior.replace(RAIZ / f"{ARQUIVO_BLOCOS.name}.bak{n + 1}")
        (RAIZ / f"{ARQUIVO_BLOCOS.name}.bak1").write_text(
            ARQUIVO_BLOCOS.read_text(encoding="utf-8"), encoding="utf-8")

    temporario = RAIZ / f"{ARQUIVO_BLOCOS.name}.tmp"
    temporario.write_text(
        json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporario.replace(ARQUIVO_BLOCOS)


def executar(destino: str) -> str:
    """Executa a ação no Mac. Devolve a mensagem que o iPad vai mostrar."""
    if destino in ACOES_LOCAIS:
        montar_comando, mensagem = ACOES_LOCAIS[destino]
        # `open` devolve na hora, então dá para esperar e saber se deu certo.
        # Sem isso, um programa ausente falharia em silêncio no iPad.
        concluido = subprocess.run(montar_comando(), capture_output=True,
                                   text=True, timeout=15)
        if concluido.returncode != 0:
            raise RuntimeError(FALHAS.get(destino, "o comando falhou"))
        return mensagem

    if destino in enderecos_permitidos():
        subprocess.Popen(["open", destino])
        return "Aberto no MacBook"

    raise ValueError(f"destino fora da lista: {destino}")


SCRIPT_CLIENTE = PASTA_PONTE / "ponte.js"


class Manipulador(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(RAIZ), **kwargs)

    def log_message(self, formato, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), formato % args))

    # ── entrega de arquivos ──

    def do_GET(self):
        caminho = self.path.split("?")[0]

        if caminho in ("/", "/index.html"):
            return self.entregar_pagina()

        if caminho == "/ponte.js":
            return self.entregar_script()

        if caminho == "/blocos.json":
            return self.entregar_config()

        return super().do_GET()

    def entregar_pagina(self):
        """Serve o index.html com o script da ponte acrescentado no fim."""
        html = (RAIZ / "index.html").read_text(encoding="utf-8")
        html = html.replace("</body>", '<script src="/ponte.js"></script>\n</body>')
        corpo = html.encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(corpo)

    def entregar_config(self):
        """
        A página pede `blocos.json`, mas quem manda é a configuração desta
        máquina. Sem este desvio, a entrega de arquivos estáticos devolveria o
        modelo do repositório e a página mostraria botões que não são os seus.
        """
        garantir_config()
        corpo = ARQUIVO_BLOCOS.read_bytes()

        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(corpo)

    def entregar_script(self):
        """O token vai embutido aqui — é a única via de entrega."""
        js = SCRIPT_CLIENTE.read_text(encoding="utf-8")
        js = js.replace("__TOKEN__", TOKEN)
        corpo = js.encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/javascript; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(corpo)

    # ── execução das ações ──

    def do_POST(self):
        caminho = self.path.split("?")[0]
        if caminho not in ("/acao", "/blocos"):
            return self.responder(404, {"erro": "endereço desconhecido"})

        tamanho = int(self.headers.get("Content-Length") or 0)
        if tamanho > 65536:
            return self.responder(413, {"erro": "pedido grande demais"})

        try:
            pedido = json.loads(self.rfile.read(tamanho) or b"{}")
        except json.JSONDecodeError:
            return self.responder(400, {"erro": "pedido malformado"})

        if not secrets.compare_digest(str(pedido.get("token", "")), TOKEN):
            return self.responder(403, {"erro": "token inválido"})

        if caminho == "/blocos":
            return self.salvar_blocos(pedido)

        try:
            mensagem = executar(str(pedido.get("destino", "")))
        except ValueError as erro:
            return self.responder(400, {"erro": str(erro)})
        except RuntimeError as erro:  # o programa não existe nesta máquina
            return self.responder(500, {"erro": str(erro)})
        except Exception as erro:  # falha inesperada ao chamar o `open`
            return self.responder(500, {"erro": f"o Mac não conseguiu executar: {erro}"})

        return self.responder(200, {"ok": True, "mensagem": mensagem})

    def salvar_blocos(self, pedido):
        try:
            config = validar_config(pedido.get("config"))
        except ValueError as erro:
            return self.responder(400, {"erro": str(erro)})

        try:
            gravar_config(config)
        except Exception as erro:
            return self.responder(500, {"erro": f"não consegui gravar: {erro}"})

        return self.responder(200, {"ok": True, "mensagem": "Blocos salvos", "config": config})

    def responder(self, codigo: int, dados: dict):
        corpo = json.dumps(dados, ensure_ascii=False).encode("utf-8")
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corpo)))
        self.end_headers()
        self.wfile.write(corpo)


def main():
    servidor = http.server.ThreadingHTTPServer(("0.0.0.0", PORTA), Manipulador)
    print(f"Ponte do Cockpit no ar na porta {PORTA}", flush=True)
    print(f"Token guardado em {ARQUIVO_TOKEN}", flush=True)
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print("encerrando", flush=True)
        servidor.shutdown()


if __name__ == "__main__":
    main()
