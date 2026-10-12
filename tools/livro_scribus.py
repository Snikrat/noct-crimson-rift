# -*- coding: utf-8 -*-
"""Monta o miolo do livro "Noct e a Fenda Carmesim" no Scribus, no gabarito da gráfica Futura.

Gabarito: livro de 224 páginas, 160 x 230 mm, 1x1 (tons de cinza), Pólen Soft, lombada de 9 mm.
Sangria de 3 mm. Segurança medida do corte: topo 10, pé 6 (faixa do fólio até 15), interna 20, externa 10.
A capa é feita à parte; este script gera só o miolo (as 224 páginas).

Roda DENTRO do Scribus (1.6 ou mais novo), sem interface:

    scribus -g -ns -py tools/livro_scribus.py

ou no Windows (Scribus 1.6.6):

    "C:\\Program Files\\Scribus 1.6.6\\Scribus.exe" -g -ns -py tools\\livro_scribus.py

Lê o texto de site/historia/capitulos.js (o mesmo do site e do PDF do site) e grava em livro_grafica/:
  noct_miolo.sla  documento do Scribus, para ajustes à mão
  noct_miolo.pdf  PDF para a gráfica (com sangria, sem marcas, fontes em curvas)

Fontes necessárias (instaladas no sistema): Spectral (Regular, Italic, SemiBold) e Noct Pixel.
Ficam em livro_grafica/fontes/.

Variáveis de ambiente opcionais: NOCT_CORPO (tamanho do texto em pt) e NOCT_ENTRELINHA (pt),
para ajustar o total de páginas; NOCT_SO_SLA=1 para não exportar o PDF.
"""
import json
import os
import re
import sys
import time

import scribus

AQUI = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else os.getcwd()
RAIZ = os.path.dirname(AQUI)
SAIDA = os.environ.get("NOCT_SAIDA") or os.path.join(RAIZ, "livro_grafica")
CAPITULOS_JS = os.path.join(RAIZ, "site", "historia", "capitulos.js")
EMBLEMA = os.path.join(SAIDA, "emblema_cinza.png")

# ---------- Gabarito ----------
LARG, ALT = 160.0, 230.0
SANGRIA = 3.0
PAGINAS = 224
TOPO = 18.0         # segurança 10
INTERNA = 24.0      # segurança 20
EXTERNA = 18.0      # segurança 10
CORPO = float(os.environ.get("NOCT_CORPO", "11.5"))
ENTRELINHA = float(os.environ.get("NOCT_ENTRELINHA", "16"))
PT = 25.4 / 72.0    # mm por ponto
LINHAS = int(os.environ.get("NOCT_LINHAS", "34"))  # linhas por página
ALT_TEXTO = LINHAS * ENTRELINHA * PT
PE = ALT - TOPO - ALT_TEXTO
FOLIO_Y = ALT - 13.0  # topo da caixa do número de página (linha de base ~ 10 mm do corte)
LARG_TEXTO = LARG - INTERNA - EXTERNA
ABERTURA = 30.0     # espaço acima do título do capítulo

FONTE = "Spectral Regular"
FONTE_IT = "Spectral Italic"
FONTE_SB = "Spectral SemiBold Regular"
FONTE_SB_IT = "Spectral SemiBold Italic"
FONTE_PIXEL = "Noct Pixel Regular"


def log(msg):
    with open(os.path.join(SAIDA, "montagem.log"), "a", encoding="utf-8") as f:
        f.write(time.strftime("%H:%M:%S ") + msg + "\n")


def carregar_livro():
    texto = open(CAPITULOS_JS, encoding="utf-8").read()
    ini = texto.index("{")
    fim = texto.rindex("}")
    return json.loads(texto[ini:fim + 1])


# ---------- Estilos ----------
def cores():
    scribus.defineColorCMYK("Texto", 0, 0, 0, 255)
    scribus.defineColorCMYK("Suave", 0, 0, 0, 170)   # ~67% de preto
    scribus.defineColorCMYK("Destaque", 0, 0, 0, 215)  # ~85% de preto (o carmesim do site)


def estilos():
    """Cria os estilos num documento provisório e os carrega no livro (ver o fim desta função)."""
    scribus.newDocument((LARG, ALT), (10, 10, 10, 10), scribus.PORTRAIT, 1, scribus.UNIT_MILLIMETERS,
                        scribus.PAGE_1, 0, 1)
    cores()

    def cs(nome, fonte, tam, cor="Texto", **kw):
        scribus.createCharStyle(name=nome, font=fonte, fontsize=tam, fillcolor=cor, language="pt_BR", **kw)

    cs("c_corpo", FONTE, CORPO)
    cs("c_it", FONTE_IT, CORPO)
    cs("c_sb", FONTE_SB, CORPO)
    cs("c_sb_it", FONTE_SB_IT, CORPO)
    cs("c_inicial", FONTE, CORPO * 1.9, "Destaque")
    cs("c_epi", FONTE_IT, CORPO - 1, "Suave")
    cs("c_epi_rom", FONTE, CORPO - 1, "Suave")
    cs("c_h4", FONTE_SB, CORPO)
    cs("c_cena", FONTE, CORPO, "Suave", tracking=400)
    cs("c_rotulo", FONTE_PIXEL, 12, "Destaque")
    cs("c_titulo", FONTE_IT, 19)
    cs("c_folio", FONTE, 8.5, "Suave")
    cs("c_parte_num", FONTE_PIXEL, 18, "Destaque")
    cs("c_parte", FONTE_IT, 22)
    cs("c_parte_epi", FONTE_IT, 10.5, "Suave")
    cs("c_falso", FONTE_IT, 13)
    cs("c_rosto_tit", FONTE_IT, 22)
    cs("c_rosto_autor", FONTE, 12, tracking=80)
    cs("c_rosto_sub", FONTE, 9, "Suave", tracking=180, features="allcaps")
    cs("c_dedic", FONTE_IT, 11)
    cs("c_agrad_tit", FONTE_IT, 13)
    cs("c_agrad", FONTE_IT, 10.5)
    cs("c_sum_tit", FONTE_PIXEL, 18, "Destaque")
    cs("c_sum_parte", FONTE, 8.5, "Destaque", tracking=120, features="allcaps")
    cs("c_sum_rot", FONTE, 7.5, "Suave", tracking=100, features="allcaps")
    cs("c_sum_cap", FONTE, 10)
    cs("c_colofao", FONTE, 12, "Suave")

    L = ENTRELINHA
    recuo = CORPO * 1.4 * PT

    def ps(nome, charstyle, alinh=3, linha=L, **kw):
        # recuos, margens e espaços em mm aqui; o Scribus guarda em pontos
        for k in ("firstindent", "leftmargin", "rightmargin", "gapbefore", "gapafter"):
            if k in kw:
                kw[k] = kw[k] / PT
        scribus.createParagraphStyle(name=nome, linespacingmode=0, linespacing=linha, alignment=alinh,
                                     charstyle=charstyle, **kw)

    ps("corpo", "c_corpo", firstindent=recuo)
    ps("corpo_inicio", "c_corpo", firstindent=0)
    ps("cena", "c_cena", 1, gapbefore=L * 0.5 * PT, gapafter=L * 0.5 * PT)
    ps("epigrafe", "c_epi", 1, linha=L * 0.95, leftmargin=6, rightmargin=6, gapafter=7)
    ps("h4", "c_h4", 1, gapbefore=6, gapafter=3)
    ps("rotulo", "c_rotulo", 1, linha=16)
    ps("titulo", "c_titulo", 1, linha=24, gapbefore=2, gapafter=12)
    ps("folio", "c_folio", 1, linha=10)
    ps("parte_num", "c_parte_num", 1, linha=22)
    ps("parte", "c_parte", 1, linha=27, gapbefore=4)
    ps("parte_epi", "c_parte_epi", 1, linha=16, leftmargin=4, rightmargin=4, gapbefore=10)
    ps("falso", "c_falso", 1, linha=18)
    ps("rosto_tit", "c_rosto_tit", 1, linha=27)
    ps("rosto_autor", "c_rosto_autor", 1, linha=16, gapbefore=2)
    ps("rosto_sub", "c_rosto_sub", 1, linha=12)
    ps("dedic", "c_dedic", 1, linha=16.5)
    ps("dedic_epi", "c_epi", 1, linha=15, gapbefore=30, leftmargin=10, rightmargin=10)
    ps("agrad_tit", "c_agrad_tit", 1, linha=18, gapbefore=30, gapafter=10)
    ps("agrad", "c_agrad", 1, linha=16.8, gapafter=3)
    ps("sum_tit", "c_sum_tit", 1, linha=22, gapafter=8)
    tab = [(LARG_TEXTO / PT - 1, 1, "")]
    ps("sum_parte", "c_sum_parte", 0, linha=12, gapbefore=4, gapafter=1.5, tabs=tab)
    ps("sum_rot", "c_sum_rot", 0, linha=9.5)
    ps("sum_cap", "c_sum_cap", 0, linha=12, gapafter=1.6, tabs=tab)
    ps("colofao", "c_colofao", 1, linha=16)

    # O script do Scribus não expõe viúvas, órfãs e "manter com o próximo": grava os estilos num .sla,
    # acrescenta esses atributos e carrega os estilos de volta.
    tmp = os.path.join(SAIDA, "_estilos.sla")
    scribus.saveDocAs(tmp)
    xml = open(tmp, encoding="utf-8").read()
    extras = {
        "corpo": 'KeepLinesStart="2" KeepLinesEnd="2"',
        "corpo_inicio": 'KeepLinesStart="2" KeepLinesEnd="2"',
        "epigrafe": 'KeepTogether="1"',
        "rotulo": 'KeepWithNext="1"',
        "titulo": 'KeepWithNext="1"',
        "h4": 'KeepWithNext="1"',
        "cena": 'KeepWithNext="1"',
        "sum_parte": 'KeepWithNext="1"',
    }
    for nome, attrs in extras.items():
        xml = re.sub(r'(<STYLE NAME="%s" )' % nome, r"\1" + attrs + " ", xml)
    open(tmp, "w", encoding="utf-8").write(xml)
    scribus.closeDoc()
    return tmp


# ---------- Texto do capítulo (mesmas regras de site/js/texto.js) ----------
ENFASE = re.compile(r"\*\*(.+?)\*\*|\*(.+?)\*")


def marcar(t, base_it=False):
    """Tira os asteriscos e devolve (texto, [(início, tamanho, estilo)])."""
    saida, faixas, pos = [], [], 0
    for m in ENFASE.finditer(t):
        saida.append(t[pos:m.start()])
        ini = sum(len(s) for s in saida)
        if m.group(1) is not None:
            trecho, est = m.group(1), ("c_sb_it" if base_it else "c_sb")
        else:
            trecho, est = m.group(2), ("c_epi_rom" if base_it else "c_it")
        saida.append(trecho)
        faixas.append((ini, len(trecho), est))
        pos = m.end()
    saida.append(t[pos:])
    return "".join(saida), faixas


def blocos(texto):
    """Lista de (estilo_de_parágrafo, texto, faixas)."""
    res = []
    anterior = None
    for bl in re.split(r"\n\s*\n", texto.replace("\r", "")):
        t = bl.strip()
        if not t:
            continue
        if re.match(r"^(\*\s*){3,}$|^(-\s*){3,}$", t):
            res.append(("cena", "*\u2003*\u2003*", []))
            anterior = "cena"
            continue
        if t.startswith(">"):
            linhas = [re.sub(r"^>\s?", "", l) for l in t.split("\n")]
            s, f = marcar("\u2028".join(linhas), base_it=True)
            res.append(("epigrafe", s, f))
            anterior = "epigrafe"
            continue
        m = re.match(r"^#{2,4}\s+(.*)$", t)
        if m:
            s, f = marcar(m.group(1))
            res.append(("h4", s, f))
            anterior = "h4"
            continue
        s, f = marcar("\u2028".join(l.strip() for l in t.split("\n")))
        primeiro = anterior is None or anterior in ("cena", "epigrafe", "h4")
        res.append(("corpo_inicio" if primeiro else "corpo", s, f))
        anterior = "corpo"
    return res


# ---------- Páginas ----------
def lado_direito(p):
    return p % 2 == 1  # primeira página à direita


def x_texto(p):
    return INTERNA if lado_direito(p) else EXTERNA


def nova_pagina(numerada=True):
    n = scribus.pageCount() + 1
    mestra = ("Num" if numerada else "Vazia") + (" Dir" if lado_direito(n) else " Esq")
    scribus.newPage(-1, mestra)
    return n


def garantir_direita(numerada=False):
    """Próxima página começa à direita: põe uma página em branco se preciso."""
    if lado_direito(scribus.pageCount() + 1):
        return
    nova_pagina(numerada)


def mestras():
    for nome, numerada in (("Num Esq", True), ("Num Dir", True), ("Vazia Esq", False), ("Vazia Dir", False)):
        scribus.createMasterPage(nome)
        scribus.editMasterPage(nome)
        if numerada:
            dir_ = nome.endswith("Dir")
            f = scribus.createText(INTERNA if dir_ else EXTERNA, FOLIO_Y, LARG_TEXTO, 6)
            scribus.setText("\x1e", f)
            scribus.setParagraphStyle("folio", f)
        scribus.closeMasterPage()


def caixa(p, y, alt, nome=None):
    scribus.gotoPage(p)
    return scribus.createText(x_texto(p), y, LARG_TEXTO, alt, nome) if nome else \
        scribus.createText(x_texto(p), y, LARG_TEXTO, alt)


def preencher(frame, partes):
    """partes: lista de (estilo, texto, faixas). Insere tudo e aplica os estilos."""
    pedacos, posicoes = [], []
    pos = 0
    for est, t, faixas in partes:
        posicoes.append((pos, len(t), est, faixas))
        pedacos.append(t)
        pos += len(t) + 1
    scribus.setText("\r".join(pedacos), frame)
    for ini, tam, est, faixas in posicoes:
        scribus.selectText(ini, max(tam, 1), frame)
        scribus.setParagraphStyle(est, frame)
    for ini, tam, est, faixas in posicoes:
        for a, n, ce in faixas:
            scribus.selectText(ini + a, n, frame)
            scribus.setCharacterStyle(ce, frame)
    scribus.selectText(0, 0, frame)


def fluir(frame, numerada=True):
    """Cria páginas e caixas ligadas até o texto caber; apaga as que sobrarem vazias."""
    caixas = [frame]
    scribus.layoutTextChain(frame)
    while scribus.textOverflows(caixas[-1], 1):
        if len(caixas) > 60:
            raise RuntimeError("o texto não cabe: %s" % scribus.getAllText(frame)[:60])
        for _ in range(4):  # de quatro em quatro: o layout do Scribus é lento
            p = nova_pagina(numerada)
            novo = caixa(p, TOPO, ALT_TEXTO)
            scribus.linkTextFrames(caixas[-1], novo)
            caixas.append(novo)
        scribus.layoutTextChain(frame)
    while len(caixas) > 1 and not scribus.getFrameText(caixas[-1]).strip():
        scribus.deleteObject(caixas.pop())
        scribus.deletePage(scribus.pageCount())
    log("  fluiu até a página %d" % scribus.pageCount())
    return caixas[-1]


def emblema(p, y, lado):
    scribus.gotoPage(p)
    x = x_texto(p) + (LARG_TEXTO - lado) / 2
    img = scribus.createImage(x, y, lado, lado)
    scribus.loadImage(EMBLEMA, img)
    scribus.setScaleImageToFrame(True, True, img)
    scribus.setLineColor("None", img)
    scribus.setFillColor("None", img)


def pagina_simples(partes, y, alt, numerada=False, centro_v=False):
    p = nova_pagina(numerada)
    f = caixa(p, y, alt)
    preencher(f, partes)
    if centro_v:
        scribus.setTextVerticalAlignment(scribus.ALIGNV_CENTERED, f)
    return p, f


# ---------- Livro ----------
def montar():
    livro = carregar_livro()
    caps = [c for c in livro["capitulos"] if (c.get("texto") or "").strip()]
    if os.environ.get("NOCT_LIMITE"):
        caps = caps[:int(os.environ["NOCT_LIMITE"])]
    titulo = livro.get("titulo", "Noct e a Fenda Carmesim")

    arq_estilos = estilos()
    scribus.newDocument((LARG, ALT), (INTERNA, EXTERNA, TOPO, PE), scribus.PORTRAIT, 1,
                        scribus.UNIT_MILLIMETERS, scribus.PAGE_2, 1, 1)
    scribus.setBleeds(SANGRIA, SANGRIA, SANGRIA, SANGRIA)
    scribus.setInfo("F. G. Santos", titulo, "Miolo para a gráfica: 160 x 230 mm, 224 páginas")
    scribus.setRedraw(False)
    cores()
    scribus.loadStylesFromFile(arq_estilos)
    os.remove(arq_estilos)
    mestras()
    # A página 1 já existe: falsa folha de rosto
    scribus.applyMasterPage("Vazia Dir", 1)
    scribus.gotoPage(1)
    f = caixa(1, 60, 20)
    preencher(f, [("falso", titulo, [])])

    nova_pagina(False)  # 2: verso em branco
    p, f = pagina_simples([("rosto_tit", titulo, []),
                           ("rosto_autor", livro.get("autor", "F. G. Santos"), []),
                           ("rosto_sub", "Um romance de NOCT Crimson Rift", [])], 55, 40)  # 3: folha de rosto
    emblema(p, 110, 14)
    nova_pagina(False)  # 4
    pagina_simples([("dedic", livro.get("dedicatoria") or "Para quem ainda espera do outro lado.", []),
                    ("dedic_epi",) + marcar(livro.get("epigrafe", ""), base_it=True)], 50, 90)  # 5
    nova_pagina(False)  # 6

    inicio = {}  # chave -> página
    parte_atual = None
    for i, c in enumerate(caps):
        parte = c.get("parte") or None
        if parte != parte_atual:
            parte_atual = parte
            if parte:
                garantir_direita()
                nomes = [s.strip() for s in parte.split("\u00b7")]
                partes = [("parte_num", nomes[0], [])]
                if len(nomes) > 1:
                    partes.append(("parte", " \u00b7 ".join(nomes[1:]), []))
                if c.get("epigrafeParte"):
                    partes.append(("parte_epi",) + marcar(c["epigrafeParte"], base_it=True))
                p, f = pagina_simples(partes, 55, 80)
                emblema(p, 145, 12)
                inicio["parte-%d" % i] = p
                nova_pagina(False)  # verso da parte em branco
        if i == 0:
            garantir_direita()
        p = nova_pagina()
        inicio["cap-%d" % i] = p
        rot = c.get("rotulo") or ("Capítulo %s" % (c.get("numero") if c.get("numero") is not None else i + 1))
        conteudo = [("rotulo", rot, []), ("titulo", c.get("titulo", ""), [])] + blocos(c["texto"])
        f = caixa(p, TOPO + ABERTURA, ALT_TEXTO - ABERTURA)
        preencher(f, conteudo)
        # Letra inicial maior (como no site): primeira letra do primeiro parágrafo de texto
        pos = len(rot) + 1 + len(c.get("titulo", "")) + 1
        if conteudo[2][0] == "corpo_inicio":
            scribus.selectText(pos, 1, f)
            scribus.setCharacterStyle("c_inicial", f)
            scribus.selectText(0, 0, f)
        log("cap %d na página %d" % (i, p))
        scribus.hyphenateText(f)
        fluir(f)

    # Agradecimentos
    agrad = livro.get("agradecimentos")
    linhas = [l.strip() for l in re.split(r"\n\s*\n", agrad)] if agrad else [
        "A quem perdeu alguém e, mesmo assim, continuou acordando.",
        "A quem já se sentou na ponta de um banco deixando o outro lado livre, só por via das dúvidas.",
        "A quem guarda um bilhete, uma fita, uma voz, e já não sabe se lembra ou se inventa.",
        "A quem esperou tanto que esqueceu o que esperava, e esperou mesmo assim.",
        "E a quem, mesmo de longe, nunca deixou de chamar.",
        "Esta história é de vocês. Eu só a escrevi.",
    ]
    garantir_direita()
    pagina_simples([("agrad_tit", "Agradecimentos", [])] + [("agrad",) + marcar(l) for l in linhas],
                   TOPO, ALT_TEXTO)
    sumario_pag = None
    garantir_direita()
    sumario_pag = scribus.pageCount() + 1
    return livro, caps, inicio, sumario_pag, titulo


def sumario(caps, inicio, titulo):
    partes = [("sum_tit", "Sumário", [])]
    parte_atual = None
    for i, c in enumerate(caps):
        parte = c.get("parte") or None
        if parte != parte_atual:
            parte_atual = parte
            if parte:
                partes.append(("sum_parte", parte + "\t" + str(inicio["parte-%d" % i]), []))
        rot = c.get("rotulo") or ("Capítulo %s" % (c.get("numero") if c.get("numero") is not None else i + 1))
        partes.append(("sum_cap", rot + "\u2028" + (c.get("titulo") or "") + "\t" + str(inicio["cap-%d" % i]),
                       [(0, len(rot), "c_sum_rot")]))
    p = nova_pagina(False)
    f = caixa(p, TOPO, ALT_TEXTO)
    preencher(f, partes)
    fluir(f, numerada=False)


def fechar(titulo):
    """Completa até 224 páginas; a última traz o colofão."""
    total = scribus.pageCount()
    if total >= PAGINAS:
        log("ATENÇÃO: o miolo tem %d páginas, mais que as %d do gabarito" % (total, PAGINAS))
        return total
    while scribus.pageCount() < PAGINAS - 1:
        nova_pagina(False)
    p = nova_pagina(False)
    emblema(p, ALT - PE - 40, 10)
    scribus.gotoPage(p)
    f = caixa(p, ALT - PE - 26, 12)
    preencher(f, [("colofao", titulo, [])])
    return scribus.pageCount()


def exportar():
    os.makedirs(SAIDA, exist_ok=True)
    scribus.setRedraw(True)
    scribus.saveDocAs(os.path.join(SAIDA, "noct_miolo.sla"))
    if os.environ.get("NOCT_SO_SLA"):
        return
    pdf = scribus.PDFfile()
    pdf.file = os.path.join(SAIDA, "noct_miolo.pdf")
    pdf.useDocBleeds = True
    pdf.cropMarks = False
    pdf.bleedMarks = False
    pdf.registrationMarks = False
    pdf.colorMarks = False
    pdf.docInfoMarks = False
    pdf.fontEmbedding = 1      # fontes em curvas, como a gráfica pede
    pdf.isGrayscale = True
    pdf.resolution = 300
    pdf.downsample = 0
    pdf.quality = 0
    pdf.version = 14
    pdf.save()


def principal():
    livro, caps, inicio, sum_pag, titulo = montar()
    log("sumário")
    sumario(caps, inicio, titulo)
    log("fechar")
    total = fechar(titulo)
    log("exportar")
    exportar()
    log("pronto")
    with open(os.path.join(SAIDA, "paginas.json"), "w", encoding="utf-8") as f:
        json.dump({"total": total, "inicio": inicio, "sumario": sum_pag}, f, ensure_ascii=False, indent=1)


if __name__ == "__main__" or True:
    try:
        principal()
    finally:
        scribus.setRedraw(True)
