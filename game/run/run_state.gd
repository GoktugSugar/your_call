class_name RunState
extends RefCounted
## What one run remembers from beat to beat and chapter to chapter: the silent profile, the money
## chapter's wallet while it is open, everything the player has killed, facts later beats look back
## on, such as the walking button having come alive, every pick with the share of the room that made
## the same one, and every guess at the room. A new run starts with a fresh one. The run player
## hands it to every question, and the question player to every stage. A run started part way through,
## from the dev menu, takes what each skipped chapter would have left behind ([method assume]).

## The walking button came alive when pressed, in 2.11.
const BUTTON_WOKE := &"button_woke"
## The walking button bid against the player for the cigarettes, in 3.07.
const BUTTON_AUCTIONED := &"button_auctioned"
## The player shot the walking button as it charged, in 4.05.
const BUTTON_SHOT := &"button_shot"
## The player let the walking button come, in 4.05.
const BUTTON_SPARED := &"button_spared"

## Emitted when a chapter opens a wallet, such as the money chapter's pot.
signal wallet_opened(wallet: Wallet)
## Emitted when the chapter that opened the wallet is over.
signal wallet_closed

## The silent portrait.
var profile := Profile.new()
## The money chapter's pot while it is open, or null.
var wallet: Wallet
## Everything the player has killed so far.
var kills := KillTally.new()
## Every pick so far, in order: the question's [code]chapter[/code] and [code]id[/code], its
## [code]number[/code] and [code]title[/code], the [code]pick[/code] as the reveal labelled it, the
## [code]share[/code] of the room that picked the same, from 0 to 100, and whether it was the
## [code]least[/code] popular pick.
var picks: Array[Dictionary] = []
## Every guess at the room so far, by question id: what it was [code]about[/code], the
## [code]guess[/code], the [code]truth[/code] and the [code]gap[/code] (the guess less the truth).
var guesses: Dictionary[StringName, Dictionary] = {}

var _facts: Dictionary[StringName, bool] = {}


## Starts a fresh wallet holding [param start] and returns it.
func open_wallet(start: int) -> Wallet:
	wallet = Wallet.new(start)
	wallet_opened.emit(wallet)
	return wallet


## Puts the wallet away once its chapter is over.
func close_wallet() -> void:
	if wallet == null:
		return
	wallet = null
	wallet_closed.emit()


## Remembers [param fact], such as [code]button_woke[/code], for the rest of the run.
func remember(fact: StringName) -> void:
	_facts[fact] = true


## Whether the run remembers [param fact].
func remembers(fact: StringName) -> bool:
	return _facts.get(fact, false)


## Whether [param run] remembers every fact in [param required] and none in [param excluded].
static func holds(run: RunState, required: PackedStringArray, excluded: PackedStringArray) -> bool:
	for fact in required:
		if not run.remembers(StringName(fact)):
			return false
	for fact in excluded:
		if run.remembers(StringName(fact)):
			return false
	return true


## Remembers the pick the player made in [param question], as [param split] showed it.
func record_pick(question: QuestionData, split: RevealSplit) -> void:
	if split.pick < 0 or split.pick >= split.shares.size():
		return
	picks.append({"chapter": String(question.chapter), "id": String(question.id), "number": question.number,
			"title": question.title, "pick": split.labels[split.pick] if split.pick < split.labels.size() else "",
			"share": split.shares[split.pick], "least": split.is_least_popular()})


## Remembers the player's guess at the room in [param question]: [param guess] against [param truth],
## what it was [param about].
func record_guess(question: QuestionData, about: StringName, guess: float, truth: float) -> void:
	guesses[question.id] = {"about": String(about), "guess": guess, "truth": truth, "gap": guess - truth}


## The average gap of the guesses [param about] something, such as strangers: below 0 when they ran
## low, above when they ran high. 0 when there were none.
func guess_lean(about: StringName) -> float:
	var total := 0.0
	var count := 0
	for each: Dictionary in guesses.values():
		if StringName(str(each.get("about", ""))) == about:
			total += float(each.get("gap", 0.0))
			count += 1
	return total / count if count > 0 else 0.0


## The share of the room that made every pick the player made, from 0 to 1: each pick's share,
## multiplied.
func odds_of_every_pick() -> float:
	var odds := 1.0
	for each in picks:
		odds *= clampf(float(each.get("share", 100.0)) / 100.0, 0.0, 1.0)
	return odds


## Everything the run remembers as plain data, for the save: the profile, the wallet if one is open,
## the kill tally, the facts, the picks and the guesses.
func to_data() -> Dictionary:
	var facts: Array[String] = []
	for fact in _facts:
		facts.append(String(fact))
	var guessed := {}
	for id in guesses:
		guessed[String(id)] = guesses[id].duplicate()
	return {"profile": profile.to_data(), "wallet": wallet.to_data() if wallet != null else null,
			"kills": kills.to_data(), "facts": facts, "picks": picks.duplicate(true), "guesses": guessed}


## A run that remembers what [method to_data] wrote, or null when [param data] is not that.
static func from_data(data: Variant) -> RunState:
	if not data is Dictionary or not Profile.is_valid_data(data.get("profile")) or not data.get("facts") is Array:
		return null
	var run := RunState.new()
	run.profile.load_data(data["profile"])
	if data.get("wallet") != null:
		run.wallet = Wallet.from_data(data["wallet"])
		if run.wallet == null:
			return null
	var tally := KillTally.from_data(data.get("kills"))
	if tally == null:
		return null
	run.kills = tally
	for fact: Variant in data["facts"]:
		if not fact is String:
			return null
		run.remember(StringName(fact))
	for each: Variant in data.get("picks", []):
		if not each is Dictionary or not SaveData.has_numbers(each, ["share"]):
			return null
		run.picks.append(each)
	var guessed: Variant = data.get("guesses", {})
	if not guessed is Dictionary:
		return null
	for id: Variant in guessed:
		if not guessed[id] is Dictionary or not SaveData.has_numbers(guessed[id], ["guess", "truth", "gap"]):
			return null
		run.guesses[StringName(str(id))] = guessed[id]
	return run


## Takes what [param chapter] would have left behind had it been played, for a run that starts after
## it: its [member ChapterData.if_skipped], the facts it would be remembered for and the kills, by kind.
func assume(chapter: ChapterData) -> void:
	for fact: Variant in chapter.if_skipped.get("remember", []):
		remember(StringName(str(fact)))
	var killed: Variant = chapter.if_skipped.get("kills", {})
	if killed is Dictionary:
		for kind: Variant in killed:
			kills.add(StringName(str(kind)), int(killed[kind]))
