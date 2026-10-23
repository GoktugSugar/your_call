class_name Numbers
extends RefCounted
## How numbers read on screen and in the imp's mouth: digits grouped in threes, money with its sign.

## The currency sign in front of an amount of money.
const CURRENCY := "$"
## What goes between groups of three digits.
const GROUP_MARK := ","


## [param value] with its digits grouped in threes, such as [code]1,430,000,000[/code]. Player-facing
## text has no dashes, so a count is never shown below zero.
static func grouped(value: int) -> String:
	var digits := str(maxi(value, 0))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += GROUP_MARK
		out += digits[i]
	return out


## [param value] as money, such as [code]$12,500[/code].
static func money(value: int) -> String:
	return CURRENCY + grouped(value)


## A count too big to write out, the way it is said, to its leading figure: [code]a thousand billion
## billion[/code], [code]30 million billion[/code]. Counts under a million are written out in full.
static func huge(value: float) -> String:
	if value < 1000000.0:
		return grouped(roundi(value))
	var power := floori(log(value) / log(10.0))
	var lead := roundi(value / pow(10.0, power))
	if lead >= 10:
		lead = 1
		power += 1
	var billions := floori(power / 9.0)
	var rest := power % 9
	var words := ""
	if rest >= 6:
		words = _lead_words(lead * roundi(pow(10.0, rest - 6)), "million")
	elif rest >= 3:
		words = _lead_words(lead * roundi(pow(10.0, rest - 3)), "thousand")
	else:
		words = _lead_words(lead * roundi(pow(10.0, rest)), "")
	for i in billions:
		words += " billion"
	return words.strip_edges()


## [param count] of [param unit], [code]a thousand[/code] for one of them.
static func _lead_words(count: int, unit: String) -> String:
	if unit == "":
		return "a" if count == 1 else grouped(count)
	return ("a " if count == 1 else grouped(count) + " ") + unit
