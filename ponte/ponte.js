/* Roda só quando a página é servida pela ponte, no MacBook.

   Faz duas coisas:
     1. Intercepta o toque nos blocos e atalhos e manda a ação para o Mac
        executar, em vez de abrir qualquer coisa aqui no iPad.
     2. Oferece a tela de ajuste (a engrenagem no topo), que edita as três
        listas: os botões da grade, os apps no ar e o status dos serviços.

   A tela de ajuste mora aqui, e não no index.html, porque sem a ponte não
   haveria onde gravar as mudanças. */

(function () {
  var TOKEN = '__TOKEN__';
  var canvas = document.getElementById('canvas');
  if (!canvas) return;

  // Ordem por grupo do círculo cromático, não por matiz. As amostras aparecem
  // na sequência em que a teoria de cor as apresenta.
  var CORES = [
    'vermelho', 'amarelo', 'azul',                                    // primárias
    'laranja', 'verde', 'violeta',                                    // secundárias
    'coral', 'ambar', 'lima', 'turquesa', 'anil', 'magenta',          // terciárias
    'vinho', 'terra', 'musgo', 'marinho',                             // profundas
    'grafite', 'chumbo', 'ardosia', 'pedra'                           // neutras
  ];

  /* Cada seção declara quais campos mostra. O desenho da linha é um só,
     parametrizado por isto — não existe um editor por lista. */
  var SECOES = [
    {
      chave: 'blocos',
      titulo: 'Web',
      icone: true, descricao: true, cor: true,
      novo: function () { return { nome: '', descricao: '', icone: '✦', cor: 'azul', acao: 'https://' }; }
    },
    /* Os dois grupos de atalhos são idênticos em capacidade — o segundo já não
       aceitou cor um dia. Os títulos aqui repetem os da página, para não
       obrigar ninguém a adivinhar qual lista é qual. */
    {
      chave: 'apps',
      titulo: 'APPs',
      icone: false, descricao: false, cor: true,
      novo: function () { return { nome: '', cor: 'azul', acao: 'https://' }; }
    },
    {
      chave: 'status',
      titulo: 'Extras',
      icone: false, descricao: false, cor: true,
      novo: function () { return { nome: '', cor: 'azul', acao: 'https://' }; }
    }
  ];

  function pedir(caminho, corpo) {
    return fetch(caminho, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(Object.assign({ token: TOKEN }, corpo))
    }).then(function (r) {
      return r.json().then(function (dados) {
        if (!r.ok) throw new Error(dados.erro || 'o MacBook recusou');
        return dados;
      });
    });
  }

  /* ─────────────────────────────────────────────
     1. Aviso de confirmação

     Como nada acontece na tela do iPad, este aviso é essencial:
     sem ele você não sabe se o toque foi registrado.
     ───────────────────────────────────────────── */

  var aviso = document.createElement('div');
  aviso.style.cssText = [
    'position:absolute', 'left:50%', 'bottom:44px',
    'transform:translateX(-50%) translateY(14px)',
    'padding:14px 28px', 'border-radius:100px',
    'background:rgba(20,20,18,.94)', 'border:1px solid rgba(255,255,255,.14)',
    'color:#F2F1EC', "font-family:'Plus Jakarta Sans','Inter',sans-serif",
    'font-size:17px', 'font-weight:600', 'letter-spacing:-.01em',
    'z-index:99', 'opacity:0', 'pointer-events:none', 'white-space:nowrap',
    'box-shadow:0 12px 32px -12px rgba(0,0,0,.6)'
  ].join(';');
  canvas.appendChild(aviso);

  var relogioAviso;
  function mostrar(texto, erro) {
    aviso.textContent = texto;
    aviso.style.borderColor = erro ? 'rgba(233,120,73,.55)' : 'rgba(255,255,255,.14)';
    aviso.style.color = erro ? '#F0A47F' : '#F2F1EC';
    aviso.style.transition = 'opacity .14s ease, transform .14s ease';
    aviso.style.opacity = '1';
    aviso.style.transform = 'translateX(-50%) translateY(0)';
    clearTimeout(relogioAviso);
    relogioAviso = setTimeout(function () {
      aviso.style.opacity = '0';
      aviso.style.transform = 'translateX(-50%) translateY(14px)';
    }, erro ? 4000 : 1900);
  }

  /* ─────────────────────────────────────────────
     2. Os toques viram ações no Mac
     ───────────────────────────────────────────── */

  canvas.addEventListener('click', function (evento) {
    var link = evento.target.closest('a[href]');
    if (!link) return;

    var href = link.getAttribute('href');
    var destino;

    // Qualquer marcador com # vira uma ação local. Quem decide se ela existe é o
    // Mac, não esta página — assim criar uma ação nova não exige mexer aqui.
    if (href.charAt(0) === '#' && href.length > 1) destino = href.slice(1);
    else if (href.indexOf('https://') === 0) destino = href;
    else return;

    evento.preventDefault();

    pedir('/acao', { destino: destino })
      .then(function (d) { mostrar(d.mensagem || 'Feito no MacBook'); })
      .catch(function (e) { mostrar(e.message || 'Sem resposta do MacBook', true); });
  });

  /* ─────────────────────────────────────────────
     3. Tela de ajuste

     Fica fora do canvas de propósito. O canvas é ampliado por JS para
     preencher a tela, e um formulário ampliado junto ficaria com campos
     de tamanho estranho. Aqui os campos têm tamanho real.
     ───────────────────────────────────────────── */

  var estilo = document.createElement('style');
  estilo.textContent = [
    '#ed-fundo{position:fixed;inset:0;z-index:9999;background:rgba(8,8,7,.86);',
    '  display:none;overflow-y:auto;padding:32px 20px;',
    "  font-family:'Inter',-apple-system,sans-serif;}",
    '#ed-fundo.aberto{display:block;}',
    '#ed-caixa{max-width:940px;margin:0 auto;background:#141412;',
    '  border:1px solid rgba(255,255,255,.11);border-radius:20px;padding:28px 30px 24px;}',
    "#ed-caixa h2{font-family:'Plus Jakarta Sans',sans-serif;font-size:22px;font-weight:700;",
    '  color:#F2F1EC;margin:0 0 4px;letter-spacing:-.02em;}',
    '#ed-caixa .sub{font-size:13.5px;color:#8C8C7F;margin:0 0 22px;}',
    '#ed-fundo h3{font-size:11.5px;letter-spacing:.1em;text-transform:uppercase;',
    '  color:#8C8C7F;font-weight:700;margin:26px 0 10px;}',
    '#ed-fundo h3:first-child{margin-top:0;}',
    '.ed-item{display:grid;grid-template-columns:34px 56px 1fr 34px;gap:10px;',
    '  align-items:start;padding:14px;border:1px solid rgba(255,255,255,.09);',
    '  border-radius:13px;margin-bottom:10px;background:rgba(255,255,255,.023);}',
    '.ed-item.sem-icone{grid-template-columns:34px 1fr 34px;}',
    '.ed-ordem{display:flex;flex-direction:column;gap:4px;}',
    '.ed-ordem button{width:34px;height:26px;}',
    '.ed-campos{display:grid;grid-template-columns:1fr 1fr;gap:8px;}',
    '.ed-campos .largo{grid-column:1 / -1;}',
    '#ed-fundo input{width:100%;box-sizing:border-box;background:#0E0E0C;',
    '  border:1px solid rgba(255,255,255,.14);border-radius:8px;color:#F2F1EC;',
    '  padding:9px 11px;font:inherit;font-size:14px;}',
    '#ed-fundo input:focus{outline:2px solid #4FA890;outline-offset:1px;border-color:transparent;}',
    '#ed-fundo input.icone{text-align:center;font-size:19px;padding:9px 4px;}',
    '#ed-fundo button{background:rgba(255,255,255,.07);color:#D9D8D0;font:inherit;',
    '  font-size:13px;border:1px solid rgba(255,255,255,.12);border-radius:8px;',
    '  cursor:pointer;padding:7px 12px;}',
    '#ed-fundo button:hover{background:rgba(255,255,255,.13);color:#F2F1EC;}',
    '#ed-fundo button:disabled{opacity:.4;cursor:default;}',
    /* Estes seletores repetem o #ed-fundo de propósito. Sem o id eles perdem
       para a regra genérica "#ed-fundo button" acima, e a cor escolhida fica
       sem marcação nenhuma — foi exatamente o que aconteceu na primeira versão. */
    '#ed-fundo .ed-excluir{color:#EE9265;}',
    '#ed-fundo .ed-add{margin-top:2px;}',
    '#ed-fundo .ed-cores{grid-column:1 / -1;display:flex;gap:7px;flex-wrap:wrap;margin-top:2px;}',
    '#ed-fundo .ed-cor{width:26px;height:26px;border-radius:50%;',
    '  border:2px solid rgba(255,255,255,.16);cursor:pointer;padding:0;}',
    '#ed-fundo .ed-cor[aria-pressed="true"]{border-color:#F2F1EC;',
    '  box-shadow:0 0 0 2px rgba(0,0,0,.55) inset;}',
    '#ed-rodape{display:flex;align-items:center;gap:12px;margin-top:22px;',
    '  padding-top:18px;border-top:1px solid rgba(255,255,255,.09);}',
    '#ed-erro{flex:1;font-size:13.5px;color:#EE9265;}',
    '#ed-fundo #ed-salvar{background:#217361;border-color:#217361;',
    '  color:#fff;font-weight:600;padding:9px 20px;}',
    '#ed-fundo #ed-salvar:hover{background:#2A8B75;}',
    '#ed-dica{font-size:12.5px;color:#75746A;margin-top:16px;line-height:1.5;}'
  ].join('\n');
  document.head.appendChild(estilo);

  var fundo = document.createElement('div');
  fundo.id = 'ed-fundo';
  fundo.innerHTML =
    '<div id="ed-caixa">' +
      '<h2>Mapa dos botões</h2>' +
      '<p class="sub">Os botões grandes da grade e os dois grupos de atalhos. Use as setas para reordenar e toque na cor para trocar.</p>' +
      '<div id="ed-lista"></div>' +
      '<p id="ed-dica">O endereço começa com <code>https://</code>, ou é um marcador de ação no MacBook: <code>#claude-app</code> abre o app do Claude, <code>#claude-code</code> abre o Claude Code no Terminal.</p>' +
      '<div id="ed-rodape">' +
        '<span id="ed-erro"></span>' +
        '<button id="ed-fechar">Cancelar</button>' +
        '<button id="ed-salvar">Salvar</button>' +
      '</div>' +
    '</div>';
  document.body.appendChild(fundo);

  var lista = fundo.querySelector('#ed-lista');
  var campoErro = fundo.querySelector('#ed-erro');
  var rascunho = null;

  function campo(valor, marcador, classe, aoMudar) {
    var i = document.createElement('input');
    i.type = 'text';
    i.value = valor || '';
    i.placeholder = marcador;
    if (classe) i.className = classe;
    i.addEventListener('input', function () { aoMudar(i.value); });
    return i;
  }

  function montarItem(secao, itens, item, indice) {
    var linha = document.createElement('div');
    linha.className = 'ed-item' + (secao.icone ? '' : ' sem-icone');
    linha.dataset.secao = secao.chave;

    var ordem = document.createElement('div');
    ordem.className = 'ed-ordem';
    [['↑', -1], ['↓', 1]].forEach(function (par) {
      var b = document.createElement('button');
      b.type = 'button';
      b.textContent = par[0];
      b.disabled = (par[1] === -1 && indice === 0) ||
                   (par[1] === 1 && indice === itens.length - 1);
      b.addEventListener('click', function () {
        var destino = indice + par[1];
        var tmp = itens[destino];
        itens[destino] = itens[indice];
        itens[indice] = tmp;
        desenharTudo();
      });
      ordem.appendChild(b);
    });
    linha.appendChild(ordem);

    if (secao.icone) {
      linha.appendChild(campo(item.icone, '✦', 'icone', function (v) { item.icone = v; }));
    }

    var campos = document.createElement('div');
    campos.className = 'ed-campos';

    var nome = campo(item.nome, 'Nome', 'nome', function (v) { item.nome = v; });
    if (!secao.descricao) nome.classList.add('largo');
    campos.appendChild(nome);

    if (secao.descricao) {
      campos.appendChild(campo(item.descricao, 'Descrição (opcional)', '', function (v) { item.descricao = v; }));
    }

    campos.appendChild(campo(item.acao, 'https://…', 'largo', function (v) { item.acao = v; }));

    if (secao.cor) {
      var cores = document.createElement('div');
      cores.className = 'ed-cores';
      CORES.forEach(function (cor) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'ed-cor';
        b.title = cor;
        b.style.background = 'var(--cor-' + cor + ')';
        b.setAttribute('aria-pressed', item.cor === cor ? 'true' : 'false');
        b.addEventListener('click', function () {
          item.cor = cor;
          desenharTudo();
        });
        cores.appendChild(b);
      });
      campos.appendChild(cores);
    }
    linha.appendChild(campos);

    var excluir = document.createElement('button');
    excluir.type = 'button';
    excluir.className = 'ed-excluir';
    excluir.textContent = '✕';
    excluir.title = 'Apagar';
    excluir.addEventListener('click', function () {
      itens.splice(indice, 1);
      desenharTudo();
    });
    linha.appendChild(excluir);

    return linha;
  }

  function desenharTudo() {
    lista.textContent = '';

    SECOES.forEach(function (secao) {
      var titulo = document.createElement('h3');
      titulo.textContent = secao.titulo;
      lista.appendChild(titulo);

      if (!Array.isArray(rascunho[secao.chave])) rascunho[secao.chave] = [];
      var itens = rascunho[secao.chave];

      itens.forEach(function (item, indice) {
        lista.appendChild(montarItem(secao, itens, item, indice));
      });

      var add = document.createElement('button');
      add.type = 'button';
      add.className = 'ed-add';
      add.textContent = '+ Adicionar';
      add.addEventListener('click', function () {
        itens.push(secao.novo());
        desenharTudo();
        var criados = lista.querySelectorAll('[data-secao="' + secao.chave + '"] input.nome');
        if (criados.length) criados[criados.length - 1].focus();
      });
      lista.appendChild(add);
    });
  }

  function abrir() {
    // Sem esta guarda, abrir antes de a página carregar traria listas vazias —
    // e salvar apagaria tudo de uma vez.
    if (!window.CONFIG || !Array.isArray(window.CONFIG.blocos)) {
      mostrar('Ainda carregando, tente de novo', true);
      return;
    }
    // cópia profunda: cancelar precisa descartar tudo de verdade
    rascunho = JSON.parse(JSON.stringify(window.CONFIG));
    campoErro.textContent = '';
    desenharTudo();
    fundo.classList.add('aberto');
  }

  function fechar() { fundo.classList.remove('aberto'); }

  fundo.querySelector('#ed-fechar').addEventListener('click', fechar);
  fundo.addEventListener('click', function (e) { if (e.target === fundo) fechar(); });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && fundo.classList.contains('aberto')) fechar();
  });

  fundo.querySelector('#ed-salvar').addEventListener('click', function () {
    campoErro.textContent = '';
    pedir('/blocos', { config: rascunho })
      .then(function (d) {
        window.desenhar(d.config);
        fechar();
        mostrar('Salvo');
      })
      .catch(function (e) { campoErro.textContent = e.message; });
  });

  // a engrenagem, ao lado do botão de tela cheia
  var engrenagem = document.createElement('button');
  engrenagem.type = 'button';
  engrenagem.className = 'fs-btn';
  engrenagem.textContent = '⚙';
  engrenagem.title = 'Mapa dos botões';
  engrenagem.setAttribute('aria-label', 'Abrir o mapa dos botões');
  engrenagem.addEventListener('click', abrir);

  var botaoTelaCheia = document.getElementById('fsBtn');
  botaoTelaCheia.parentNode.insertBefore(engrenagem, botaoTelaCheia);
})();
