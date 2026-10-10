extends Node2D
## Faixa de rua atrás dos objetos de cenário: a calçada continua alguns pixels para o fundo,
## e cada objeto ganha uma sombra de contato onde a base encosta nela. Fica na frente do chão
## (room_view desce para z -2) e atrás dos objetos, que apoiam a base sobre as pedras.

const DEPTH := 10                      # altura da faixa acima da linha do chão (px)
const FILL := Rect2(32, 16, 16, 16)    # peça de calçamento do tileset Wang

var tileset: Texture2D
var spans: Array = []     # [x inicial, x final, linha do chão em px]
var shadows: Array = []   # [centro x, linha do chão, largura]


func _draw() -> void:
	for span in spans:
		var x: float = span[0]
		while x < span[1]:
			var w := minf(16.0, span[1] - x)
			draw_texture_rect_region(tileset, Rect2(x, span[2] - DEPTH, w, DEPTH), Rect2(FILL.position, Vector2(w, DEPTH)), Color(1.45, 1.4, 1.6))
			x += 16.0
		# Fundo da calçada some no escuro; a borda de cima pega um pouco de luz.
		for i in 4:
			draw_rect(Rect2(span[0], span[2] - DEPTH + i, span[1] - span[0], 1), Color(0.05, 0.04, 0.1, 0.45 - i * 0.15))
	for s in shadows:
		# Sombra de contato em degraus de pixel sobre a calçada e a primeira fileira de pedras.
		var cx: float = s[0]
		var y: float = s[1]
		var w: float = s[2]
		for i in 3:
			var half := roundf(w / 2.0 + 8 - i * 3)
			draw_rect(Rect2(cx - half, y - 3 + i, half * 2, 6 - i * 2), Color(0.02, 0.01, 0.06, 0.22))
