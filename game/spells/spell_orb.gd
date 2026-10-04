extends Node2D
## Bola de energia do herói (estilo Vengeful Spirit): voa reto, atravessa inimigos e some na parede.
## Na forma carmesim 3 (fox = true), a magia é a Raposa Espectral: mesma lógica, arte e caixa maiores.
const Fx := preload("res://game/core/fx.gd")

const Sprites := preload("res://game/core/sprites.gd")
const SPEED := 320.0
const LIFETIME := 1.2
const DAMAGE := 2
const SIZE := Vector2(34, 18)
# Raposa: o quadro tem o focinho na borda direita, então a caixa fica à frente do centro.
const FOX_SIZE := Vector2(56, 30)
const FOX_OFFSET := 10.0

var level
var dir := 1
var fox := false
var life := LIFETIME
var done := false
var hit := []
var damage := DAMAGE
var sprite: AnimatedSprite2D


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.fox_spell() if fox else Sprites.spell_ball()
	sprite.flip_h = dir < 0
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	if fox:
		add_child(Fx.glow(Color(1, 0.15, 0.3), 40, 0.9))
	else:
		add_child(Fx.glow(Color(1, 0.3, 0.55), 26, 0.8))
	sprite.play("grow")


func _on_anim_finished() -> void:
	if sprite.animation == "grow":
		sprite.play("fly")
	elif sprite.animation == "burst":
		queue_free()


func _physics_process(delta: float) -> void:
	if done:
		return
	life -= delta
	position.x += dir * SPEED * delta
	var size := FOX_SIZE if fox else SIZE
	var center := global_position + Vector2(dir * FOX_OFFSET * scale.x, 0) if fox else global_position
	var box := Rect2(center - size * scale / 2, size * scale)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in hit or not box.intersects(e.get_hurtbox()):
			continue
		hit.append(e)
		e.take_hit(Vector2(dir, 0), damage)
		if level.player.demon:
			level.player.demon.on_hit(true)
	var front := 28.0 * scale.x if fox else 8.0
	if life <= 0 or level.is_solid(global_position + Vector2(dir * front, 0)):
		done = true
		sprite.play("burst")
