extends Node
## Controles: cria as ações (teclado + controle Xbox), lembra qual dispositivo está em uso
## e dá o nome certo do botão para as dicas na tela. Também faz o controle vibrar.
## Registrado como autoload "Controls".

const InputSetup := preload("res://game/core/input_setup.gd")

const KEY_LABELS := {
	"up": ["W", "Cima"], "down": ["S", "Baixo"], "jump": ["Espaço", "A"],
	"attack": ["J", "X"], "dash": ["K", "RT"], "spell": ["L", "B"], "transform": ["R", "R3"],
}

var using_pad := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.setup()


## Lembra se o último comando veio do controle, para mostrar os botões certos.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		using_pad = true
	elif event is InputEventKey:
		using_pad = false


## Nome da tecla/botão de uma ação, conforme o dispositivo em uso.
func key_label(action: String) -> String:
	return KEY_LABELS[action][1 if using_pad else 0]


## Vibra o controle (se estiver em uso).
func rumble(weak: float, strong: float, duration: float) -> void:
	if using_pad:
		for id in Input.get_connected_joypads():
			Input.start_joy_vibration(id, weak, strong, duration)
