class_name RunState
extends RefCounted
## What one run remembers from beat to beat and chapter to chapter: the silent profile, the money
## chapter's wallet while it is open, and facts later beats look back on, such as the walking button
## having come alive. A new run starts with a fresh one. The run player hands it to every question, and
## the question player to every stage.

## The walking button came alive when pressed, in 2.11.
const BUTTON_WOKE := &"button_woke"
## The walking button bid against the player for the cigarettes, in 3.07.
const BUTTON_AUCTIONED := &"button_auctioned"

## Emitted when a chapter opens a wallet, such as the money chapter's pot.
signal wallet_opened(wallet: Wallet)
## Emitted when the chapter that opened the wallet is over.
signal wallet_closed

## The silent portrait.
var profile := Profile.new()
## The money chapter's pot while it is open, or null.
var wallet: Wallet

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
