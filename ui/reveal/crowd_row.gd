class_name CrowdRow
extends VBoxContainer
## One option on the crowd reveal: its label, and its bar just below.

@export var label: Label
@export var bar: CrowdBar


## Sets the row for an option called [param text], chosen by [param share] of the crowd, in the colour of [param role].
func setup(text: String, share: float, role: StringName) -> void:
	label.text = text
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(role))
	bar.value = share
	bar.color_role = role
	bar.fill = 0.0
