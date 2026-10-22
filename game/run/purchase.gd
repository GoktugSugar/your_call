class_name Purchase
extends RefCounted
## One thing on offer in the money chapter, as the wallet remembers it: bought, with what was paid
## for it, or passed on. The buyback and the receipt read these.

## The id of the question that offered it, such as [code]charisma[/code]. A thing bought again, such as
## another year, adds to the purchase with the same id.
var id := &""
## Its name on the receipt, such as [code]Charisma[/code]. Plain text.
var label := ""
## The doodle it is drawn with, by id.
var doodle := ""
## Everything paid for it so far, or its price when it was passed on.
var paid := 0
## How many were bought, such as years of a stranger's life. One for most things.
var units := 1
## The share of what was paid the buyback offers for it, in percent, or below zero for the buyback's own.
var buyback_share := -1.0


static func make(item_id: StringName, item_label: String, item_doodle: String, price: int) -> Purchase:
	var made := Purchase.new()
	made.id = item_id
	made.label = item_label
	made.doodle = item_doodle
	made.paid = price
	return made
