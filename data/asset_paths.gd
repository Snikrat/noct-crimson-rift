extends RefCounted
## Todos os caminhos de arte e som do jogo num lugar só.
## Se um arquivo ou pasta mudar de lugar, só este arquivo precisa ser atualizado.

const HERO := "res://assets/hero/"              # herói (gerado por tools/slice_hero.gd)
const VENDOR := "res://assets/vendor/"          # pacotes de terceiros, sem alterações (licenças em CREDITOS.md)

# --- Pacotes ------------------------------------------------------------
const CEMETERY := VENDOR + "gothicvania-cemetery/gothicvania-cemetery-files/Assets/"
const SWAMP := VENDOR + "gothicvania-swamp/Gothicvania Swamp files/"
const TOWN := VENDOR + "gothicvania-town/GothicVania-town-files/"
const CHURCH := VENDOR + "gothicvania-church/gothicvania church files/Assets/"
const MAGIC := VENDOR + "magic-pack-9/Magic Pack 9 files/spritesheets/"
const BRINGER := VENDOR + "bringer-of-death/Bringer-Of-Death/Individual Sprite/"
const TITLE_BG := VENDOR + "final/Final/"
const EMBLEM := "res://assets/ui/emblem.png"           # emblema carmesim: ícone de jogo salvo (tools/make_emblem.gd)
const LOGO := "res://assets/ui/logo/"                 # logo animado da tela de título (tools/make_logo.lua, no Aseprite)
const HUD_BARS := "res://assets/ui/hud/"              # barras de vida, magia e XP: moldura + preenchimento (tools/make_hud_ui.gd)
const UI_FONT := "res://assets/ui/fonts/noct_pixel.fnt" # tipografia pixel do jogo (tools/make_hud_ui.gd)
const LEGACY := VENDOR + "gothicvania-legacy/"       # recortes do Legacy Collection (ansimuz)
const DEMON_SLIME := VENDOR + "demon-slime/"
const SWORD_ICONS := VENDOR + "sword-icons/"         # ícones dos amuletos
const BANDITS := VENDOR + "bandits/Sprites/"
const EVIL_WIZARD := VENDOR + "evil-wizard-2/Sprites/"
const HERO_KNIGHT := VENDOR + "hero-knight/Sprites/"
const FOREST := VENDOR + "gardens-forest/"
const UNDEAD := VENDOR + "undead-props/PNG/Objects_separately/"
const AREAS := "res://assets/areas/"            # arte própria das áreas novas (fontes .aseprite em art_source/cenarios_novos/)
const MINES := AREAS + "minas_da_fenda/"
const ARCHIVE := AREAS + "arquivo_submerso/"

# --- Cenários -----------------------------------------------------------
const SWAMP_ENV := SWAMP + "Evironment/"
const TOWN_ENV := TOWN + "PNG/environment/"
const CHURCH_ENV := CHURCH + "ENVIRONMENT/"
const CEMETERY_ENV := CEMETERY + "Environment/"
const LAVA_ENV := LEGACY + "lava/"

# --- Personagens --------------------------------------------------------
const ENEMIES := CEMETERY + "Characters/Enemies/"
const SWAMP_SPRITES := SWAMP + "Sprites/"
const TOWN_SPRITES := TOWN + "PNG/sprites/"
const CHURCH_SPRITES := CHURCH + "SPRITES/"

# --- Som ----------------------------------------------------------------
const SFX_DIR := CEMETERY + "Phaser Demo/assets/sounds/"
const RPG_SFX := VENDOR + "rpg-essentials-sfx/"   # RPG Essentials (efeitos de combate, magia, menu, passos)
const SFX_SWITCH := TOWN + "code/phaser-code/assets/sounds/switch.ogg"
const MUSIC_TOWN := TOWN + "Music/rpg_village02__loop.ogg"

# Trilha de metal (assets/vendor/music, licenças em CREDITOS.md). Nomes dos arquivos YannZ não podem mudar.
const MUSIC := VENDOR + "music/"
const MUSIC_LIVING_SCORN := MUSIC + "yannz/Living-Scorn-Exploration-music.ogg"       # exploração
const MUSIC_PIXEL_DAMNATION := MUSIC + "yannz/Pixel-Damnation-intro-tag-loop.ogg"   # combate (4s de entrada + loop)
const MUSIC_REVENGES_WAITING := MUSIC + "yannz/Revenge's Waiting mini combat loop.ogg"  # chefe
const MUSIC_UNHOLY_SURGE := MUSIC + "vitalezzz/unholy_surge.ogg"                    # combate
const MUSIC_SILVER_BULLET := MUSIC + "vitalezzz/silver_bullet.ogg"                  # chefe
const MUSIC_REALM_OF_TORMENT := MUSIC + "vitalezzz/realm_of_torment.mp3"            # Inferno
const MUSIC_HEAVY_BATTLE_1 := MUSIC + "mintodog/heavy_battle_1_bpm190.ogg"          # combate
const MUSIC_HEAVY_BATTLE_2 := MUSIC + "mintodog/heavy_battle_2_bpm185.ogg"          # combate
const MUSIC_AMBIENT_4 := MUSIC + "tom-feldmann/Ambient4.wav"                         # ambiente sombrio
const MUSIC_SYNTHETIC_EDEN := MUSIC + "david-j-barrios/Synthetic-Eden.mp3"          # título
const MUSIC_APOCALYPTIC_CARNAGE := MUSIC + "tom-feldmann/ApocalypticCarnage.wav"   # chefe final
const MUSIC_TITLE := MUSIC_SYNTHETIC_EDEN  # a mais pesada (deathcore)
# Faixas com uma entrada que não se repete: o loop volta para este ponto (segundos).
const MUSIC_LOOP_OFFSETS := {MUSIC_PIXEL_DAMNATION: 4.0}
