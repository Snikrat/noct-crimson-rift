extends Node2D
## Rede de captura do Capitão: voa em arco, abre no ar e cai. Se pegar Noct, tira uma máscara e o
## deixa preso por um instante (lento, sem pular alto); depois se desfaz. É assim que os Desgarrados
## levam ao Custódio quem ouve a fenda.

const GRAVITY := 620.0
const SNARE_TIME := 1.3
const ROPE := Color(0.55, 0.42, 0.28)
const KNOT := Color(0.32, 0.22, 0.14)

var level
var velocity := Vector2.ZERO
var life := 3.0
var caught := 0.0       # > 0: presa no Noct
var open := 0.0         # 0 = embolada na mão, 1 = aberta


func _physics_process(delta: float) -> void:
	life -= delta
	if caught > 0:
		caught -= delta
		position = level.player.global_position + Vector2(0, -2)
		if caught <= 0:
			queue_free()
		queue_redraw()
		return
	open = minf(open + delta * 3.0, 1.0)
	velocity.y += GRAVITY * delta
	position += velocity * delta
	var size := Vector2(10, 10).lerp(Vector2(30, 22), open)
	var box := Rect2(global_position - size / 2, size)
	var p = level.player
	if p.death_timer <= 0 and p.invuln_timer <= 0 and box.intersects(p.get_hurtbox()):
		p.hit_by_boss(signf(velocity.x))
		p.snare_timer = SNARE_TIME
		caught = SNARE_TIME
		if is_instance_valid(level.boss) and level.boss.has_method("on_net_hit"):
			level.boss.on_net_hit()
		return
	if life <= 0 or level.is_solid(global_position + Vector2(0, 6)):
		queue_free()
	queue_redraw()


func _draw() -> void:
	var w := lerpf(5, 15, open)
	var h := lerpf(5, 11, open) if caught <= 0 else 20.0
	if caught > 0:
		w = 13
	# Malha de corda: diagonais cruzadas e nós nas pontas (pesos).
	var step := 5.0
	var x := -w
	while x <= w:
		draw_line(Vector2(x, -h), Vector2(x + h * 0.6, h), ROPE, 1)
		draw_line(Vector2(x, -h), Vector2(x - h * 0.6, h), ROPE, 1)
		x += step
	draw_line(Vector2(-w, -h), Vector2(w, -h), ROPE, 1)
	for k in [-w, 0.0, w]:
		draw_rect(Rect2(Vector2(k - 1, h - 1), Vector2(2, 2)), KNOT)
