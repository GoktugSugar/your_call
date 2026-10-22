class_name BalanceReadout
extends Control
## The money chapter's running balance at the top of the screen: a quiet word over the amount, in
## amber. It inks in when a chapter opens its wallet, counts up or down to every change, and fades
## once the wallet is put away. Watching a run wires it to that run's wallet.

## Holds the word and the amount, centred along the top.
@export var column: VBoxContainer
## The word over the amount.
@export var word: Label
## The amount left.
@export var amount: Label

@export_group("Words")
## What the word over the amount says.
@export var word_text := "balance"
## Size of the word.
@export_range(8, 120) var word_size := 30
## Palette role of the word.
@export var word_role := &"heading"
## Size of the amount.
@export_range(8, 200) var amount_size := 60
## Palette role of the amount.
@export var amount_role := &"amber"
## Gap between the top of the screen and the word.
@export_range(0.0, 300.0, 1.0) var top_margin := 18.0

@export_group("Motion")
## Seconds it takes to ink in or fade away.
@export_range(0.0, 3.0, 0.01) var fade_duration := 0.6
## Seconds the amount takes to count to a new balance.
@export_range(0.0, 3.0, 0.01) var count_duration := 0.7

var _run: RunState
var _wallet: Wallet
## The amount shown, which counts toward the balance.
var _shown := 0.0:
	set(value):
		_shown = value
		amount.text = Numbers.money(roundi(value))
var _fade: Tween
var _count: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var palette := InkPalette.get_default()
	word.text = word_text
	word.add_theme_font_size_override(&"font_size", word_size)
	word.add_theme_color_override(&"font_color", palette.color(word_role))
	amount.add_theme_font_size_override(&"font_size", amount_size)
	amount.add_theme_color_override(&"font_color", palette.color(amount_role))
	column.position.y = top_margin
	modulate.a = 0.0
	visible = false


## Follows [param run]'s wallet from now on, letting go of any run it followed before.
func watch(run: RunState) -> void:
	if _run != null:
		_run.wallet_opened.disconnect(_on_wallet_opened)
		_run.wallet_closed.disconnect(_on_wallet_closed)
	_let_go_of_wallet()
	_run = run
	run.wallet_opened.connect(_on_wallet_opened)
	run.wallet_closed.connect(_on_wallet_closed)
	_set_shown(false, 0.0)
	if run.wallet != null:
		_on_wallet_opened(run.wallet)


func _on_wallet_opened(wallet: Wallet) -> void:
	_let_go_of_wallet()
	_wallet = wallet
	wallet.changed.connect(_on_balance_changed)
	_kill(_count)
	_shown = wallet.balance
	_set_shown(true, fade_duration)


func _on_wallet_closed() -> void:
	_let_go_of_wallet()
	_set_shown(false, fade_duration)


func _on_balance_changed(balance: int) -> void:
	_kill(_count)
	_count = create_tween()
	_count.tween_property(self, ^"_shown", float(balance), count_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _let_go_of_wallet() -> void:
	if _wallet != null and _wallet.changed.is_connected(_on_balance_changed):
		_wallet.changed.disconnect(_on_balance_changed)
	_wallet = null


## Inks the readout in, or fades it away, over [param seconds].
func _set_shown(shown: bool, seconds: float) -> void:
	_kill(_fade)
	if shown:
		visible = true
	if seconds <= 0.0:
		modulate.a = 1.0 if shown else 0.0
		visible = shown
		return
	_fade = create_tween()
	_fade.tween_property(self, ^"modulate:a", 1.0 if shown else 0.0, seconds)
	if not shown:
		_fade.tween_callback(hide)


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
