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


## The purchase as plain data, for the save.
func to_data() -> Dictionary:
	return {"id": String(id), "label": label, "doodle": doodle, "paid": paid, "units": units,
			"buyback_share": buyback_share}


## A purchase from [method to_data], or null when [param data] is not one.
static func from_data(data: Variant) -> Purchase:
	if not data is Dictionary or not SaveData.has_text(data, ["id", "label", "doodle"]) \
			or not SaveData.has_numbers(data, ["paid", "units", "buyback_share"]):
		return null
	var made := make(StringName(data["id"]), data["label"], data["doodle"], int(data["paid"]))
	made.units = int(data["units"])
	made.buyback_share = float(data["buyback_share"])
	return made
