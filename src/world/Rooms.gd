extends Reference
# Room layouts in 16px tiles. Every room is 14 tiles (one screen) tall and
# connects to its left/right neighbors: walking off an open edge loads the
# next room at the same height, so edge floors all sit on row 12.
#
# solids:   [x, y, w, h] blocks of ground
# entities: [kind, x, y] placed on the bottom of tile (x, y)
#   spawn, walker, flyer, sentinel (boss), health, core_gale, goal
#   [boss_door, x, y, w, h]   wall that opens when the room's boss is beaten
#   [reward, core, x, y]      core that appears once the boss is beaten

const TILE := 16

const THEMES := {
	"forest": {"sky_top": Color("142238"), "sky_bottom": Color("3d6e7a"), "far": Color("24465a"), "near": Color("1a3a34"),
		"tile": Color("5b5a44"), "tile_light": Color("8d8a62"), "tile_dark": Color("2f2e22"), "top": Color("67b347"),
		"stars": false, "style": "trees"},
	"ruins": {"sky_top": Color("1c1230"), "sky_bottom": Color("6a3d5c"), "far": Color("34234a"), "near": Color("251a36"),
		"tile": Color("625a78"), "tile_light": Color("958cb0"), "tile_dark": Color("312c42"), "top": Color("b79be0"),
		"stars": true, "style": "pillars"},
	"wind": {"sky_top": Color("3f86c4"), "sky_bottom": Color("c6ecff"), "far": Color("8dbfe0"), "near": Color("6aa0c2"),
		"tile": Color("8a7e6a"), "tile_light": Color("c9bc9c"), "tile_dark": Color("4a4236"), "top": Color("eef6f2"),
		"stars": false, "style": "clouds"},
	"summit": {"sky_top": Color("06071a"), "sky_bottom": Color("3a2d66"), "far": Color("221f48"), "near": Color("17142f"),
		"tile": Color("55576b"), "tile_light": Color("8d90a8"), "tile_dark": Color("2a2b38"), "top": Color("a8f0ff"),
		"stars": true, "style": "pillars"},
}

const ROOMS := {
	"start": {
		"name": "VERDANT RUN", "theme": "forest", "size": Vector2(50, 14), "left": "", "right": "cliffs",
		"solids": [[0, 0, 50, 1], [0, 12, 50, 2], [0, 1, 1, 11], [14, 8, 3, 1], [22, 6, 4, 1],
			[23, 11, 6, 1], [34, 8, 4, 1], [41, 10, 2, 2]],
		"entities": [["spawn", 4, 11], ["walker", 30, 11], ["flyer", 38, 5], ["health", 23, 5]],
	},
	"cliffs": {
		"name": "BROKEN AQUEDUCT", "theme": "ruins", "size": Vector2(60, 14), "left": "start", "right": "gate",
		"solids": [[0, 0, 60, 1], [0, 12, 10, 2], [14, 4, 3, 10], [17, 12, 43, 2], [22, 8, 3, 1],
			[28, 6, 3, 1], [36, 9, 2, 3], [44, 1, 1, 8], [50, 10, 4, 2]],
		"entities": [["flyer", 8, 5], ["flyer", 25, 4], ["walker", 31, 11], ["walker", 48, 11], ["health", 29, 5]],
	},
	"gate": {
		"name": "SENTINEL GATE", "theme": "ruins", "size": Vector2(25, 14), "left": "cliffs", "right": "windway",
		"solids": [[0, 0, 25, 1], [0, 12, 25, 2], [4, 8, 3, 1], [18, 8, 3, 1]],
		"entities": [["sentinel", 16, 11], ["boss_door", 24, 1, 1, 11], ["reward", "ember", 12, 10]],
	},
	"windway": {
		"name": "SKYWARD SPAN", "theme": "wind", "size": Vector2(80, 14), "left": "gate", "right": "summit",
		"solids": [[0, 0, 80, 1], [0, 12, 12, 2], [17, 12, 8, 2], [33, 12, 10, 2], [47, 10, 3, 1],
			[53, 8, 3, 1], [59, 10, 3, 1], [66, 12, 14, 2], [72, 9, 2, 3]],
		"entities": [["core_gale", 6, 10], ["flyer", 20, 6], ["walker", 37, 11], ["flyer", 40, 5],
			["flyer", 56, 4], ["health", 54, 7], ["walker", 76, 11]],
	},
	"summit": {
		"name": "THE SUMMIT", "theme": "summit", "size": Vector2(25, 14), "left": "windway", "right": "",
		"solids": [[0, 0, 25, 1], [0, 12, 25, 2], [24, 1, 1, 11], [10, 10, 5, 2]],
		"entities": [["goal", 12, 9]],
	},
}
