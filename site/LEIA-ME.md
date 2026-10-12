# Site do livro Noct e a Fenda Carmesim

Site do livro (só o livro, nada do jogo), em HTML, CSS e JS puros (sem build). Abra `site/index.html` no navegador
ou publique a pasta `site/` em qualquer hospedagem estática (GitHub Pages, Netlify, itch.io).

- `index.html`: página única (abertura com a capa, o livro, o leitor de capítulos e o autor).
- `css/site.css` e `js/site.js`: estilo, barra de leitura e o leitor de capítulos.
- `historia/capitulos.js`: capítulos do livro mostrados na seção História. Formato em `historia/LEIA-ME.md`.
- `livro.html` (+ `css/livro.css`, `js/livro.js`): o livro inteiro montado para imprimir ou salvar em PDF.
- `noct_e_a_fenda_carmesim.pdf`: o livro em PDF, gerado por `tools/livro_pdf.py`.
- `img/capa/`: arte da capa, lombada e contracapa. `img/titulo/` e `img/ui/emblem.png` são usados pelo livro impresso; as outras pastas de `img/` ficam só para o README do repositório.
- `fonts/noct_pixel.woff2`: fonte usada pelo livro impresso e pela capa.
- `.gdignore`: faz a Godot ignorar a pasta (o site não entra no jogo exportado).
