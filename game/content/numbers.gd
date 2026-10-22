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
