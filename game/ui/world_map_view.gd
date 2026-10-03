extends RefCounted
## Desenha o mapa do mundo na pausa: salas visitadas, onde o herói está, bancos e chefes vivos.

const Rooms := preload("res://data/rooms.gd")
const WorldMap := preload("res://data/world_map.gd")
const GOLD := Color("e8c872")
const ROOM_FILL := Color(0.32, 0.06, 0.12)
const ROOM_EDGE := Color(0.95, 0.35, 0.45)
const BOSS_ROOMS := {"lair": "gato", "sanctum": "bringer", "demon_lair": "demon_slime"}


## Caixa de cada sala, centrada em `center`.
static func layout(center: Vector2) -> Dictionary:
	var rects := {}
	var total := 0.0
	for r in WorldMap.MAIN_ROW:
		total += _size(r).x + WorldMap.GAP
	var x := center.x - (total - WorldMap.GAP) / 2.0
	for r in WorldMap.MAIN_ROW:
		var s := _size(r)
		rects[r] = Rect2(Vector2(x, center.y - s.y / 2.0), s)
		x += s.x + WorldMap.GAP
	for r in WorldMap.SIDE:
		var anchor: Rect2 = rects[WorldMap.SIDE[r][0]]
		var s := _size(r)
		rects[r] = Rect2(anchor.get_center() + WorldMap.SIDE[r][1] - s / 2.0, s)
	return rects


static func _size(r: String) -> Vector2:
	var rows: Array = Rooms.ROOMS[r]["map"]
	return Vector2(rows[0].length(), rows.size()) * WorldMap.SCALE


static func draw(ci: CanvasItem, font: Font, screen: Vector2, level, t: float) -> void:
	var box := Rect2(16, 18, screen.x - 32, screen.y - 36)
	ci.draw_rect(box, Color(0.02, 0.02, 0.06, 0.92))
	ci.draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	ci.draw_string(font, box.position + Vector2(0, 20), "Mapa", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
	var rects := layout(box.get_center() + Vector2(0, -4))
	var visited: Dictionary = GameState.visited

	# Ligações entre salas visitadas (bordas e passagens).
	for r in rects:
		if not visited.has(r):
			continue
		var room: Dictionary = Rooms.ROOMS[r]
		var links := []
		for side in ["left", "right"]:
			if room.get(side, "") != "":
				links.append(room[side])
		for m in room.get("markers", []):
			if m.has("target"):
				links.append(m["target"])
		for other in links:
			if rects.has(other) and visited.has(other):
				ci.draw_line(rects[r].get_center(), rects[other].get_center(), Color(1, 0.4, 0.5, 0.35), 1.0)

	for r in rects:
		if not visited.has(r):
			continue
		var rect: Rect2 = rects[r]
		var here: bool = r == level.room_name
		ci.draw_rect(rect, ROOM_FILL.lightened(0.25) if here else ROOM_FILL)
		ci.draw_rect(rect, ROOM_EDGE if here else Color(ROOM_EDGE, 0.55), false, 1)
		var rows: Array = Rooms.ROOMS[r]["map"]
		for row in rows:
			if "B" in row:
				ci.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(3, 3)), GOLD)   # banco
				break
		if BOSS_ROOMS.has(r) and not GameState.defeated_bosses.has(BOSS_ROOMS[r]):
			var c := rect.get_center()
			ci.draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), Color(1, 0.3, 0.3), 1.5)
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), Color(1, 0.3, 0.3), 1.5)
		if here:
			var p: Vector2 = level.player.global_position / (Vector2(level.map_size) * level.TILE)
			var dot := rect.position + rect.size * p.clamp(Vector2.ZERO, Vector2.ONE)
			ci.draw_circle(dot, 2.5 + sin(t * 6.0) * 0.6, Color(1, 0.9, 0.95))

	var here_title: String = Rooms.ROOMS[level.room_name]["title"]
	ci.draw_string(font, Vector2(box.position.x, box.end.y - 30), here_title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 11, Color(1, 0.75, 0.82))
	ci.draw_string(font, Vector2(box.position.x + 12, box.end.y - 12), "■ banco   x chefe   • você", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
	ci.draw_string(font, Vector2(box.position.x, box.end.y - 12), "M / K / Esc volta   ", HORIZONTAL_ALIGNMENT_RIGHT, box.size.x, 8, Color(1, 1, 1, 0.45))
