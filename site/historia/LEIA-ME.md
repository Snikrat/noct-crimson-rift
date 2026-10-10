# Capítulos do livro no site

A seção **História** do site (`site/index.html#historia`) lê os capítulos de `site/historia/capitulos.js`.

## Atualizar a partir do livro

O livro "Noct e a Fenda Carmesim" é escrito como documento. Exporte-o em Markdown e rode:

```
python3 tools/livro_para_site.py caminho/do/livro.md
```

O script refaz `capitulos.js` inteiro (partes, epígrafes e capítulos). Não edite o arquivo à mão se for
rodar o script depois.

Depois, refaça o livro em PDF (o botão "Baixar o livro em PDF" do site aponta para ele):

```
python3 tools/livro_pdf.py
```

Ele gera `site/noct_e_a_fenda_carmesim.pdf` a partir de `site/livro.html` (capa, folha de rosto, sumário com
páginas, partes, capítulos e colofão, em formato A5) e grava os números do sumário em `historia/paginas.js`.
Precisa de Node com o Playwright e de `pip install pypdf`. Sem isso, dá para abrir `site/livro.html` no
navegador e usar o botão "Salvar em PDF".

## Formato de cada capítulo

Cada item da lista `capitulos`:

```js
{
  numero: 1,                       // opcional; sem ele, vale a ordem da lista
  rotulo: "Prólogo",               // opcional; troca o "Capítulo N" (ex.: "Prólogo", "Epílogo")
  titulo: "A estação vazia",
  parte: "Parte I · Pedravelha",   // opcional; agrupa no sumário
  epigrafeParte: "...",            // opcional; citação que abre a parte
  texto: "Texto do capítulo...",
},
```

## Como escrever o `texto`

| No texto                       | No site                                  |
|--------------------------------|------------------------------------------|
| linha em branco                | começa outro parágrafo                   |
| `— Fala do personagem.`        | parágrafo de diálogo                     |
| `*pensamento*`                 | itálico                                  |
| `**negrito**`                  | negrito                                  |
| `## Subtítulo`                 | subtítulo dentro do capítulo             |
| `***` ou `---`                 | troca de cena (o emblema da fenda)       |
| `> citação`                    | citação centralizada                     |

O link `site/index.html#cap-3` abre direto o capítulo 3. O site também lembra o último capítulo lido.
