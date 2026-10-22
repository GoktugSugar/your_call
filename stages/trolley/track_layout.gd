class_name TrackLayout
extends Node2D
## One way the line splits past the approach: a fork whose branch a lever throws the trolley onto,
## or a fan of routes the player points into. The trolley stage shows the layout with as many routes
## as its question has tracks, and hides the rest.

## The routes beyond the split, in data order.
@export var routes: Array[Track] = []
## Whether a lever throws the trolley onto the branch. Without one, the player points at a route.
@export var has_lever := true
