// Noct e a Fenda Carmesim — site do livro. Sem bibliotecas: barra de leitura e o leitor de capítulos.
(function () {
  "use strict";

  var calmo = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function guardar(chave, valor) {
    try { localStorage.setItem(chave, valor); } catch (e) { /* sem armazenamento: tudo bem */ }
  }
  function lembrar(chave) {
    try { return localStorage.getItem(chave); } catch (e) { return null; }
  }

  // ---------- Barra de leitura e seção atual no menu ----------
  var barra = document.getElementById("barra-leitura");
  var links = Array.prototype.slice.call(document.querySelectorAll(".topo-nav a[href^='#']"));
  var secoes = links.map(function (l) { return document.querySelector(l.getAttribute("href")); });
  function aoRolar() {
    var max = document.documentElement.scrollHeight - window.innerHeight;
    barra.style.transform = "scaleX(" + (max > 0 ? Math.min(1, window.scrollY / max) : 0) + ")";
    var atual = -1;
    for (var s = 0; s < secoes.length; s++) {
      if (secoes[s] && secoes[s].getBoundingClientRect().top < window.innerHeight * 0.4) atual = s;
    }
    links.forEach(function (l, j) { l.classList.toggle("atual", j === atual); });
  }
  window.addEventListener("scroll", aoRolar, { passive: true });
  window.addEventListener("resize", aoRolar);
  aoRolar();

  // ---------- O livro ----------
  // Os capítulos vêm de historia/capitulos.js (window.NOCT_LIVRO). Formato em historia/LEIA-ME.md.
  var livro = window.NOCT_LIVRO || {};
  var caps = (livro.capitulos || []).filter(function (c) { return c && (c.texto || "").trim(); });
  if (livro.titulo) document.getElementById("livro-titulo").textContent = livro.titulo;
  if (livro.epigrafe) {
    var ep = document.getElementById("livro-epigrafe");
    ep.textContent = livro.epigrafe;
    ep.hidden = false;
  }

  var lista = document.getElementById("sumario-lista");
  var select = document.getElementById("sumario-select");
  var pagina = document.getElementById("pagina");
  var paginacao = document.getElementById("paginacao");
  var anterior = document.getElementById("cap-anterior");
  var proximo = document.getElementById("cap-proximo");
  var posicao = document.getElementById("cap-posicao");
  var atualCap = 0;
  var botoes = [];

  // Formatação do texto dos capítulos: js/texto.js (a mesma do livro para impressão, livro.html).
  var escapar = window.NoctTexto.escapar;
  var enfeitar = window.NoctTexto.enfeitar;
  var paraHtml = window.NoctTexto.paraHtml;

  // Trechos novos: o livro marca os parágrafos alterados na última versão (capitulo.novos). Ficam destacados
  // até o leitor clicar neles; os já vistos ficam guardados neste navegador.
  var vistos = {};
  try { vistos = JSON.parse(lembrar("noct-livro-vistos") || "{}") || {}; } catch (e) { vistos = {}; }
  function pendentes(c) {
    return window.NoctTexto.codigosNovos(c.texto, c.novos).filter(function (h) { return !vistos[h]; });
  }
  function marcarVisto(h) {
    vistos[h] = 1;
    guardar("noct-livro-vistos", JSON.stringify(vistos));
  }
  function atualizarMarcas() {
    var porParte = {};
    caps.forEach(function (c, i) {
      var tem = pendentes(c).length > 0;
      if (botoes[i]) botoes[i].classList.toggle("tem-novo", tem);
      if (c.parte && tem) porParte[c.parte] = true;
    });
    Array.prototype.forEach.call(lista.querySelectorAll(".sumario-parte summary"), function (s) {
      s.classList.toggle("tem-novo", !!porParte[s.textContent]);
    });
    var aviso = pagina.querySelector(".aviso-novos");
    if (aviso) {
      var n = pagina.querySelectorAll(".novo").length;
      aviso.hidden = n === 0;
      aviso.querySelector("span").textContent = n === 1 ? "1 trecho novo ou alterado" : n + " trechos novos ou alterados";
    }
  }
  function prepararNovos() {
    Array.prototype.forEach.call(pagina.querySelectorAll("[data-novo]"), function (el) {
      var h = el.getAttribute("data-novo");
      if (vistos[h]) return;
      el.classList.add("novo");
      el.title = "Trecho novo. Clique para marcar como lido.";
      el.addEventListener("click", function () {
        if (!el.classList.contains("novo")) return;
        el.classList.remove("novo");
        el.removeAttribute("title");
        marcarVisto(h);
        atualizarMarcas();
      });
    });
    var todos = pagina.querySelector(".aviso-novos button");
    if (todos) todos.addEventListener("click", function () {
      Array.prototype.forEach.call(pagina.querySelectorAll(".novo"), function (el) {
        el.classList.remove("novo");
        el.removeAttribute("title");
        marcarVisto(el.getAttribute("data-novo"));
      });
      atualizarMarcas();
    });
    atualizarMarcas();
  }

  function nomeCap(c, i) {
    return c.numero != null ? String(c.numero) : String(i + 1);
  }

  function abrir(i, rolar) {
    if (!caps.length) return;
    atualCap = Math.max(0, Math.min(caps.length - 1, i));
    var c = caps[atualCap];
    var rotulo = c.rotulo || ("Capítulo " + nomeCap(c, atualCap));
    pagina.innerHTML =
      (c.parte ? '<p class="cap-parte">' + escapar(c.parte) + "</p>" : "") +
      '<p class="cap-num px">' + escapar(rotulo) + "</p>" +
      "<h3>" + escapar(c.titulo || rotulo) + "</h3>" +
      (c.epigrafeParte ? '<blockquote class="epigrafe">' + enfeitar(c.epigrafeParte) + "</blockquote>" : "") +
      '<p class="aviso-novos" hidden><span></span> · <button type="button">marcar todos como lidos</button></p>' +
      '<div class="cap-texto">' + paraHtml(c.texto, c.novos) + "</div>";
    Array.prototype.forEach.call(lista.querySelectorAll("button"), function (bt, j) {
      bt.setAttribute("aria-current", j === atualCap ? "true" : "false");
    });
    // A parte do capítulo aberto fica expandida; as outras ficam como o leitor deixou.
    var gaveta = botoes[atualCap] && botoes[atualCap].closest("details");
    if (gaveta) gaveta.open = true;
    select.value = String(atualCap);
    anterior.disabled = atualCap === 0;
    proximo.disabled = atualCap === caps.length - 1;
    posicao.textContent = (atualCap + 1) + " / " + caps.length;
    guardar("noct-livro-capitulo", String(atualCap));
    prepararNovos();
    if (rolar) document.getElementById("ler").scrollIntoView({ behavior: calmo ? "auto" : "smooth" });
  }

  if (caps.length) {
    var parteAtual = null;
    var grupo = null;
    var destino = lista;   // onde entram os capítulos: a lista da parte ou o sumário
    caps.forEach(function (c, i) {
      if ((c.parte || null) !== parteAtual) {
        parteAtual = c.parte || null;
        if (parteAtual) {
          // Cada parte é expansível: clique no nome para abrir ou fechar a lista dos capítulos dela.
          var item = document.createElement("li");
          item.className = "sumario-parte";
          var det = document.createElement("details");
          var sum = document.createElement("summary");
          sum.textContent = parteAtual;
          det.appendChild(sum);
          destino = document.createElement("ol");
          det.appendChild(destino);
          item.appendChild(det);
          lista.appendChild(item);
          grupo = document.createElement("optgroup");
          grupo.label = parteAtual;
          select.appendChild(grupo);
        } else {
          grupo = null;
          destino = lista;
        }
      }
      var li = document.createElement("li");
      var bt = document.createElement("button");
      bt.type = "button";
      var num = document.createElement("span");
      num.textContent = c.rotulo || ("Capítulo " + nomeCap(c, i));
      bt.appendChild(num);
      bt.appendChild(document.createTextNode(c.titulo || ""));
      bt.addEventListener("click", function () { abrir(i, true); });
      li.appendChild(bt);
      destino.appendChild(li);
      botoes.push(bt);
      var op = document.createElement("option");
      op.value = String(i);
      op.textContent = (c.rotulo || ("Capítulo " + nomeCap(c, i))) + (c.titulo ? ": " + c.titulo : "");
      (grupo || select).appendChild(op);
    });
    select.addEventListener("change", function () { abrir(parseInt(select.value, 10), false); });
    anterior.addEventListener("click", function () { abrir(atualCap - 1, true); });
    proximo.addEventListener("click", function () { abrir(atualCap + 1, true); });
    paginacao.hidden = false;
    var salvo = parseInt(lembrar("noct-livro-capitulo"), 10);
    var link = location.hash.match(/^#cap-(\d+)$/);
    abrir(link ? parseInt(link[1], 10) - 1 : (isNaN(salvo) ? 0 : salvo), false);
  } else {
    var li = document.createElement("li");
    li.className = "sumario-vazio";
    li.textContent = "Nenhum capítulo ainda.";
    lista.appendChild(li);
    select.disabled = true;
    var op = document.createElement("option");
    op.textContent = "Nenhum capítulo ainda";
    select.appendChild(op);
  }
})();
