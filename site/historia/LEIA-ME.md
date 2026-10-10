# Capítulos do livro no site

A seção **História** do site (`site/index.html#historia`) lê os capítulos de `site/historia/capitulos.js`.
Para publicar um capítulo, acrescente um item na lista `capitulos`:

```js
{
  numero: 1,                       // opcional; sem ele, vale a ordem da lista
  rotulo: "Prólogo",               // opcional; troca o "Capítulo N" (ex.: "Prólogo", "Epílogo")
  titulo: "A estação vazia",
  texto: `Texto do capítulo...`,   // crase (`) permite várias linhas
},
```

## Como escrever o `texto`

| No texto                       | No site                                  |
|--------------------------------|------------------------------------------|
| linha em branco                | começa outro parágrafo                   |
| `— Fala do personagem.`        | parágrafo de diálogo                     |
| `*pensamento*` ou `_ênfase_`   | itálico                                  |
| `**negrito**`                  | negrito                                  |
| `## Subtítulo`                 | subtítulo dentro do capítulo             |
| `***`                          | troca de cena (o emblema da fenda)       |

Não use crase (`` ` ``) dentro do texto; se precisar, escreva `\``.

O link `site/index.html#cap-3` abre direto o capítulo 3. O site também lembra o último capítulo lido.
