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

  return { escapar: escapar, enfeitar: enfeitar, paraHtml: paraHtml };
})();
