@tool
class_name InkPalette
extends Resource
## The game's colours, each named for what it means. Colour is for meaning and emphasis, never decoration.
## The whole game shares one, [code]res://ink/palette.tres[/code].

const DEFAULT_PATH := "res://ink/palette.tres"

static var _default: InkPalette

@export_group("Ink and paper")
## The warm near black of every line.
@export var ink := Color("#1B1A17")
## The page.
@export var paper := Color("#F5F2E9")
## Inside the dialogue box.
@export var box_paper := Color("#FBF9F1")
## Resting choice words.
@export var muted := Color("#8C887E")
## Choice words that were not picked.
@export var faded := Color("#C0BBB0")
## The crowd reveal's heading.
@export var heading := Color("#B0AB9F")
## The crowd's bars.
@export var crowd := Color("#46433B")
## Other quiet ink.
@export var secondary := Color("#9A968C")

@export_group("Meaning")
## Attention and consequence: hover, the lever, the player's pick, money, counts, stressed words.
@export var amber := Color("#E8951E")
## The imp's own tint.
@export var imp := Color("#D1851A")
## Death and the guilty.
@export var red := Color("#AA483A")
## The blue button.
@export var blue := Color("#3C6496")
## The player's partner, and love.
@export var pink := Color("#D97392")
## The best life.
@export var gold := Color("#DBB447")
## The last bear.
@export var brown := Color("#805C3D")

@export_group("Identification")
## Colours that only tell figures apart, like the five in the Last Bullet.
@export var green := Color("#4E8C55")
@export var orange := Color("#CC7A33")
@export var sky := Color("#5E9BC4")
@export var purple := Color("#8A5FA6")


## The palette the whole game draws with.
static func get_default() -> InkPalette:
	if _default == null:
		_default = load(DEFAULT_PATH) as InkPalette
	return _default


## The colour for a role name such as [code]&"amber"[/code]. Unknown roles fall back to ink.
func color(role: StringName) -> Color:
	var value: Variant = get(role)
	return value if value is Color else ink
