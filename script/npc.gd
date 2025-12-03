extends CharacterBody2D

# --- SETTINGS: DIALOG (STORY) ---
@export_multiline var dialog_intro_list: Array[String] = [
	"Tenanglah, Anak Manusia. Simpan rasa takutmu.",
	"Jika aku berniat jahat, kau sudah menjadi santapan sejak napas pertamamu di sini.",
	"Kau bingung melihat hutan ini? Tempat ini masih Kerinci, namun bukan yang kau kenal.",
	"Kau telah melangkah melewati batas Pintu Rimba. Selamat datang di Alam Halimun.",
	"Jalan pulang? Pintu di pohon itu sudah tertutup bagi jiwa yang bimbang.",
	"Namun, takdirmu belum berakhir di sini. Ada satu cara untuk membuka kembali gerbang itu.",
	"Dahulu, ada sebuah Prasasti Kuno yang menjaga keseimbangan dua dunia. Kini prasasti itu telah hancur dan pecahannya tersebar.",
	"Temukan pecahan-pecahan itu. Satukan kembali mereka.",
	"Hanya energi dari prasasti yang utuh yang mampu memulangkanmu ke dunia manusia.",
	"Cape bet dah.",
	"Tersesat? ikuti noda ditanah."
]

@export_multiline var dialog_finished_list: Array[String] = [
	"Kekuatan prasasti telah kembali... Tubuhku terasa ringan.",
	"Berhati-hatilah. Kau tidak sendirian di hutan ini. Ada yang mengawasimu dari kegelapan.",
	"Pergilah, sebelum kabut ini menelanmu selamanya."
]

# --- REFERENCES ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var label = $Label
@onready var interaction_zone = $InteractionZone
# Pastikan node ini bernama 'InteractIcon' dan tipenya Label
@onready var interact_icon = $InteractIcon 

# --- VARIABLES ---
var player_in_range: bool = false
var has_transformed: bool = false 
var active_tween: Tween = null
var icon_tween: Tween = null

# Agar dialog urut (Story Mode)
var intro_index: int = 0
var finish_index: int = 0
var READ_TIME: float = 4.0

func _ready():
	# 1. Hide UI elements initially
	label.visible = false
	label.visible_ratio = 0
	if interact_icon:
		interact_icon.visible = false
		interact_icon.text = "E" # Set text to E automatically
	
	# 2. Connect signals
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	# 3. Default Animation
	anim_sprite.play("false") 

func _process(_delta):
	# Check input
	if player_in_range and Input.is_action_just_pressed("interact"):
		interact()

func interact():
	# A. Check Logic: Has player finished the quest?
	if Manager.collected_fragments >= Manager.FRAGMENTS_REQUIRED:
		
		# Transformation Logic (Hanya sekali)
		if not has_transformed:
			has_transformed = true
			anim_sprite.play("princess") # Loop must be OFF in SpriteFrames
			
		# Ambil dialog urut dari list Finish
		var text = get_sequential_dialog(dialog_finished_list, "finish")
		show_dialog(text)
		
	else:
		# Masih monster (Quest belum kelar)
		anim_sprite.play("false")
		
		# Ambil dialog urut dari list Intro
		var text = get_sequential_dialog(dialog_intro_list, "intro")
		show_dialog(text)

# --- FUNGSI PINTAR: URUTAN DIALOG ---
func get_sequential_dialog(list: Array, type: String) -> String:
	var text = ""
	
	if type == "intro":
		text = list[intro_index]
		intro_index += 1
		# Kalau sudah habis, ulang dari awal (Looping Story)
		if intro_index >= list.size():
			intro_index = 0
			
	elif type == "finish":
		text = list[finish_index]
		finish_index += 1
		if finish_index >= list.size():
			finish_index = 0
			
	return text

# --- FUNGSI VISUAL: TEXT TYPEWRITER ---
func show_dialog(text_to_show: String):
	# 1. Reset Text
	label.text = text_to_show
	label.visible = true
	label.visible_ratio = 0
	
	# 2. Reset Tween (supaya gak glitch kalau di-spam)
	if active_tween: active_tween.kill()
	active_tween = create_tween()
	
	# 3. Animasi Ngetik (Duration: 1.0s)
	active_tween.tween_property(label, "visible_ratio", 1.0, 1.0)
	
	# 4. Tunggu Player Baca (READ_TIME)
	active_tween.tween_interval(READ_TIME)
	
	# 5. Hilang Otomatis
	active_tween.tween_callback(func(): label.visible = false)

# --- FUNGSI VISUAL: ICON 'E' ---
func toggle_icon(show: bool):
	if not interact_icon: return
	
	interact_icon.visible = show
	
	if show:
		# Animasi Floating (Naik Turun) untuk Label E
		if icon_tween: icon_tween.kill()
		icon_tween = create_tween().set_loops()
		
		# Simpan posisi awal Y biar gak terbang ke langit
		var start_y = interact_icon.position.y
		
		# Gerak naik sedikit (-5 pixels) lalu balik
		icon_tween.tween_property(interact_icon, "position:y", start_y - 5, 0.5).set_trans(Tween.TRANS_SINE)
		icon_tween.tween_property(interact_icon, "position:y", start_y, 0.5).set_trans(Tween.TRANS_SINE)
	else:
		if icon_tween: icon_tween.kill()

# --- SIGNALS ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		toggle_icon(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		label.visible = false
		if active_tween: active_tween.kill() # Stop text animation immediately
		toggle_icon(false)
