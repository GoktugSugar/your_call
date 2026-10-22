extends GutTest
## Souls made from their kinds. A kind hands its figure the details it names, such as a pistol, and the
## steps it folds down through when they differ from the scene's; kinds that name neither keep the
## scene's own. An armed figure's muzzle follows its pistol, and the last bear topples over and dissolves.

const FIGURE_SCENE := "res://figures/stick_figure.tscn"
## The longest a fold here may take before it counts as stuck, in seconds.
const MAX_WAIT := 5.0
## A quick fold, in seconds per stage, so the bear's fold takes a fraction of a second.
const QUICK := 0.02
## How far apart two positions may be and still count as the same, in pixels: nothing beyond rounding.
const ROUNDING := 0.001


func test_an_armed_kind_holds_a_pistol_and_a_stranger_does_not() -> void:
	var armed := _figure_of(&"armed")
	var stranger := _figure_of(&"stranger")
	assert_true(armed.pistol, "the armed soul holds a pistol")
	assert_false(stranger.pistol, "a stranger holds none")


func test_a_kind_with_fold_steps_hands_them_to_its_figure() -> void:
	var kind := SoulKind.find(&"dying")
	assert_false(kind.fold_steps.is_empty(), "the dying soul has fold steps of its own")
	var figure := _figure_of(&"dying")
	assert_eq(figure.fold_steps.size(), kind.fold_steps.size(), "as many steps as the kind names")
	for i in kind.fold_steps.size():
		assert_eq(figure.fold_steps[i], kind.fold_steps[i], "step %d" % i)


func test_a_kind_without_fold_steps_keeps_the_scenes() -> void:
	var scene_steps := (autofree((load(FIGURE_SCENE) as PackedScene).instantiate()) as StickFigure).fold_steps
	for id: StringName in [&"stranger", &"armed", &"calm"]:
		var figure := _figure_of(id)
		assert_eq(figure.fold_steps.size(), scene_steps.size(), "%s: as many steps as the scene's" % id)
		for i in scene_steps.size():
			assert_eq(figure.fold_steps[i], scene_steps[i], "%s: step %d" % [id, i])


func test_a_kind_that_does_not_fall_has_no_fold_steps() -> void:
	assert_true(_figure_of(&"sleeper").fold_steps.is_empty(), "a sleeper only dissolves")


func test_the_muzzle_is_on_the_pistol_aimed_or_lowered() -> void:
	var figure := _figure_of(&"armed")
	_assert_muzzle_on_pistol(figure, "aimed")
	var aimed := figure.muzzle_point()
	figure.pose = load("res://figures/poses/aim_lowered.tres") as FigurePose
	_assert_muzzle_on_pistol(figure, "lowered")
	assert_gt(figure.muzzle_point().y, aimed.y, "lowering the pistol lowers the muzzle")


func test_the_bear_topples_toward_the_shot_and_dissolves() -> void:
	for way: float in [1.0, -1.0]:
		var bear := SoulKind.find(&"bear").make() as Bear
		assert_not_null(bear, "the bear kind makes the bear")
		if bear == null:
			return
		bear.fall_time = QUICK
		bear.settle_time = QUICK
		bear.down_hold = 0.0
		bear.fold_fade = QUICK
		add_child_autofree(bear)
		var sitting := bear.head_top()
		bear.fold(way)
		assert_true(await wait_for_signal(bear.folded, MAX_WAIT), "way %d: the fold ends" % way)
		assert_eq(bear.dissolve, 1.0, "way %d: she has dissolved" % way)
		var lying := bear.head_top()
		assert_gt((lying.x - sitting.x) * way, 0.0, "way %d: her head went the way she was shot" % way)
		assert_gt(lying.y, sitting.y, "way %d: her head went down" % way)


func test_the_bears_floating_words_clear_her_head_and_ears() -> void:
	var bear := autofree(SoulKind.find(&"bear").make()) as Bear
	var top := bear.head_top()
	for line in bear._build_lines(InkStyle.get_default(), InkPalette.get_default()):
		for point in line.path:
			assert_lt(top.y, point.y - ROUNDING, "above every line of her")


## A stick figure of the kind called [param id], freed after the test.
func _figure_of(id: StringName) -> StickFigure:
	return autofree(SoulKind.find(id).make()) as StickFigure


## Checks the muzzle lies on the drawn pistol: the dark muzzle dot is drawn right where it is.
func _assert_muzzle_on_pistol(figure: StickFigure, label: String) -> void:
	var muzzle := figure.muzzle_point()
	var nearest := INF
	for line in figure._build_lines(InkStyle.get_default(), InkPalette.get_default()):
		if line.dot_radius > 0.0:
			nearest = minf(nearest, line.path[0].distance_to(muzzle))
	assert_almost_eq(nearest, 0.0, ROUNDING, "%s: a dot is drawn at the muzzle" % label)
