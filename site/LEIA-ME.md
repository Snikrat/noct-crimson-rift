# Site do NOCT Crimson Rift

Site de apresentação do jogo, em HTML, CSS e JS puros (sem build). Abra `site/index.html` no navegador
ou publique a pasta `site/` em qualquer hospedagem estática (GitHub Pages, Netlify, itch.io).

- `index.html`: página única (título, o jogo, Noct, o mundo, personagens e história).
- `css/site.css` e `js/site.js`: estilo e animações (logo animado, fundo da tela de título, Noct, barra de leitura).
- `historia/capitulos.js`: capítulos do livro mostrados na seção História. Formato em `historia/LEIA-ME.md`.
- `img/`: cópias da arte do jogo (logo, tela de título, sprites, retratos, HUD e capturas das áreas).
- `fonts/noct_pixel.woff2`: a fonte do jogo convertida por `tools/make_site_font.py`.
- `.gdignore`: faz a Godot ignorar a pasta (o site não entra no jogo exportado).
