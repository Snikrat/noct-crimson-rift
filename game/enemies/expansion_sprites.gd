extends RefCounted
## Animações dos inimigos da expansão (tools/make_new_enemies.lua): uma tira PNG por animação em
## assets/enemies/expansao/<nome>_<animação>.png, quadros lado a lado. Todos olham para a direita.

const Sprites := preload("res://game/core/sprites.gd")
const DIR := "res://assets/enemies/expansao/"

static var _cache := {}


## anims: {"animação": [quadros por segundo, repete?]}; size = tamanho do quadro.
static func frames(name: String, size: Vector2, anims: Dictionary) -> SpriteFrames:
	if _cache.has(name):
		return _cache[name]
	var f := SpriteFrames.new()
	f.remove_animation("default")
	for anim in anims:
		var path: String = DIR + "%s_%s.png" % [name, anim]
		var tex: Texture2D = load(path)
		var count := int(tex.get_width() / size.x)
		Sprites.add_sheet(f, anim, path, size, 0, count - 1, anims[anim][0], anims[anim][1])
	_cache[name] = f
	return f
