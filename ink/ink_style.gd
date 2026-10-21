@tool
class_name InkStyle
extends Resource
## How every ink line in the game looks and lives: its unsteady wobble, its boil, its width and its tapered ends.
## The whole game shares one, [code]res://ink/ink_style.tres[/code], so tuning it retunes every line at once.

const DEFAULT_PATH := "res://ink/ink_style.tres"

static var _default: InkStyle

@export_group("Boil")
## How many times a second every line is redrawn with its next variant.
@export_range(1.0, 24.0, 0.5) var boil_fps := 5.0
## How many near identical variants a line cycles through.
@export_range(1, 8) var boil_variants := 3
## How far a line moves between variants, in pixels.
@export_range(0.0, 4.0, 0.05) var boil_amplitude := 0.6
## Distance along a line between the boil's wiggles, in pixels.
@export_range(4.0, 200.0, 1.0) var boil_wavelength := 24.0

@export_group("Wobble")
## How far a line drifts off its path, like an unsteady hand, in pixels.
@export_range(0.0, 8.0, 0.05) var wobble_amplitude := 1.8
## Distance along a line between drifts, in pixels.
@export_range(10.0, 400.0, 1.0) var wobble_wavelength := 75.0
## Lines shorter than one drift wobble less, the way a hand steadies for small marks.
## This is the least a tiny line wobbles, as a fraction of the full wobble.
@export_range(0.0, 1.0, 0.01) var small_line_wobble := 0.3

@export_group("Width")
## Width of a line at scale 1, in pixels.
@export_range(0.5, 20.0, 0.1) var width := 4.4
## How much the width swells and thins along a line, as a fraction of it.
@export_range(0.0, 0.8, 0.01) var width_jitter := 0.18
## Distance along a line between swells, in pixels.
@export_range(4.0, 200.0, 1.0) var width_wavelength := 44.0
## Length of the pressure taper at each loose end, in pixels.
@export_range(0.0, 60.0, 0.5) var taper_length := 14.0
## Width at the very tip of a loose end, as a fraction of the line's width.
@export_range(0.0, 1.0, 0.01) var taper_tip := 0.3
## How far a loose end runs past where it was aimed, in pixels.
@export_range(0.0, 12.0, 0.1) var overshoot := 2.5
## How far a closed shape runs past its own start, as a fraction of its length, as if the pen lifted late.
@export_range(0.0, 0.3, 0.005) var loop_overlap := 0.045

@export_group("Sampling")
## Distance between samples along a line, in pixels. Smaller is smoother and costs more.
@export_range(1.0, 16.0, 0.5) var sample_spacing := 4.0
## Most a bend may widen a line, as a multiple of its width. Stops sharp corners from spiking.
@export_range(1.0, 4.0, 0.05) var miter_limit := 1.6


## The style the whole game draws with.
static func get_default() -> InkStyle:
	if _default == null:
		_default = load(DEFAULT_PATH) as InkStyle
	return _default
