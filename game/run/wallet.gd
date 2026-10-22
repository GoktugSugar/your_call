class_name Wallet
extends RefCounted
## The money chapter's pot: what the player started with, what is left, everything they bought in the
## order they bought it, and what they passed on. Buying spends from it, the buyback pays back into it,
## and the receipt reads it at the end.

## Emitted whenever the balance changes, with the balance as it is now.
signal changed(balance: int)

## What the player started with.
var start := 0
## What is left to spend.
var balance := 0
## What was bought and is still owned, in the order it was first bought.
var bought: Array[Purchase] = []
## What was passed on, or could not be afforded, in the order it was offered.
var passed: Array[Purchase] = []


func _init(starting := 0) -> void:
	start = starting
	balance = starting


## Whether [param price] can be paid out of what is left.
func can_afford(price: int) -> bool:
	return price <= balance


## Pays for [param item] and keeps it. Buying more of something already owned adds to it.
func buy(item: Purchase) -> void:
	balance -= item.paid
	var owned := find(item.id)
	if owned != null:
		owned.paid += item.paid
		owned.units += item.units
	else:
		bought.append(item)
	changed.emit(balance)


## Gives [param item] back for [param refund]: the money goes back in, and the thing is gone from
## what was bought, as if it had never been.
func sell(item: Purchase, refund: int) -> void:
	bought.erase(item)
	balance += refund
	changed.emit(balance)


## Remembers that [param item] was passed on.
func pass_on(item: Purchase) -> void:
	passed.append(item)


## What is owned with [param item_id], or null.
func find(item_id: StringName) -> Purchase:
	for item in bought:
		if item.id == item_id:
			return item
	return null


## How much of the pot has gone, buybacks netted out. Never below nothing.
func spent() -> int:
	return maxi(start - balance, 0)


## The share of the pot still left, from 0 to 1.
func share_left() -> float:
	return clampf(float(balance) / start, 0.0, 1.0) if start > 0 else 0.0
