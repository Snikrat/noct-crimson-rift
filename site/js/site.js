// NOCT Crimson Rift — site. Sem bibliotecas: tela de título, Noct animado, barra de leitura e o livro.
(function () {
  "use strict";

  var calmo = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function carregar(src) {
    var img = new Image();
    img.src = src;
    return img;
  }

  function guardar(chave, valor) {
    try { localStorage.setItem(chave, valor); } catch (e) { /* sem armazenamento: tudo bem */ }
  }
  function lembrar(chave) {
    try { return localStorage.getItem(chave); } catch (e) { return null; }
  }

  // ---------- Tela de título ----------
  // Igual a game/ui/title.gd: abertura 0-7 a 11 qps, trovão no quadro 6, loop 8-13 a 0,24 s por quadro.
  var LOGO_INTRO = [0, 1, 2, 3, 4, 5, 6, 7];
  var LOGO_LOOP = [8, 9, 10, 11, 12, 13];
  var logoCanvas = document.getElementById("logo");
  var logoCtx = logoCanvas.getContext("2d");
  var logos = [];
  for (var i = 0; i < 15; i++) logos.push(carregar("img/logo/logo_" + (i < 10 ? "0" : "") + i + ".png"));
  var clarao = document.getElementById("clarao");
  var trovao = false;
  var logoT = calmo ? 99 : -0.5;

  function quadroLogo(t) {
    if (t < 0) return -1;
    var f = Math.floor(t * 11);
    if (f < LOGO_INTRO.length) return LOGO_INTRO[f];
    var resto = t - LOGO_INTRO.length / 11;
    return LOGO_LOOP[Math.floor(resto / 0.24) % LOGO_LOOP.length];
  }

  // Camadas do fundo, com as velocidades da tela de título (px/s na tela de 270 px de altura).
  var titulo = document.querySelector(".titulo");
  var camadas = [
    { el: titulo.querySelector(".c0"), v: 3, w: 768 },
    { el: titulo.querySelector(".c1"), v: 8, w: 768 },
    { el: titulo.querySelector(".c2"), v: 16, w: 352 },
    { el: titulo.querySelector(".c3"), v: 26, w: 352 },
  ];

  // Vagalumes, como na tela de título.
  var vg = document.getElementById("vagalumes");
  var vctx = vg.getContext("2d");
  var bichos = [];
  for (var b = 0; b < 28; b++) {
    bichos.push({ x: Math.random(), y: 0.45 + Math.random() * 0.5, fase: Math.random() * Math.PI * 2, vel: 0.4 + Math.random() * 0.6 });
  }

  var tempo = 0;
  var antes = performance.now();
  var tituloVisivel = true;
  if ("IntersectionObserver" in window) {
    new IntersectionObserver(function (e) { tituloVisivel = e[0].isIntersecting; }).observe(titulo);
  }

  function quadro(agora) {
    var dt = Math.min((agora - antes) / 1000, 0.1);
    antes = agora;
    if (tituloVisivel) {
      tempo += dt;
      logoT += dt;
      desenharTitulo();
    }
    animarNoct(dt);
    requestAnimationFrame(quadro);
  }

  function desenharTitulo() {
    var f = quadroLogo(logoT);
    logoCtx.clearRect(0, 0, 300, 112);
    if (f >= 0 && logos[f].complete) logoCtx.drawImage(logos[f], 0, 0);
    if (!trovao && logoT >= 6 / 11) {
      trovao = true;
      if (!calmo) {
        clarao.classList.add("on");
        setTimeout(function () { clarao.classList.remove("on"); }, 800);
      }
    }

    var h = titulo.clientHeight;
    var escala = h / 270;
    for (var c = 0; c < camadas.length; c++) {
      var cam = camadas[c];
      var largura = cam.w * (h / 416);
      var x = calmo ? 0 : -((tempo * cam.v * escala) % largura);
      cam.el.style.backgroundPositionX = x.toFixed(1) + "px";
    }

    var W = titulo.clientWidth;
    if (vg.width !== W || vg.height !== h) { vg.width = W; vg.height = h; }
    vctx.clearRect(0, 0, W, h);
    for (var k = 0; k < bichos.length; k++) {
      var bi = bichos[k];
      var px = (bi.x * W + Math.sin(tempo * bi.vel + bi.fase) * 18 * escala) % W;
      var py = bi.y * h + Math.cos(tempo * bi.vel * 0.7 + bi.fase) * 10 * escala;
      var luz = 0.35 + 0.65 * Math.max(0, Math.sin(tempo * 2 * bi.vel + bi.fase));
      var r = Math.max(2, Math.round(escala));
      vctx.fillStyle = "rgba(255, 220, 140," + (0.18 * luz).toFixed(3) + ")";
      vctx.fillRect(Math.round(px) - r, Math.round(py) - r, r * 3, r * 3);
      vctx.fillStyle = "rgba(255, 236, 170," + luz.toFixed(3) + ")";
      vctx.fillRect(Math.round(px), Math.round(py), r, r);
    }
  }

  // ---------- Noct animado ----------
  // Folhas de 117x77 por quadro; velocidades de game/core/sprites.gd.
  var ANIMS = {
    humano: {
      parado: { img: carregar("img/noct/idle.png"), qps: 2, vaivem: true },
      correndo: { img: carregar("img/noct/run.png"), qps: 14 },
      retrato: "img/noct/portrait_calmo.png",
    },
    raposa: {
      parado: { img: carregar("img/noct/c3_idle.png"), qps: 8 },
      correndo: { img: carregar("img/noct/c3_run.png"), qps: 12 },
      retrato: "img/noct/portrait_c3_sorrindo.png",
    },
  };
  var sprite = document.getElementById("sprite");
  var sctx = sprite.getContext("2d");
  var forma = "humano";
  var mov = "parado";
  var animT = 0;
  var ultimoQuadro = -1;

  function animarNoct(dt) {
    var a = ANIMS[forma][mov];
    if (!a.img.complete || !a.img.naturalWidth) return;
    animT += calmo ? 0 : dt;
    var n = Math.max(1, Math.round(a.img.naturalWidth / 117));
    var passo = Math.floor(animT * a.qps);
    var f;
    if (a.vaivem && n > 1) {
      var ciclo = n * 2 - 2;
      f = passo % ciclo;
      if (f >= n) f = ciclo - f;
    } else {
      f = passo % n;
    }
    var chave = forma + mov + f;
    if (chave === ultimoQuadro) return;
    ultimoQuadro = chave;
    sctx.clearRect(0, 0, 117, 77);
    sctx.drawImage(a.img, f * 117, 0, 117, 77, 0, 0, 117, 77);
  }

  function ligar(idA, idB, aoEscolher) {
    var a = document.getElementById(idA);
    var bt = document.getElementById(idB);
    function escolher(qual) {
      a.classList.toggle("ativo", qual === a);
      bt.classList.toggle("ativo", qual === bt);
      a.setAttribute("aria-pressed", qual === a);
      bt.setAttribute("aria-pressed", qual === bt);
      aoEscolher(qual === a ? 0 : 1);
      animT = 0;
      ultimoQuadro = -1;
    }
    a.addEventListener("click", function () { escolher(a); });
    bt.addEventListener("click", function () { escolher(bt); });
  }
  var retrato = document.getElementById("retrato-noct");
  ligar("forma-humano", "forma-raposa", function (i) {
    forma = i ? "raposa" : "humano";
    retrato.src = ANIMS[forma].retrato;
    retrato.alt = i ? "Retrato de Noct na Forma Demoníaca" : "Retrato de Noct";
  });
  ligar("anim-parado", "anim-correndo", function (i) { mov = i ? "correndo" : "parado"; });

  requestAnimationFrame(quadro);

  // ---------- HUD: a barra de vida enche conforme a leitura ----------
  var barra = document.getElementById("barra-leitura");
  var links = Array.prototype.slice.call(document.querySelectorAll(".hud-nav a"));
  var secoes = links.map(function (l) { return document.querySelector(l.getAttribute("href")); });
  function aoRolar() {
    var max = document.documentElement.scrollHeight - window.innerHeight;
    var k = max > 0 ? Math.min(1, window.scrollY / max) : 0;
    barra.style.width = Math.round(186 * k / 2) * 2 + "px";
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
  if (livro.subtitulo) document.getElementById("livro-subtitulo").textContent = livro.subtitulo;
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

  function escapar(t) {
    return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
  function enfeitar(t) {
    return escapar(t)
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/\*(.+?)\*/g, "<em>$1</em>");
  }
  // Texto simples: parágrafos separados por linha em branco; "## " é subtítulo; "***" é troca de cena;
  // parágrafo que começa com travessão (—) é diálogo; *itálico* para pensamentos; **negrito**.
  function paraHtml(texto) {
    var blocos = texto.replace(/\r/g, "").split(/\n\s*\n/);
    var html = [];
    blocos.forEach(function (bl) {
      var t = bl.trim();
      if (!t) return;
      if (/^(\*\s*){3,}$|^(-\s*){3,}$/.test(t)) { html.push('<div class="cena" role="separator"></div>'); return; }
      if (/^>/.test(t)) {
        html.push('<blockquote class="epigrafe">' + t.split("\n").map(function (l) { return enfeitar(l.replace(/^>\s?/, "")); }).join("<br>") + "</blockquote>");
        return;
      }
      var m = t.match(/^#{2,4}\s+(.*)$/);
      if (m) { html.push("<h4>" + enfeitar(m[1]) + "</h4>"); return; }
      var linhas = t.split("\n").map(function (l) { return enfeitar(l.trim()); }).join("<br>");
      html.push(/^[—–-]\s/.test(t) ? '<p class="dialogo">' + linhas + "</p>" : "<p>" + linhas + "</p>");
    });
    return html.join("\n");
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
      '<div class="cap-texto">' + paraHtml(c.texto) + "</div>";
    Array.prototype.forEach.call(lista.querySelectorAll("button"), function (bt, j) {
      bt.setAttribute("aria-current", j === atualCap ? "true" : "false");
    });
    select.value = String(atualCap);
    anterior.disabled = atualCap === 0;
    proximo.disabled = atualCap === caps.length - 1;
    posicao.textContent = (atualCap + 1) + " / " + caps.length;
    guardar("noct-livro-capitulo", String(atualCap));
    if (rolar) document.getElementById("historia").scrollIntoView({ behavior: calmo ? "auto" : "smooth" });
  }

  if (caps.length) {
    var parteAtual = null;
    var grupo = null;
    caps.forEach(function (c, i) {
      if ((c.parte || null) !== parteAtual) {
        parteAtual = c.parte || null;
        if (parteAtual) {
          var cab = document.createElement("li");
          cab.className = "sumario-parte";
          cab.textContent = parteAtual;
          lista.appendChild(cab);
          grupo = document.createElement("optgroup");
          grupo.label = parteAtual;
          select.appendChild(grupo);
        } else {
          grupo = null;
          if (i > 0) {
            var vao = document.createElement("li");
            vao.className = "sumario-parte";
            vao.setAttribute("aria-hidden", "true");
            lista.appendChild(vao);
          }
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
      lista.appendChild(li);
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
