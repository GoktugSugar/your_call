extends GutTest
## The stick figure's walk and its crown. A walk carries the figure to where it was going and stands it
## back in its pose, turned the way it went; on the way each foot stays planted while the other steps.
## The best life is a gold figure in a crown that rests on the head clear of the eyes, and floating words
## clear the crown.

const FIGURE_SCENE := "res://figures/stick_figure.tscn"
## Where a walking figure sets off, and how far it walks.
const START_X := 400.0
const WALK := 300.0
## A quick walk, in pixels a second, so the walks in these tests take a fraction of a second.
const QUICK_SPEED := 3000.0
## A quick step, in seconds, for a walk at the figure's own pace.
const QUICK_STEP := 0.02
## The longest a walk here may take before it counts as stuck, in seconds.
const MAX_WAIT := 5.0
## Samples taken across each step when following the feet.
const SAMPLES_PER_STEP := 24
## How far apart two lengths may be and still count as the same, in pixels: nothing beyond rounding.
const ROUNDING := 0.001
## The least gap there must be between the crown's line and an eye, in pixels.
const EYE_CLEARANCE := 1.0


func test_a_walk_ends_at_its_target() -> void:
	var figure := _walker()
	figure.walk_to(START_X + WALK, QUICK_SPEED)
	assert_true(await wait_for_signal(figure.arrived, MAX_WAIT), "the walk ends")
	assert_eq(figure.position.x, START_X + WALK)


func test_a_walk_at_the_figures_own_pace_ends_at_its_target() -> void:
	var figure := _walker()
	figure.step_time = QUICK_STEP
	figure.walk_to(START_X - WALK)
	assert_true(await wait_for_signal(figure.arrived, MAX_WAIT), "the walk ends")
	assert_eq(figure.position.x, START_X - WALK)


func test_a_walk_ends_standing_in_the_figures_pose() -> void:
	var figure := _walker()
	figure.walk_to(START_X + WALK, QUICK_SPEED)
	await wait_for_signal(figure.arrived, MAX_WAIT)
	var shown: FigurePose = figure._shown
	var pose := figure.pose
	assert_eq(shown.hip_offset, pose.hip_offset, "hips")
	assert_eq(shown.spine_angle, pose.spine_angle, "spine")
	assert_eq(shown.head_tilt, pose.head_tilt, "head")
	assert_eq(shown.left_shoulder, pose.left_shoulder, "left shoulder")
	assert_eq(shown.right_shoulder, pose.right_shoulder, "right shoulder")
	assert_eq(shown.left_elbow, pose.left_elbow, "left elbow")
	assert_eq(shown.right_elbow, pose.right_elbow, "right elbow")
	assert_eq(shown.left_foot, pose.left_foot, "left foot")
	assert_eq(shown.right_foot, pose.right_foot, "right foot")


func test_a_walk_turns_the_figure_the_way_it_goes() -> void:
	var figure := _walker()
	assert_eq(figure.facing, StickFigure.Facing.FRONT, "facing the player before it walks")
	figure.walk_to(START_X + WALK, QUICK_SPEED)
	await wait_for_signal(figure.arrived, MAX_WAIT)
	assert_eq(figure.facing, StickFigure.Facing.RIGHT, "turned right after walking right")
	figure.walk_to(START_X, QUICK_SPEED)
	await wait_for_signal(figure.arrived, MAX_WAIT)
	assert_eq(figure.facing, StickFigure.Facing.LEFT, "turned left after walking back")


func test_each_step_lifts_one_foot_while_the_other_stays_planted() -> void:
	for way: float in [1.0, -1.0]:
		var figure := _figure()
		var walk := FigureWalk.new(figure, figure.pose, figure.pose, WALK, way)
		var last_stepping := -1
		for k in walk.steps:
			var feet := _follow_feet(figure, walk, k)
			var planted: Array[bool] = [_stays_put(feet[0]), _stays_put(feet[1])]
			assert_ne(planted[0], planted[1], "way %d, step %d: one foot stays planted while the other moves" % [way, k])
			var stepping := 1 if planted[0] else 0
			assert_lt(_highest(feet[stepping]), 0.0, "way %d, step %d: the stepping foot lifts" % [way, k])
			assert_ne(stepping, last_stepping, "way %d, step %d: the feet take turns" % [way, k])
			last_stepping = stepping


func test_the_body_never_drifts_back() -> void:
	var figure := _figure()
	var walk := FigureWalk.new(figure, figure.pose, figure.pose, WALK, 1.0)
	var samples := walk.steps * SAMPLES_PER_STEP
	var previous := walk.travel_at(0.0)
	for i in range(1, samples + 1):
		var travel := walk.travel_at(float(walk.steps) * i / samples)
		assert_gte(travel, previous - ROUNDING, "sample %d" % i)
		previous = travel
	assert_eq(previous, WALK, "it ends where it was going")


func test_the_best_life_is_a_gold_figure_in_a_crown() -> void:
	var soul := SoulKind.find(&"best_life").make()
	var figure := soul as StickFigure
	assert_not_null(figure, "the best life is a stick figure")
	if figure != null:
		assert_eq(figure.color_override, &"gold")
		assert_true(figure.crown, "it wears a crown")
	soul.free()


func test_the_crown_rests_on_the_head_clear_of_the_eyes() -> void:
	for facing: StickFigure.Facing in [StickFigure.Facing.FRONT, StickFigure.Facing.LEFT, StickFigure.Facing.RIGHT]:
		var figure := _figure()
		figure.crown = true
		figure.facing = facing
		var lines := figure._build_lines(InkStyle.get_default(), InkPalette.get_default())
		var head := _centre(lines[0].path)
		var crown := lines[lines.size() - 1]
		var half_line := InkStyle.get_default().width * figure.crown_line * 0.5
		var nearest_head := INF
		var nearest_eye := INF
		for point in crown.path:
			nearest_head = minf(nearest_head, point.distance_to(head))
			for line in lines:
				if line.dot_radius > 0.0:
					nearest_eye = minf(nearest_eye, point.distance_to(line.path[0]) - line.dot_radius - half_line)
		assert_almost_eq(nearest_head, figure.head_radius, ROUNDING, "facing %d: it rests on the head" % facing)
		assert_gt(nearest_eye, EYE_CLEARANCE, "facing %d: it clears the eyes" % facing)


func test_floating_words_clear_the_crown() -> void:
	var figure := _figure()
	var bare_top := figure.head_top()
	figure.crown = true
	var top := figure.head_top()
	assert_almost_eq(top.y, bare_top.y - figure.crown_size.y, ROUNDING, "raised by the crown's height")
	var lines := figure._build_lines(InkStyle.get_default(), InkPalette.get_default())
	for point in lines[lines.size() - 1].path:
		assert_lt(top.y, point.y, "above the crown")


## A figure standing in the tree, ready to walk.
func _walker() -> StickFigure:
	var figure := _figure_scene().instantiate() as StickFigure
	figure.position = Vector2(START_X, 0.0)
	add_child_autofree(figure)
	return figure


## A figure out of the tree, for looking at its drawing and planning walks.
func _figure() -> StickFigure:
	return autofree(_figure_scene().instantiate()) as StickFigure


func _figure_scene() -> PackedScene:
	return load(FIGURE_SCENE) as PackedScene


## Each foot through step [param k] of [param walk]: how far along the way it is and how high it is
## lifted (negative is up), screen left foot first.
func _follow_feet(figure: StickFigure, walk: FigureWalk, k: int) -> Array[PackedVector2Array]:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var pose := FigurePose.new()
	for i in SAMPLES_PER_STEP + 1:
		var progress := k + float(i) / SAMPLES_PER_STEP
		walk.pose_at(progress, pose)
		var body := walk.travel_at(progress)
		var left_x := pose.left_foot.x - figure.foot_spread
		var right_x := pose.right_foot.x + figure.foot_spread
		left.append(Vector2(body + walk.way * left_x, pose.left_foot.y))
		right.append(Vector2(body + walk.way * right_x, pose.right_foot.y))
	return [left, right]


## Whether a foot followed through a step stayed on the ground in one spot.
func _stays_put(samples: PackedVector2Array) -> bool:
	for sample in samples:
		if absf(sample.x - samples[0].x) > ROUNDING or absf(sample.y) > ROUNDING:
			return false
	return true


## The highest a foot followed through a step got: the most negative height.
func _highest(samples: PackedVector2Array) -> float:
	var highest := 0.0
	for sample in samples:
		highest = minf(highest, sample.y)
	return highest


## The middle of a ring of evenly spaced points.
func _centre(points: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for point in points:
		sum += point
	return sum / points.size()
