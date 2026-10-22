extends GutTest
## The credits file loads, every credit names a role and a person or thing, and no credit uses a dash.

var _data: Variant


func before_all() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(Credits.CREDITS_PATH))


func test_the_credits_load() -> void:
	assert_true(_data is Dictionary, "%s should be a JSON object" % Credits.CREDITS_PATH)


func test_there_is_a_title() -> void:
	assert_ne(str(_data.get("title", "")), "")


func test_every_credit_has_a_role_and_a_name() -> void:
	var credits: Array = _data.get("credits", [])
	assert_gt(credits.size(), 0)
	for credit: Variant in credits:
		assert_true(credit is Dictionary and str(credit.get("role", "")) != "" and str(credit.get("name", "")) != "",
				"incomplete credit: %s" % [credit])


func test_no_credit_has_a_dash() -> void:
	var texts := PackedStringArray([str(_data.get("title", ""))])
	for credit: Variant in _data.get("credits", []):
		texts.append(str(credit.get("role", "")))
		texts.append(str(credit.get("name", "")))
	for text: String in texts:
		assert_false(Markup.has_dash(text), "dash in credits: %s" % text)
