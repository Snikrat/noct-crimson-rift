// Monta o livro inteiro para impressão (livro.html): capa, folha de rosto, sumário, partes, capítulos e colofão.
// Os números de página do sumário vêm de historia/paginas.js, gerado por tools/livro_pdf.py.
(function () {
  "use strict";

  var T = window.NoctTexto;
  var livro = window.NOCT_LIVRO || {};
  var paginas = window.NOCT_LIVRO_PAGINAS || {};
  var caps = (livro.capitulos || []).filter(function (c) { return c && (c.texto || "").trim(); });
  var titulo = livro.titulo || "Noct e a Fenda Carmesim";

  function rotulo(c, i) {
    return c.rotulo || ("Capítulo " + (c.numero != null ? c.numero : i + 1));
  }
  function pagina(id) {
    return paginas[id] != null ? String(paginas[id]) : "";
  }

  var h = [];

  // Capa
  h.push(
    '<section class="capa">' +
      '<div class="capa-fundo"></div>' +
      '<div class="capa-texto">' +
        '<img class="capa-logo" src="img/logo/logo_10.png" alt="NOCT Crimson Rift">' +
        "<h1>" + T.escapar(titulo) + "</h1>" +
        '<p class="capa-sub">Um romance de NOCT Crimson Rift</p>' +
      "</div>" +
    "</section>"
  );

  // Folha de rosto
  h.push(
    '<section class="rosto">' +
      '<p class="rosto-titulo">' + T.escapar(titulo) + "</p>" +
      '<p class="rosto-sub">Um romance de NOCT Crimson Rift</p>' +
      (livro.epigrafe ? '<blockquote class="rosto-epigrafe">' + T.enfeitar(livro.epigrafe) + "</blockquote>" : "") +
      (livro.subtitulo ? '<p class="rosto-nota">' + T.enfeitar(livro.subtitulo) + "</p>" : "") +
      '<img class="rosto-emblema" src="img/ui/emblem.png" alt="">' +
    "</section>"
  );

  // Sumário
  var sum = ['<section class="sumario"><h2>Sumário</h2><ol>'];
  var parteAtual = null;
  caps.forEach(function (c, i) {
    if ((c.parte || null) !== parteAtual) {
      parteAtual = c.parte || null;
      if (parteAtual) {
        sum.push('<li class="s-parte"><span>' + T.escapar(parteAtual) + "</span><b>" + pagina("parte-" + i) + "</b></li>");
      }
    }
    sum.push(
      '<li class="s-cap' + (c.parte ? " s-dentro" : "") + '"><span><i>' + T.escapar(rotulo(c, i)) + "</i>" +
      T.escapar(c.titulo || "") + "</span><b>" + pagina("cap-" + i) + "</b></li>"
    );
  });
  sum.push("</ol></section>");
  h.push(sum.join(""));

  // Partes e capítulos
  parteAtual = null;
  caps.forEach(function (c, i) {
    if ((c.parte || null) !== parteAtual) {
      parteAtual = c.parte || null;
      if (parteAtual) {
        var nomes = parteAtual.split("·");
        h.push(
          '<section class="parte">' +
            '<span class="marca">@@parte-' + i + "@@</span>" +
            '<p class="parte-num">' + T.escapar(nomes[0].trim()) + "</p>" +
            (nomes[1] ? "<h2>" + T.escapar(nomes.slice(1).join("·").trim()) + "</h2>" : "") +
            (c.epigrafeParte ? '<blockquote class="parte-epigrafe">' + T.enfeitar(c.epigrafeParte) + "</blockquote>" : "") +
            '<img class="parte-emblema" src="img/ui/emblem.png" alt="">' +
          "</section>"
        );
      }
    }
    h.push(
      '<section class="capitulo">' +
        '<span class="marca">@@cap-' + i + "@@</span>" +
        '<p class="cap-num">' + T.escapar(rotulo(c, i)) + "</p>" +
        "<h3>" + T.escapar(c.titulo || "") + "</h3>" +
        '<div class="cap-texto">' + T.paraHtml(c.texto) + "</div>" +
      "</section>"
    );
  });

  // Colofão
  h.push(
    '<section class="colofao">' +
      '<img src="img/ui/emblem.png" alt="">' +
      "<p>" + T.escapar(titulo) + "</p>" +
      "<p>Baseado no jogo NOCT Crimson Rift, feito com a Godot Engine.</p>" +
      "<p>github.com/Snikrat/noct-crimson-rift</p>" +
    "</section>"
  );

  document.getElementById("livro").innerHTML = h.join("\n");

  var botao = document.getElementById("imprimir");
  if (botao) botao.addEventListener("click", function () { window.print(); });
})();
