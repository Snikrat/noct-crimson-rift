#!/usr/bin/env python3
"""Gera site/historia/capitulos.js a partir do livro exportado em Markdown.

O livro "Noct e a Fenda Carmesim" é escrito como documento (Claude Doc). Exporte-o em Markdown e rode:

    python3 tools/livro_para_site.py caminho/do/livro.md

Estrutura esperada do Markdown:
    # Título do livro            (a primeira linha)
    > *epígrafe do livro*        (opcional)
    ## Sumário                   (ignorado: o site monta o próprio)
    ## Prólogo · Título          (capítulo com rótulo)
    # Parte I · Nome             (começa uma parte; "> " logo abaixo é a epígrafe da parte)
    ## 1 · Título                (capítulo numerado)
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "site/historia/capitulos.js"


def limpar_titulo(t: str) -> str:
    return re.sub(r"\*+", "", t).strip()


def citacao(linhas: list[str]) -> str:
    return " ".join(l.lstrip(">").strip() for l in linhas if l.startswith(">")).strip().strip("*").strip()


def main(caminho: str) -> None:
    linhas = Path(caminho).read_text(encoding="utf-8").replace("\r", "").split("\n")
    livro = {"titulo": "", "subtitulo": "A história de Noct contada como um livro.", "epigrafe": "", "capitulos": []}
    parte = None
    atual = None
    bloco = None   # "inicio", "sumario", "parte", "cap"
    pendente_parte = []

    def fechar():
        if atual is not None:
            atual["texto"] = "\n".join(atual["texto"]).strip()
            livro["capitulos"].append(atual)

    inicio = []

    def parte_solta():
        # "# Epílogo · Título" sem capítulos "##" embaixo: vira um capítulo sozinho, fora das partes.
        nonlocal parte
        if bloco != "parte" or parte is None:
            return
        if any(c.get("parte") == parte["nome"] for c in livro["capitulos"]):
            return
        texto = "\n".join(pendente_parte).strip()
        if not texto:
            return
        cap = {}
        mr = re.match(r"^([^·]+?)\s*·\s*(.*)$", parte["nome"])
        if mr:
            cap["rotulo"], cap["titulo"] = mr.group(1).strip(), mr.group(2).strip()
        else:
            cap["rotulo"], cap["titulo"] = parte["nome"], ""
        cap["texto"] = texto
        livro["capitulos"].append(cap)
        parte = None
    for linha in linhas:
        m1 = re.match(r"^# (?!#)(.*)$", linha)
        m2 = re.match(r"^## (?!#)(.*)$", linha)
        if m1:
            if not livro["titulo"]:
                livro["titulo"] = m1.group(1).strip()
                bloco = "inicio"
                continue
            fechar(); atual = None
            parte_solta()
            parte = {"nome": limpar_titulo(m1.group(1)), "epigrafe": ""}
            pendente_parte = []
            bloco = "parte"
            continue
        if m2:
            nome = m2.group(1).strip()
            if bloco == "parte" and parte is not None:
                parte["epigrafe"] = citacao(pendente_parte)
            fechar(); atual = None
            if nome.lower().startswith("sumário") or nome.lower().startswith("sumario"):
                bloco = "sumario"
                continue
            bloco = "cap"
            cap = {}
            mn = re.match(r"^(\d+)\s*[·\-–—:.]\s*(.*)$", nome)
            mr = re.match(r"^([^·]+?)\s*·\s*(.*)$", nome)
            if mn:
                cap["numero"] = int(mn.group(1))
                cap["titulo"] = limpar_titulo(mn.group(2))
            elif mr:
                cap["rotulo"] = limpar_titulo(mr.group(1))
                cap["titulo"] = limpar_titulo(mr.group(2))
            else:
                cap["rotulo"] = limpar_titulo(nome)
                cap["titulo"] = ""
            if parte is not None:
                cap["parte"] = parte["nome"]
                if not any(c.get("parte") == parte["nome"] for c in livro["capitulos"]):
                    cap["epigrafeParte"] = parte["epigrafe"]
            cap["texto"] = []
            atual = cap
            continue
        if bloco == "inicio":
            inicio.append(linha)
        elif bloco == "parte":
            pendente_parte.append(linha)
        elif bloco == "cap" and atual is not None:
            atual["texto"].append(linha)
    fechar()
    parte_solta()

    livro["epigrafe"] = citacao(inicio).strip("*").strip()
    # A apresentação é o último parágrafo comum antes do sumário (o resto do início é data, autor e créditos).
    paragrafos = [p.strip() for p in "\n".join(inicio).split("\n\n") if p.strip() and not p.strip().startswith(">")]
    if paragrafos:
        livro["subtitulo"] = paragrafos[-1]
    livro["capitulos"] = [c for c in livro["capitulos"] if c["texto"]]

    js = (
        "// Capítulos do livro da história do Noct, mostrados na seção \"História\" do site.\n"
        "// Gerado por tools/livro_para_site.py a partir do livro exportado em Markdown; veja site/historia/LEIA-ME.md.\n"
        "window.NOCT_LIVRO = " + json.dumps(livro, ensure_ascii=False, indent=2) + ";\n"
    )
    OUT.write_text(js, encoding="utf-8")
    print("ok:", OUT, len(livro["capitulos"]), "capítulos")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
