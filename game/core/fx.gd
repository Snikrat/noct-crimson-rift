extends RefCounted
## Efeitos visuais simples: brilho aditivo (luz falsa, funciona no renderizador Compatibility)
## e faíscas de partículas. Só visual: nunca muda dano ou colisão.

static var _glow_tex: Texture2D


## Círculo de luz suave somado à cena. `radius` em px; ajuste `modulate` para a intensidade.
static func glow(color: Color, radius: float, energy := 0.7) -> Sprite2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.45))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 64
		tex.height = 64
		_glow_tex = tex
	var s := Sprite2D.new()
	s.texture = _glow_tex
	s.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	s.modulate = Color(color, energy)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.z_index = 1
	return s


## Explosão de faíscas que some sozinha.
static func sparks(parent: Node, pos: Vector2, color: Color, amount := 10, speed := 90.0, gravity := 160.0, size := 1.6) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 0.45
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0))
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.z_index = 3
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
