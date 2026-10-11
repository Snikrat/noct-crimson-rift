// Formatação do texto do livro, usada pela seção História (site.js) e pelo livro para impressão (livro.js).
window.NoctTexto = (function () {
  "use strict";
  function escapar(t) {
    return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
  function enfeitar(t) {
    return escapar(t)
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/\*(.+?)\*/g, "<em>$1</em>");
  }
  // Código curto e estável de um parágrafo, para lembrar quais trechos novos o leitor já viu.
  function codigo(t) {
    var h = 5381;
    for (var i = 0; i < t.length; i++) h = ((h * 33) ^ t.charCodeAt(i)) >>> 0;
    return h.toString(36);
  }

  // Códigos dos blocos novos de um capítulo (os índices em capitulo.novos, contados como em paraHtml).
  function codigosNovos(texto, novos) {
    if (!novos || !novos.length) return [];
    var bs = texto.replace(/\r/g, "").split(/\n\s*\n/).map(function (b) { return b.trim(); }).filter(Boolean);
    return novos.filter(function (i) { return i < bs.length; }).map(function (i) { return codigo(bs[i]); });
  }

  // Texto simples: parágrafos separados por linha em branco; "## " é subtítulo; "***" é troca de cena;
  // parágrafo que começa com travessão (—) é diálogo; *itálico* para pensamentos; **negrito**.
  // novos (opcional): índices dos blocos alterados na última versão; ganham class "novo" e data-novo.
  function paraHtml(texto, novos) {
    var blocos = texto.replace(/\r/g, "").split(/\n\s*\n/);
    var html = [];
    var n = -1;
    blocos.forEach(function (bl) {
      var t = bl.trim();
      if (!t) return;
      n++;
      var marca = novos && novos.indexOf(n) >= 0 ? ' data-novo="' + codigo(t) + '"' : "";
      if (/^(\*\s*){3,}$|^(-\s*){3,}$/.test(t)) { html.push('<div class="cena" role="separator"></div>'); return; }
      if (/^>/.test(t)) {
        html.push('<blockquote class="epigrafe"' + marca + '>' + t.split("\n").map(function (l) { return enfeitar(l.replace(/^>\s?/, "")); }).join("<br>") + "</blockquote>");
        return;
      }
      var m = t.match(/^#{2,4}\s+(.*)$/);
      if (m) { html.push("<h4" + marca + ">" + enfeitar(m[1]) + "</h4>"); return; }
      var linhas = t.split("\n").map(function (l) { return enfeitar(l.trim()); }).join("<br>");
      html.push(/^[—–-]\s/.test(t) ? '<p class="dialogo"' + marca + ">" + linhas + "</p>" : "<p" + marca + ">" + linhas + "</p>");
    });
    return html.join("\n");
  }

  return { escapar: escapar, enfeitar: enfeitar, paraHtml: paraHtml, codigo: codigo, codigosNovos: codigosNovos };
})();
