// Monta o livro inteiro para impressão (livro.html): falsa folha de rosto, folha de rosto, dedicatória, partes, capítulos, agradecimentos, sumário e colofão.
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

  // Páginas iniciais: 1 falsa folha de rosto, 2 em branco, 3 folha de rosto, 4 dedicatória, 5 em branco.
  // A história começa na página 6. A capa fica fora do miolo (vai à parte, na gráfica).
  h.push('<section class="falso-rosto"><p>' + T.escapar(titulo) + "</p></section>");
  h.push('<section class="branco"></section>');
  h.push(
    '<section class="rosto">' +
      '<p class="rosto-titulo">' + T.escapar(titulo) + "</p>" +
      '<p class="rosto-autor">' + T.escapar(livro.autor || "F. G. Santos") + "</p>" +
      '<p class="rosto-sub">Um romance de NOCT Crimson Rift</p>' +
      '<img class="rosto-emblema" src="img/ui/emblem.png" alt="">' +
    "</section>"
  );
  h.push(
    '<section class="dedicatoria">' +
      "<p>" + T.enfeitar(livro.dedicatoria || "Para quem ainda espera do outro lado.") + "</p>" +
      (livro.epigrafe ? '<blockquote class="rosto-epigrafe">' + T.enfeitar(livro.epigrafe) + "</blockquote>" : "") +
    "</section>"
  );
  h.push('<section class="branco"></section>');

  // Partes e capítulos
  var parteAtual = null;
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

  // Agradecimentos (texto provisório até o autor mandar o dele)
  h.push(
    '<section class="agradecimentos"><h2>Agradecimentos</h2>' +
      (livro.agradecimentos ? T.paraHtml(livro.agradecimentos) :
        "<p>A quem perdeu alguém e, mesmo assim, continuou acordando.</p>" +
        "<p>A quem já se sentou na ponta de um banco deixando o outro lado livre, só por via das dúvidas.</p>" +
        "<p>A quem guarda um bilhete, uma fita, uma voz, e já não sabe se lembra ou se inventa.</p>" +
        "<p>A quem esperou tanto que esqueceu o que esperava, e esperou mesmo assim.</p>" +
        "<p>E a quem, mesmo de longe, nunca deixou de chamar.</p>" +
        "<p>Esta história é de vocês. Eu só a escrevi.</p>") +
    "</section>"
  );

  // Sumário (no fim, para a história começar na página 6)
  var sum = ['<section class="sumario"><h2>Sumário</h2><ol>'];
  parteAtual = null;
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

  // Colofão
  h.push(
    '<section class="colofao">' +
      '<img src="img/ui/emblem.png" alt="">' +
      "<p>" + T.escapar(titulo) + "</p>" +
    "</section>"
  );

  document.getElementById("livro").innerHTML = h.join("\n");

  var botao = document.getElementById("imprimir");
  if (botao) botao.addEventListener("click", function () { window.print(); });
})();
