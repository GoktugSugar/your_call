@tool
class_name WorldMap
extends InkDrawing
## A sketchbook world map in ink, for the cancer and nuke button: every landmass a hand-placed loop of
## longitude and latitude points, projected flat (each degree the same width everywhere) and smoothed
## into a slightly loose coastline. Outlines only: no borders, labels or grid. The two inland seas are
## loops of their own, and the smallest islands are dots. It draws itself on landmass by landmass.
## Its origin is the middle of the map.

## How big the map is drawn.
@export var map_size := Vector2(1360.0, 560.0):
	set(value):
		map_size = value
		_rebuild()
## The longitudes at the map's left and right edges. Running past 180 keeps the Pacific islands and
## the tip of Siberia inside the right edge.
@export var lon_range := Vector2(-170.0, 190.0):
	set(value):
		lon_range = value
		_rebuild()
## The latitudes at the map's top and bottom edges.
@export var lat_range := Vector2(84.0, -58.0):
	set(value):
		lat_range = value
		_rebuild()
## Width of the coastlines, as a multiple of the line width.
@export_range(0.1, 3.0, 0.05) var coast_width := 0.75:
	set(value):
		coast_width = value
		queue_redraw()
## Radius of an island too small to outline.
@export_range(0.5, 10.0, 0.1) var dot_radius := 2.6:
	set(value):
		dot_radius = value
		queue_redraw()

## The landmasses, each a loop of (longitude, latitude) points, biggest first so the map draws on
## from the continents down to the islands.
const _EURASIA := [
	Vector2(-9.0, 37.0), Vector2(-6.3, 36.5), Vector2(-5.6, 36.0), Vector2(-4.4, 36.7), Vector2(-2.0, 36.8),
	Vector2(-0.7, 37.6), Vector2(0.2, 38.8), Vector2(-0.3, 39.5), Vector2(0.8, 40.7), Vector2(3.2, 41.9),
	Vector2(3.1, 43.0), Vector2(4.5, 43.4), Vector2(6.0, 43.1), Vector2(7.5, 43.8), Vector2(8.9, 44.4),
	Vector2(10.2, 43.9), Vector2(11.1, 42.4), Vector2(12.5, 41.5), Vector2(14.2, 40.8), Vector2(15.6, 40.0),
	Vector2(15.7, 38.1), Vector2(16.6, 38.6), Vector2(17.1, 39.1), Vector2(17.0, 40.4), Vector2(18.5, 40.1),
	Vector2(17.0, 41.1), Vector2(16.0, 41.9), Vector2(14.1, 42.6), Vector2(13.6, 43.6), Vector2(12.3, 44.5),
	Vector2(12.4, 45.4), Vector2(13.7, 45.6), Vector2(15.2, 44.3), Vector2(16.4, 43.5), Vector2(18.1, 42.6),
	Vector2(19.4, 41.8), Vector2(19.5, 40.4), Vector2(20.4, 39.4), Vector2(21.1, 38.3), Vector2(21.7, 36.8),
	Vector2(22.5, 36.4), Vector2(23.2, 36.6), Vector2(23.1, 37.4), Vector2(24.0, 37.9), Vector2(22.9, 39.1),
	Vector2(22.9, 40.5), Vector2(24.2, 40.8), Vector2(26.0, 40.8), Vector2(26.2, 40.1), Vector2(26.8, 38.6),
	Vector2(27.4, 37.0), Vector2(28.5, 36.6), Vector2(30.6, 36.8), Vector2(32.6, 36.1), Vector2(34.6, 36.8),
	Vector2(35.9, 36.6), Vector2(35.9, 34.9), Vector2(35.5, 33.9), Vector2(34.9, 32.8), Vector2(34.3, 31.3),
	Vector2(32.6, 31.1), Vector2(32.5, 29.9), Vector2(33.3, 28.6), Vector2(34.3, 27.8), Vector2(35.0, 29.5),
	Vector2(36.5, 27.0), Vector2(38.5, 24.0), Vector2(39.2, 21.5), Vector2(41.0, 18.6), Vector2(42.7, 15.8),
	Vector2(43.3, 12.7), Vector2(45.0, 12.8), Vector2(48.5, 14.0), Vector2(52.2, 15.6), Vector2(55.3, 17.3),
	Vector2(57.7, 19.0), Vector2(59.8, 22.5), Vector2(58.5, 23.6), Vector2(56.4, 26.3), Vector2(56.0, 24.8),
	Vector2(54.5, 24.3), Vector2(51.6, 24.6), Vector2(51.2, 26.1), Vector2(50.1, 26.6), Vector2(48.5, 28.5),
	Vector2(48.2, 30.0), Vector2(50.3, 29.2), Vector2(52.6, 27.4), Vector2(56.3, 27.1), Vector2(57.5, 25.7),
	Vector2(61.5, 25.1), Vector2(66.6, 25.4), Vector2(68.3, 23.6), Vector2(69.6, 22.5), Vector2(70.4, 20.9),
	Vector2(72.6, 21.2), Vector2(72.8, 19.0), Vector2(73.7, 15.5), Vector2(74.8, 12.9), Vector2(76.2, 9.9),
	Vector2(77.5, 8.1), Vector2(78.2, 8.9), Vector2(79.8, 10.3), Vector2(80.3, 13.1), Vector2(80.2, 15.6),
	Vector2(82.3, 17.0), Vector2(85.8, 19.8), Vector2(87.0, 21.5), Vector2(88.5, 21.7), Vector2(90.5, 22.0),
	Vector2(91.8, 22.3), Vector2(92.3, 20.8), Vector2(94.3, 16.0), Vector2(95.5, 15.8), Vector2(97.6, 16.5),
	Vector2(98.3, 14.0), Vector2(98.5, 10.0), Vector2(98.3, 7.9), Vector2(100.3, 5.4), Vector2(101.5, 2.8),
	Vector2(103.5, 1.3), Vector2(104.2, 1.8), Vector2(103.4, 4.8), Vector2(102.3, 6.2), Vector2(101.0, 6.9),
	Vector2(100.3, 8.4), Vector2(99.3, 10.3), Vector2(100.0, 12.6), Vector2(100.5, 13.5), Vector2(101.0, 12.7),
	Vector2(102.5, 12.0), Vector2(103.0, 10.5), Vector2(104.8, 8.6), Vector2(106.7, 10.4), Vector2(109.2, 11.6),
	Vector2(109.3, 13.5), Vector2(108.5, 15.5), Vector2(106.7, 17.5), Vector2(105.8, 19.0), Vector2(106.7, 20.7),
	Vector2(108.3, 21.6), Vector2(110.0, 21.3), Vector2(110.5, 20.3), Vector2(111.2, 21.5), Vector2(113.5, 22.2),
	Vector2(116.5, 23.0), Vector2(118.8, 24.8), Vector2(120.0, 26.7), Vector2(121.6, 28.7), Vector2(122.0, 30.8),
	Vector2(120.9, 32.6), Vector2(119.5, 34.7), Vector2(120.3, 36.0), Vector2(122.5, 37.4), Vector2(121.0, 37.8),
	Vector2(119.0, 37.2), Vector2(117.7, 38.9), Vector2(119.5, 39.9), Vector2(121.5, 40.8), Vector2(121.2, 39.0),
	Vector2(122.3, 39.7), Vector2(124.3, 39.9), Vector2(125.2, 37.9), Vector2(126.5, 37.5), Vector2(126.3, 34.7),
	Vector2(127.5, 34.6), Vector2(129.1, 35.1), Vector2(129.4, 36.0), Vector2(129.5, 37.5), Vector2(128.3, 38.6),
	Vector2(127.5, 39.8), Vector2(129.7, 41.0), Vector2(130.6, 42.4), Vector2(131.9, 43.1), Vector2(135.2, 43.8),
	Vector2(138.6, 46.5), Vector2(140.4, 48.9), Vector2(140.5, 51.5), Vector2(141.4, 53.3), Vector2(137.5, 54.0),
	Vector2(135.3, 54.7), Vector2(138.0, 56.5), Vector2(141.5, 59.3), Vector2(149.0, 59.5), Vector2(154.5, 59.2),
	Vector2(155.8, 57.4), Vector2(156.7, 51.0), Vector2(158.7, 52.9), Vector2(162.0, 56.2), Vector2(163.3, 58.0),
	Vector2(165.5, 60.2), Vector2(170.0, 60.0), Vector2(173.0, 61.5), Vector2(178.0, 63.0), Vector2(182.0, 65.0),
	Vector2(186.5, 64.6), Vector2(189.6, 66.0), Vector2(186.0, 67.2), Vector2(180.0, 68.9), Vector2(170.0, 70.0),
	Vector2(160.0, 69.7), Vector2(150.0, 71.2), Vector2(140.0, 72.5), Vector2(130.0, 71.0), Vector2(127.0, 73.4),
	Vector2(120.0, 73.0), Vector2(113.0, 73.7), Vector2(104.3, 77.7), Vector2(100.0, 76.0), Vector2(90.0, 75.5),
	Vector2(80.0, 72.5), Vector2(75.0, 72.8), Vector2(72.5, 68.5), Vector2(68.0, 68.5), Vector2(60.0, 68.9),
	Vector2(55.0, 68.3), Vector2(50.0, 67.0), Vector2(44.0, 68.4), Vector2(40.5, 66.2), Vector2(37.0, 66.0),
	Vector2(33.0, 69.3), Vector2(25.8, 71.0), Vector2(19.0, 70.2), Vector2(14.0, 68.0), Vector2(12.5, 65.5),
	Vector2(10.0, 63.5), Vector2(5.0, 62.0), Vector2(5.0, 60.0), Vector2(5.5, 58.8), Vector2(8.0, 58.0),
	Vector2(10.5, 59.0), Vector2(11.9, 57.7), Vector2(12.5, 56.0), Vector2(14.3, 55.4), Vector2(16.5, 56.5),
	Vector2(16.6, 57.8), Vector2(18.9, 59.3), Vector2(17.4, 61.0), Vector2(17.6, 62.5), Vector2(21.0, 64.5),
	Vector2(22.5, 65.8), Vector2(25.4, 65.0), Vector2(21.6, 63.0), Vector2(21.4, 61.0), Vector2(22.5, 60.1),
	Vector2(25.0, 60.2), Vector2(28.5, 60.5), Vector2(30.2, 59.9), Vector2(28.0, 59.4), Vector2(24.7, 59.4),
	Vector2(23.4, 58.5), Vector2(24.2, 57.5), Vector2(21.0, 56.8), Vector2(21.1, 55.7), Vector2(20.5, 54.9),
	Vector2(18.6, 54.4), Vector2(16.0, 54.2), Vector2(14.2, 53.9), Vector2(12.0, 54.2), Vector2(10.6, 54.6),
	Vector2(10.9, 56.4), Vector2(10.6, 57.7), Vector2(8.6, 57.1), Vector2(8.1, 55.5), Vector2(8.6, 54.0),
	Vector2(7.0, 53.5), Vector2(4.8, 52.9), Vector2(4.3, 52.0), Vector2(3.4, 51.4), Vector2(1.9, 51.0),
	Vector2(1.6, 50.2), Vector2(0.1, 49.5), Vector2(-1.3, 49.7), Vector2(-1.6, 48.7), Vector2(-4.7, 48.4),
	Vector2(-4.3, 47.8), Vector2(-2.5, 47.3), Vector2(-1.2, 46.0), Vector2(-1.3, 44.5), Vector2(-1.6, 43.4),
	Vector2(-3.8, 43.5), Vector2(-6.0, 43.6), Vector2(-8.0, 43.7), Vector2(-9.3, 43.0), Vector2(-8.9, 41.5),
	Vector2(-8.8, 40.0), Vector2(-9.5, 38.7), Vector2(-8.8, 38.0),
]
const _AFRICA := [
	Vector2(-5.9, 35.8), Vector2(-2.0, 35.1), Vector2(1.0, 36.5), Vector2(3.0, 36.8), Vector2(8.0, 37.0),
	Vector2(10.2, 37.3), Vector2(11.0, 35.5), Vector2(10.1, 33.9), Vector2(11.5, 33.2), Vector2(13.2, 32.9),
	Vector2(15.5, 31.5), Vector2(19.0, 30.3), Vector2(20.1, 32.1), Vector2(22.0, 32.9), Vector2(25.0, 31.7),
	Vector2(29.0, 30.9), Vector2(31.0, 31.5), Vector2(32.2, 31.2), Vector2(32.4, 29.8), Vector2(33.6, 27.2),
	Vector2(35.5, 23.9), Vector2(37.2, 19.6), Vector2(38.6, 18.0), Vector2(39.5, 15.6), Vector2(41.5, 13.8),
	Vector2(43.2, 11.6), Vector2(44.0, 10.4), Vector2(47.0, 11.2), Vector2(51.3, 11.8), Vector2(51.0, 10.4),
	Vector2(49.0, 6.5), Vector2(46.5, 3.5), Vector2(43.0, 0.0), Vector2(40.5, -2.5), Vector2(39.6, -4.0),
	Vector2(39.3, -6.8), Vector2(40.5, -10.5), Vector2(40.6, -15.0), Vector2(37.0, -18.0), Vector2(35.0, -21.0),
	Vector2(35.5, -24.0), Vector2(32.9, -26.0), Vector2(32.4, -28.5), Vector2(31.0, -29.9), Vector2(28.0, -32.8),
	Vector2(25.6, -34.0), Vector2(20.0, -34.8), Vector2(18.4, -34.3), Vector2(18.2, -32.0), Vector2(16.5, -28.6),
	Vector2(14.5, -22.9), Vector2(11.8, -17.2), Vector2(13.5, -12.0), Vector2(13.2, -8.8), Vector2(12.2, -6.0),
	Vector2(9.2, -1.0), Vector2(9.5, 3.8), Vector2(8.5, 4.5), Vector2(6.0, 4.3), Vector2(3.4, 6.4),
	Vector2(0.0, 5.6), Vector2(-3.0, 5.1), Vector2(-7.5, 4.4), Vector2(-11.0, 6.8), Vector2(-13.2, 8.5),
	Vector2(-15.0, 10.8), Vector2(-17.0, 13.5), Vector2(-17.5, 14.7), Vector2(-16.5, 16.5), Vector2(-16.0, 19.5),
	Vector2(-17.0, 21.0), Vector2(-15.0, 24.0), Vector2(-13.0, 27.5), Vector2(-10.0, 29.5), Vector2(-9.8, 31.5),
	Vector2(-8.5, 33.3), Vector2(-6.8, 34.0), Vector2(-6.0, 35.5),
]
const _NORTH_AMERICA := [
	Vector2(-168.0, 65.6), Vector2(-162.0, 70.0), Vector2(-156.0, 71.3), Vector2(-148.0, 70.3),
	Vector2(-140.0, 69.6), Vector2(-128.0, 70.0), Vector2(-115.0, 68.5), Vector2(-105.0, 68.0), Vector2(-95.0, 69.0),
	Vector2(-87.0, 68.0), Vector2(-90.0, 64.0), Vector2(-94.0, 59.0), Vector2(-92.0, 57.0), Vector2(-85.0, 55.3),
	Vector2(-82.0, 52.5), Vector2(-79.0, 54.5), Vector2(-77.5, 58.0), Vector2(-78.0, 61.5), Vector2(-73.0, 62.3),
	Vector2(-69.5, 61.0), Vector2(-65.0, 60.3), Vector2(-61.0, 56.0), Vector2(-56.0, 51.5), Vector2(-59.0, 48.0),
	Vector2(-64.5, 49.0), Vector2(-61.0, 45.5), Vector2(-66.0, 43.8), Vector2(-70.0, 41.7), Vector2(-74.0, 40.5),
	Vector2(-75.5, 37.5), Vector2(-76.0, 35.0), Vector2(-79.0, 33.0), Vector2(-81.2, 31.0), Vector2(-80.5, 28.0),
	Vector2(-80.1, 25.3), Vector2(-81.5, 25.6), Vector2(-82.5, 27.5), Vector2(-83.5, 29.8), Vector2(-85.0, 29.6),
	Vector2(-88.0, 30.4), Vector2(-89.5, 29.0), Vector2(-91.5, 29.5), Vector2(-94.0, 29.6), Vector2(-97.0, 27.5),
	Vector2(-97.5, 25.5), Vector2(-97.8, 22.0), Vector2(-96.5, 19.5), Vector2(-94.5, 18.2), Vector2(-91.0, 18.7),
	Vector2(-90.4, 21.0), Vector2(-87.0, 21.5), Vector2(-87.5, 18.5), Vector2(-88.5, 16.0), Vector2(-86.0, 16.0),
	Vector2(-83.5, 15.0), Vector2(-83.5, 11.0), Vector2(-82.0, 9.0), Vector2(-79.5, 9.5), Vector2(-77.5, 8.6),
	Vector2(-78.0, 7.5), Vector2(-80.0, 7.5), Vector2(-83.0, 8.3), Vector2(-85.8, 10.3), Vector2(-87.5, 13.0),
	Vector2(-91.0, 14.0), Vector2(-94.0, 16.0), Vector2(-96.5, 15.7), Vector2(-100.0, 17.0), Vector2(-104.5, 19.2),
	Vector2(-105.5, 20.5), Vector2(-105.8, 22.5), Vector2(-109.0, 25.5), Vector2(-112.0, 29.0), Vector2(-114.7, 31.7),
	Vector2(-113.0, 29.0), Vector2(-111.0, 25.5), Vector2(-109.9, 22.9), Vector2(-112.0, 24.7), Vector2(-114.2, 27.8),
	Vector2(-116.5, 31.5), Vector2(-117.2, 32.6), Vector2(-118.5, 34.0), Vector2(-120.6, 34.5), Vector2(-122.5, 37.8),
	Vector2(-124.2, 40.4), Vector2(-124.5, 43.0), Vector2(-124.0, 46.5), Vector2(-124.7, 48.4), Vector2(-127.5, 50.5),
	Vector2(-130.5, 54.0), Vector2(-133.0, 56.5), Vector2(-136.5, 58.2), Vector2(-140.0, 59.8), Vector2(-145.0, 60.3),
	Vector2(-149.5, 60.0), Vector2(-154.0, 57.5), Vector2(-158.0, 56.7), Vector2(-162.0, 55.2), Vector2(-164.5, 54.5),
	Vector2(-161.0, 58.6), Vector2(-165.0, 60.5), Vector2(-164.5, 63.0), Vector2(-161.0, 64.5), Vector2(-166.2, 64.6),
]
const _SOUTH_AMERICA := [
	Vector2(-77.4, 8.6), Vector2(-76.0, 9.5), Vector2(-75.5, 10.4), Vector2(-74.2, 11.2), Vector2(-71.6, 12.4),
	Vector2(-71.0, 11.0), Vector2(-68.0, 10.5), Vector2(-64.0, 10.7), Vector2(-61.9, 10.4), Vector2(-60.0, 8.5),
	Vector2(-57.0, 6.0), Vector2(-52.5, 5.0), Vector2(-51.0, 4.0), Vector2(-50.0, 1.5), Vector2(-48.5, -1.4),
	Vector2(-44.5, -2.5), Vector2(-40.0, -3.0), Vector2(-37.0, -5.0), Vector2(-34.8, -7.1), Vector2(-35.0, -9.0),
	Vector2(-37.5, -12.0), Vector2(-38.9, -15.0), Vector2(-39.2, -17.5), Vector2(-40.3, -20.3), Vector2(-42.0, -23.0),
	Vector2(-45.0, -23.8), Vector2(-48.0, -26.0), Vector2(-48.6, -28.5), Vector2(-51.0, -31.5), Vector2(-53.0, -33.8),
	Vector2(-56.0, -34.9), Vector2(-57.5, -35.5), Vector2(-57.0, -37.5), Vector2(-61.0, -39.0), Vector2(-63.0, -41.0),
	Vector2(-65.0, -42.5), Vector2(-67.5, -46.0), Vector2(-65.8, -47.8), Vector2(-69.0, -51.0), Vector2(-68.4, -52.4),
	Vector2(-68.6, -54.8), Vector2(-67.3, -55.9), Vector2(-70.0, -55.0), Vector2(-73.0, -53.0), Vector2(-75.0, -50.0),
	Vector2(-74.5, -46.5), Vector2(-73.8, -43.0), Vector2(-73.7, -40.0), Vector2(-73.5, -37.0), Vector2(-71.7, -33.0),
	Vector2(-71.5, -30.0), Vector2(-70.5, -25.0), Vector2(-70.2, -20.0), Vector2(-70.3, -18.3), Vector2(-72.5, -16.5),
	Vector2(-76.2, -13.6), Vector2(-77.1, -12.0), Vector2(-79.5, -8.0), Vector2(-81.3, -4.7), Vector2(-80.4, -2.5),
	Vector2(-80.1, 0.0), Vector2(-79.0, 1.5), Vector2(-77.7, 3.5), Vector2(-77.3, 6.5),
]
const _AUSTRALIA := [
	Vector2(113.5, -22.0), Vector2(114.2, -26.0), Vector2(114.9, -29.5), Vector2(115.0, -33.6), Vector2(115.0, -34.4),
	Vector2(118.0, -35.0), Vector2(121.9, -33.9), Vector2(124.0, -32.9), Vector2(129.0, -31.6), Vector2(131.5, -31.5),
	Vector2(134.2, -32.8), Vector2(135.6, -34.8), Vector2(137.6, -33.0), Vector2(137.8, -35.5), Vector2(138.6, -34.9),
	Vector2(139.7, -37.3), Vector2(140.9, -38.0), Vector2(143.5, -38.8), Vector2(145.0, -38.3), Vector2(146.3, -39.1),
	Vector2(148.0, -37.8), Vector2(150.0, -37.5), Vector2(151.2, -33.9), Vector2(152.9, -31.5), Vector2(153.6, -28.6),
	Vector2(153.0, -25.2), Vector2(151.0, -23.5), Vector2(149.3, -21.2), Vector2(146.8, -19.2), Vector2(145.8, -16.9),
	Vector2(145.3, -14.9), Vector2(143.6, -14.0), Vector2(142.5, -10.7), Vector2(141.6, -13.0), Vector2(141.5, -16.5),
	Vector2(139.5, -17.4), Vector2(137.8, -16.0), Vector2(136.5, -15.0), Vector2(135.9, -13.3), Vector2(136.8, -12.2),
	Vector2(132.5, -11.4), Vector2(130.8, -12.4), Vector2(129.5, -14.9), Vector2(128.0, -15.2), Vector2(125.0, -14.4),
	Vector2(123.5, -16.5), Vector2(122.2, -18.0), Vector2(119.0, -20.0), Vector2(116.5, -20.7),
]
const _GREENLAND := [
	Vector2(-73.0, 78.2), Vector2(-65.0, 81.5), Vector2(-45.0, 83.0), Vector2(-30.0, 83.3), Vector2(-20.0, 82.0),
	Vector2(-18.0, 77.0), Vector2(-20.0, 73.5), Vector2(-22.0, 70.3), Vector2(-26.0, 68.5), Vector2(-32.0, 68.0),
	Vector2(-38.0, 65.6), Vector2(-41.0, 63.0), Vector2(-43.5, 60.0), Vector2(-48.0, 61.0), Vector2(-51.5, 64.0),
	Vector2(-53.5, 66.5), Vector2(-51.5, 69.0), Vector2(-54.0, 70.8), Vector2(-56.0, 74.0), Vector2(-61.0, 76.0),
	Vector2(-68.0, 77.0),
]
const _BAFFIN := [
	Vector2(-80.0, 73.5), Vector2(-72.0, 71.5), Vector2(-68.0, 70.4), Vector2(-62.0, 66.8), Vector2(-63.5, 64.5),
	Vector2(-66.0, 62.0), Vector2(-72.0, 63.0), Vector2(-76.0, 64.2), Vector2(-78.0, 66.0), Vector2(-80.0, 69.0),
	Vector2(-86.0, 70.0),
]
const _MADAGASCAR := [
	Vector2(49.3, -12.0), Vector2(50.5, -15.5), Vector2(49.8, -17.0), Vector2(48.0, -22.0), Vector2(47.1, -24.9),
	Vector2(45.2, -25.6), Vector2(43.7, -23.0), Vector2(44.3, -20.0), Vector2(44.0, -17.5), Vector2(46.2, -15.7),
	Vector2(48.0, -13.5),
]
const _NEW_GUINEA := [
	Vector2(131.0, -1.5), Vector2(134.0, -0.9), Vector2(138.0, -1.6), Vector2(141.0, -2.6), Vector2(145.5, -4.5),
	Vector2(147.0, -6.5), Vector2(149.5, -9.5), Vector2(150.5, -10.5), Vector2(147.0, -10.0), Vector2(144.0, -7.8),
	Vector2(142.5, -9.2), Vector2(141.0, -9.1), Vector2(138.5, -8.3), Vector2(137.5, -5.0), Vector2(134.5, -4.0),
	Vector2(132.5, -3.0),
]
const _BORNEO := [
	Vector2(109.0, 1.5), Vector2(109.6, -1.0), Vector2(110.5, -3.0), Vector2(114.0, -3.6), Vector2(116.3, -3.3),
	Vector2(116.0, -1.0), Vector2(117.8, 1.0), Vector2(119.0, 5.0), Vector2(117.0, 7.0), Vector2(116.0, 6.0),
	Vector2(114.5, 4.5), Vector2(113.0, 3.2), Vector2(111.0, 2.0),
]
const _SUMATRA := [
	Vector2(95.3, 5.6), Vector2(98.0, 4.0), Vector2(100.5, 2.0), Vector2(103.7, -1.0), Vector2(106.0, -3.0),
	Vector2(105.8, -5.8), Vector2(104.0, -5.0), Vector2(101.0, -2.5), Vector2(98.5, 0.5), Vector2(96.0, 3.5),
]
const _JAVA := [
	Vector2(105.2, -6.8), Vector2(108.0, -6.3), Vector2(111.0, -6.4), Vector2(114.5, -7.7), Vector2(114.4, -8.7),
	Vector2(111.0, -8.3), Vector2(108.0, -7.8), Vector2(105.5, -7.3),
]
const _SULAWESI := [
	Vector2(118.8, -3.0), Vector2(119.5, 0.5), Vector2(120.9, 1.3), Vector2(124.9, 1.5), Vector2(123.0, 0.6),
	Vector2(121.0, 0.4), Vector2(121.6, -0.9), Vector2(123.3, -0.9), Vector2(121.7, -2.0), Vector2(122.5, -4.5),
	Vector2(120.7, -2.9), Vector2(120.4, -5.5), Vector2(119.4, -5.4),
]
const _HONSHU := [
	Vector2(130.9, 34.0), Vector2(132.5, 35.4), Vector2(135.2, 35.7), Vector2(136.8, 37.3), Vector2(138.5, 37.4),
	Vector2(139.8, 38.5), Vector2(140.0, 40.3), Vector2(140.9, 41.5), Vector2(141.5, 40.6), Vector2(142.0, 39.0),
	Vector2(141.0, 38.2), Vector2(141.0, 36.9), Vector2(140.8, 35.7), Vector2(139.8, 35.0), Vector2(138.8, 34.6),
	Vector2(137.0, 34.6), Vector2(136.0, 33.5), Vector2(135.0, 34.2), Vector2(133.0, 34.3), Vector2(132.0, 33.8),
]
const _KYUSHU := [
	Vector2(129.8, 33.6), Vector2(131.0, 33.9), Vector2(131.9, 32.8), Vector2(131.1, 31.3), Vector2(130.2, 31.2),
	Vector2(129.9, 32.6),
]
const _HOKKAIDO := [
	Vector2(140.0, 42.6), Vector2(140.4, 43.3), Vector2(141.6, 45.4), Vector2(143.5, 44.2), Vector2(145.3, 44.0),
	Vector2(145.5, 43.3), Vector2(143.3, 42.0), Vector2(141.0, 41.8),
]
const _SAKHALIN := [
	Vector2(142.0, 54.2), Vector2(143.2, 51.5), Vector2(143.5, 49.0), Vector2(142.5, 46.0), Vector2(141.9, 46.6),
	Vector2(142.0, 50.0), Vector2(141.7, 53.0),
]
const _GREAT_BRITAIN := [
	Vector2(-5.7, 50.1), Vector2(1.4, 51.1), Vector2(1.7, 52.6), Vector2(0.3, 53.4), Vector2(-1.3, 54.6),
	Vector2(-2.0, 55.9), Vector2(-3.0, 58.6), Vector2(-5.0, 58.6), Vector2(-6.1, 57.0), Vector2(-5.6, 55.3),
	Vector2(-3.3, 54.4), Vector2(-3.0, 53.4), Vector2(-4.5, 52.8), Vector2(-5.2, 51.8), Vector2(-4.0, 51.2),
]
const _IRELAND := [
	Vector2(-6.0, 52.2), Vector2(-6.0, 53.9), Vector2(-7.3, 55.3), Vector2(-8.5, 54.8), Vector2(-10.0, 54.1),
	Vector2(-9.6, 53.0), Vector2(-10.2, 51.8), Vector2(-8.5, 51.6), Vector2(-7.0, 52.1),
]
const _ICELAND := [
	Vector2(-24.0, 65.5), Vector2(-22.0, 66.4), Vector2(-16.0, 66.5), Vector2(-13.5, 65.2), Vector2(-15.0, 64.2),
	Vector2(-18.5, 63.4), Vector2(-22.5, 63.8), Vector2(-24.0, 64.8),
]
const _NORTH_ISLAND := [
	Vector2(172.7, -34.4), Vector2(174.8, -36.8), Vector2(175.9, -37.0), Vector2(178.5, -37.7), Vector2(177.0, -39.6),
	Vector2(176.2, -41.0), Vector2(174.8, -41.3), Vector2(175.0, -39.8), Vector2(173.8, -39.3), Vector2(174.6, -38.0),
	Vector2(173.0, -35.2),
]
const _SOUTH_ISLAND := [
	Vector2(172.7, -40.5), Vector2(174.0, -41.2), Vector2(174.2, -41.7), Vector2(173.0, -43.0), Vector2(172.9, -43.8),
	Vector2(171.2, -44.4), Vector2(170.5, -45.9), Vector2(168.4, -46.6), Vector2(166.5, -46.0), Vector2(167.0, -45.0),
	Vector2(168.5, -43.9), Vector2(170.3, -43.0), Vector2(171.5, -41.7),
]
const _TASMANIA := [
	Vector2(144.7, -40.7), Vector2(148.3, -40.9), Vector2(148.0, -43.0), Vector2(146.8, -43.6), Vector2(145.2, -42.2),
]
const _CUBA := [
	Vector2(-84.9, 21.9), Vector2(-83.0, 23.0), Vector2(-80.0, 23.2), Vector2(-77.5, 21.8), Vector2(-74.2, 20.2),
	Vector2(-77.0, 19.9), Vector2(-78.0, 20.7), Vector2(-80.5, 21.8), Vector2(-82.0, 22.2),
]
const _HISPANIOLA := [
	Vector2(-74.4, 18.5), Vector2(-72.8, 19.9), Vector2(-70.0, 19.7), Vector2(-68.4, 18.6), Vector2(-70.0, 18.2),
	Vector2(-71.6, 17.7), Vector2(-74.0, 18.1),
]
const _JAMAICA := [
	Vector2(-78.4, 18.4), Vector2(-77.0, 18.6), Vector2(-76.2, 18.0), Vector2(-77.2, 17.8),
]
const _SRI_LANKA := [
	Vector2(80.0, 9.8), Vector2(81.2, 8.5), Vector2(81.9, 7.0), Vector2(81.0, 6.1), Vector2(80.0, 6.0),
	Vector2(79.8, 7.5),
]
const _SICILY := [
	Vector2(12.4, 38.1), Vector2(15.6, 38.3), Vector2(15.1, 36.7), Vector2(12.5, 37.6),
]
const _TAIWAN := [
	Vector2(120.1, 23.0), Vector2(121.0, 25.2), Vector2(121.9, 24.5), Vector2(120.9, 22.0),
]
const _LUZON := [
	Vector2(120.5, 18.5), Vector2(122.2, 18.5), Vector2(122.0, 16.5), Vector2(121.6, 14.2), Vector2(124.0, 12.6),
	Vector2(123.0, 13.8), Vector2(120.6, 14.4), Vector2(119.8, 16.2),
]
const _MINDANAO := [
	Vector2(122.0, 7.0), Vector2(126.5, 8.0), Vector2(126.2, 6.0), Vector2(125.4, 5.6), Vector2(124.0, 6.5),
]
const _FIJI := [
	Vector2(177.3, -17.5), Vector2(178.0, -17.3), Vector2(178.6, -17.8), Vector2(178.0, -18.3), Vector2(177.3, -18.0),
]
## The inland seas, drawn as loops of their own inside the land.
const _BLACK_SEA := [
	Vector2(28.0, 41.6), Vector2(28.6, 43.4), Vector2(29.6, 45.2), Vector2(30.7, 46.5), Vector2(32.0, 46.2),
	Vector2(33.5, 44.5), Vector2(35.5, 45.1), Vector2(36.6, 45.3), Vector2(38.0, 44.5), Vector2(39.8, 43.4),
	Vector2(41.6, 41.6), Vector2(39.7, 41.0), Vector2(36.3, 41.3), Vector2(35.0, 42.0), Vector2(32.0, 41.8),
	Vector2(30.0, 41.2),
]
const _CASPIAN := [
	Vector2(47.0, 44.5), Vector2(49.0, 46.6), Vector2(51.5, 47.0), Vector2(53.0, 45.3), Vector2(51.0, 44.5),
	Vector2(51.3, 42.5), Vector2(52.9, 41.9), Vector2(53.0, 40.0), Vector2(53.9, 37.3), Vector2(51.6, 36.7),
	Vector2(49.5, 37.5), Vector2(49.0, 38.5), Vector2(49.5, 40.3), Vector2(48.0, 42.5),
]
## Islands too small to outline at this scale: Malta, Nauru and Tuvalu.
const _DOTS := [Vector2(14.4, 35.9), Vector2(166.92, -0.53), Vector2(179.2, -8.52)]
const _LOOPS := [_EURASIA, _AFRICA, _NORTH_AMERICA, _SOUTH_AMERICA, _AUSTRALIA, _GREENLAND, _BAFFIN,
		_MADAGASCAR, _NEW_GUINEA, _BORNEO, _SUMATRA, _JAVA, _SULAWESI, _HONSHU, _KYUSHU, _HOKKAIDO, _SAKHALIN,
		_GREAT_BRITAIN, _IRELAND, _ICELAND, _NORTH_ISLAND, _SOUTH_ISLAND, _TASMANIA, _CUBA, _HISPANIOLA,
		_JAMAICA, _SRI_LANKA, _SICILY, _TAIWAN, _LUZON, _MINDANAO, _FIJI, _BLACK_SEA, _CASPIAN]

## The coastlines, projected and smoothed, kept until the map's size or extent changes.
var _coasts: Array[PackedVector2Array] = []
var _coast_spacing := 0.0


## Where [param lon] and [param lat] fall on the map, in its own space. A longitude west of the left
## edge comes round again from the right.
func project(lon: float, lat: float) -> Vector2:
	var east := lon if lon >= lon_range.x else lon + 360.0
	var x := (east - lon_range.x) / (lon_range.y - lon_range.x)
	var y := (lat - lat_range.x) / (lat_range.y - lat_range.x)
	return Vector2((x - 0.5) * map_size.x, (y - 0.5) * map_size.y)


## Whether [param lon] and [param lat] fall inside the map.
func covers(lon: float, lat: float) -> bool:
	var at := project(lon, lat)
	return absf(at.x) <= map_size.x * 0.5 and absf(at.y) <= map_size.y * 0.5


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	if _coasts.is_empty() or not is_equal_approx(_coast_spacing, style.sample_spacing):
		_coasts = _project_coasts(style.sample_spacing)
		_coast_spacing = style.sample_spacing
	var lines: Array[InkLine] = []
	for coast in _coasts:
		lines.append(InkLine.along(coast, palette.ink, coast_width, true))
	for dot: Vector2 in _DOTS:
		lines.append(InkLine.dot(project(dot.x, dot.y), dot_radius, palette.ink))
	return lines


func _project_coasts(spacing: float) -> Array[PackedVector2Array]:
	var coasts: Array[PackedVector2Array] = []
	for loop: Array in _LOOPS:
		var points := PackedVector2Array()
		for point: Vector2 in loop:
			points.append(project(point.x, point.y))
		coasts.append(InkBrush.resample_smooth(points, true, spacing))
	return coasts


func _rebuild() -> void:
	_coasts.clear()
	queue_redraw()
