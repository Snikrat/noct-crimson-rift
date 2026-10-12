# Livro impresso (miolo para a gráfica)

Miolo de **Noct e a Fenda Carmesim** no gabarito da gráfica Futura (livro personalizado):
**160 x 230 mm, 224 páginas, 1x1 (tons de cinza), Pólen Soft, lombada de 9 mm.**
A capa é feita à parte.

| Arquivo | O que é |
|---|---|
| `noct_miolo.pdf` | PDF para enviar à gráfica: 224 páginas de 166 x 236 mm (160 x 230 + 3 mm de sangria em cada lado), sem marcas de corte, textos em curvas, tons de cinza |
| `noct_miolo.sla` | O mesmo miolo aberto no Scribus, para ajustes à mão |
| `fontes/` | Spectral (texto) e Noct Pixel (títulos). Instale antes de abrir o `.sla` |
| `emblema_cinza.png` | Emblema em tons de cinza usado na folha de rosto, nas partes e no colofão |
| `paginas.json` | Em que página começa cada parte e capítulo (o sumário usa isso) |

## Diagramação

- Margens (do corte): topo 18, pé 20, interna 24, externa 18 mm. A segurança do gabarito é 10 / 6 / 20 / 10.
- Número da página centralizado no pé, a uns 9 mm do corte (dentro da faixa de 6 a 15 mm do gabarito).
- Texto em Spectral 11,5 pt, entrelinha 16 pt, 34 linhas por página, justificado, com hifenização em português e sem linhas viúvas ou órfãs.
- Páginas 1 a 6: falsa folha de rosto, branco, folha de rosto, branco, dedicatória, branco. O prólogo começa na página 7.
- Cada parte abre numa página da direita, com o verso em branco. Cada capítulo começa em página nova.
- No fim: agradecimentos, sumário, páginas em branco até a 223 e o colofão na 224.

## Como gerar de novo

Sempre que o texto do livro mudar (`site/historia/capitulos.js`), rode o script dentro do Scribus, com as fontes instaladas:

    scribus -g -ns -py tools/livro_scribus.py

No Windows:

    "C:\Program Files\Scribus 1.6.6\Scribus.exe" -g -ns -py tools\livro_scribus.py

O script recria `noct_miolo.sla`, `noct_miolo.pdf` e `paginas.json`. Ele sempre fecha em 224 páginas; se o texto crescer
e passar disso, ajuste o corpo com as variáveis `NOCT_CORPO`, `NOCT_ENTRELINHA` e `NOCT_LINHAS`
(o total aparece em `paginas.json`).
