#!/usr/bin/env python3
"""Gera site/noct_e_a_fenda_carmesim.pdf a partir de site/livro.html, com o sumário paginado.

Rode depois de tools/livro_para_site.py, sempre que o livro mudar:

    python3 tools/livro_pdf.py

Precisa de: Node com o pacote playwright (e o Chromium dele) e `pip install pypdf`.
Passo 1: imprime o livro em PDF e acha em que página começa cada parte e capítulo (marcas @@cap-N@@).
Também gera site/noct_capa.pdf a partir de site/capa.html (capa, contracapa e orelhas).
Passo 2: grava essas páginas em site/historia/paginas.js e imprime de novo, agora com o sumário numerado
(repete até as páginas não mudarem mais).
"""
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
PDF = SITE / "noct_e_a_fenda_carmesim.pdf"
PAGINAS = SITE / "historia/paginas.js"
CAPA = SITE / "noct_capa.pdf"

NODE = r"""
const { chromium } = require('playwright');
(async () => {
  const [url, out] = process.argv.slice(2);
  const opts = {};
  if (process.env.CHROMIUM_PATH) opts.executablePath = process.env.CHROMIUM_PATH;
  const browser = await chromium.launch(opts);
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  await page.emulateMedia({ media: 'print' });
  await page.pdf({ path: out, preferCSSPageSize: true, printBackground: true });
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
"""


def imprimir(pagina: str = "livro.html", saida: Path = PDF) -> None:
    with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False) as f:
        f.write(NODE)
        script = f.name
    env = dict(os.environ)
    try:
        raiz = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True).stdout.strip()
        if raiz:
            env["NODE_PATH"] = os.pathsep.join(p for p in [env.get("NODE_PATH", ""), raiz] if p)
    except FileNotFoundError:
        pass
    try:
        subprocess.run(["node", script, (SITE / pagina).as_uri(), str(saida)], check=True, env=env)
    finally:
        os.unlink(script)


# Largura de cada página do noct_capa.pdf, em mm (capa aberta, frente, lombada, contracapa, orelhas).
LARGURAS_CAPA = [494, 148, 18, 148, 90, 90]


def acertar_capa() -> None:
    """O Chromium às vezes imprime a última página com o tamanho padrão; corta cada página na largura dela."""
    from pypdf import PdfWriter
    escritor = PdfWriter(clone_from=str(CAPA))
    for pg, mm in zip(escritor.pages, LARGURAS_CAPA):
        largura = mm / 25.4 * 72
        if float(pg.mediabox.width) > largura + 1:
            for caixa in (pg.mediabox, pg.cropbox):
                caixa.upper_right = (caixa.left + largura, caixa.top)
    escritor.write(str(CAPA))


def escrever_paginas(paginas: dict) -> None:
    PAGINAS.write_text(
        "// Página em que começa cada parte e capítulo no PDF do livro (sumário do livro.html).\n"
        "// Gerado por tools/livro_pdf.py; vazio = o sumário sai sem números.\n"
        "window.NOCT_LIVRO_PAGINAS = " + json.dumps(paginas, ensure_ascii=False, sort_keys=True) + ";\n",
        encoding="utf-8",
    )


def achar_paginas() -> dict:
    paginas = {}
    for n, pg in enumerate(PdfReader(str(PDF)).pages, start=1):
        for marca in re.findall(r"@@((?:cap|parte)-\d+)@@", (pg.extract_text() or "").replace(" ", "")):
            paginas.setdefault(marca, n)
    return paginas


def main() -> None:
    # Os números no sumário podem empurrar linhas; repete até a paginação parar de mudar.
    paginas = {}
    for _ in range(4):
        escrever_paginas(paginas)
        imprimir()
        novas = achar_paginas()
        if novas == paginas:
            break
        paginas = novas
    else:
        sys.exit("aviso: a paginação não estabilizou; confira o sumário do PDF.")
    imprimir("capa.html", CAPA)
    acertar_capa()
    print("ok:", CAPA, len(PdfReader(str(CAPA)).pages), "páginas (capa aberta, capa, lombada, contracapa e orelhas)")
    print("ok:", PDF, len(PdfReader(str(PDF)).pages), "páginas,", len(paginas), "marcas")

if __name__ == "__main__":
    main()
