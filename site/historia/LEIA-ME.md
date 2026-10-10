# Capítulos do livro no site

A seção **História** do site (`site/index.html#historia`) lê os capítulos de `site/historia/capitulos.js`.

## Atualizar a partir do livro

O livro "Noct e a Fenda Carmesim" é escrito como documento. Exporte-o em Markdown e rode:

```
python3 tools/livro_para_site.py caminho/do/livro.md
```

O script refaz `capitulos.js` inteiro (partes, epígrafes e capítulos). Não edite o arquivo à mão se for
rodar o script depois.

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
