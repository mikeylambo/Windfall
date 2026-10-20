extends RefCounted
class_name WPal

## The WINDFALL master palette.
## Every sprite, tile, icon and UI texture is painted from these ramps so the
## whole game reads as one cohesive set. Ramps run dark -> light.

const OUTLINE := Color("2a1d27")        # warm plum-brown, never pure black
const OUTLINE_SOFT := Color("4a3040")
const SHADOW := Color(0.11, 0.06, 0.12, 0.38)
const WHITE := Color("fff7e6")
const INK := Color("1a1220")

const GRASS := [Color("1e3b2a"), Color("2d5a3a"), Color("3f7d45"), Color("5ea24d"), Color("8cc65a"), Color("c2e078")]
const GRASS_WILD := [Color("16302a"), Color("23493a"), Color("336845"), Color("4c8a4c"), Color("74b05a")]
const LEAF := [Color("163a2a"), Color("24573a"), Color("357a42"), Color("4f9e48"), Color("7cc35a"), Color("b4e07a")]
const WOOD := [Color("2e1c1a"), Color("4a2e22"), Color("6b4430"), Color("8f5d3b"), Color("b57d4e"), Color("d9a66b")]
const BARK := [Color("2a1a1a"), Color("43291f"), Color("62402c"), Color("82583a"), Color("a5774c")]
const SOIL := [Color("2b1c19"), Color("3f2a22"), Color("5a3c2c"), Color("77513a"), Color("94694a")]
const DIRT := [Color("5a3f2e"), Color("7a5a3e"), Color("9c7a52"), Color("b9966a"), Color("d4b88a")]
const STONE := [Color("2c2c3a"), Color("3d3f4e"), Color("5e6175"), Color("8a8ea3"), Color("c3c6d4")]
const ROOF := [Color("3a1a22"), Color("5e2430"), Color("8a3438"), Color("b4503e"), Color("d9784e")]
const CREAM := [Color("a88d6a"), Color("cdb48c"), Color("eadcb8"), Color("fff7e6")]
const SKIN := [Color("6b3f35"), Color("a96b4f"), Color("d99c74"), Color("f2c9a0"), Color("ffe3c4")]
const BARKSKIN := [Color("3d2a22"), Color("6b4a35"), Color("9a7050"), Color("c49a6c"), Color("e4c294")]
const MOSS := [Color("1f3b26"), Color("2f5a34"), Color("467d3e"), Color("6ca04a"), Color("9cc65e")]
const WATER := [Color("142447"), Color("1d3a6e"), Color("2a5c9c"), Color("3f86c4"), Color("79bde6"), Color("c4ecff")]
const GOLD := [Color("6a4210"), Color("a86a1a"), Color("dca032"), Color("f2c94e"), Color("fff0a0")]
const RED := [Color("4a1426"), Color("6e1f2c"), Color("a8323b"), Color("e05a46"), Color("ff9b6a")]
const CLOTH_RUSSET := [Color("2a1416"), Color("4a2222"), Color("74372a"), Color("a0553a"), Color("c87c52")]
const CLOTH_GREEN := [Color("1d3324"), Color("2c4d34"), Color("3e6b42"), Color("5a8f52"), Color("86b86a")]
const CLOTH_BLUE := [Color("1a2240"), Color("26365e"), Color("355086"), Color("4f74b0"), Color("7ea2d4")]
const CLOTH_OCHRE := [Color("4a3014"), Color("7a521c"), Color("b07e28"), Color("dcac3c"), Color("f6d677")]
const CLOTH_DARK := [Color("141018"), Color("221c2a"), Color("332b3e"), Color("4a4058"), Color("685c78")]
const CLOTH_PLUM := [Color("26152a"), Color("3b2140"), Color("55305a"), Color("744878"), Color("9a6a9a")]
const HAIR_DARK := [Color("1d1420"), Color("332433"), Color("4d3548"), Color("6b4c62")]
const NIGHT := Color("2c3a78")

## Signature element ramps. Index 2 is the signature hue; 3-4 are glow tones.
## Families follow WindfallTypes.Family order.
const ELEMENT := {
	0: [Color("2a1a5e"), Color("4b2fa8"), Color("8a6cff"), Color("b9a4ff"), Color("eee6ff")],  # STORM  electric violet
	1: [Color("5a160e"), Color("a8301a"), Color("ff5a24"), Color("ff9a3c"), Color("ffe08a")],  # EMBER  orange-red
	2: [Color("1c4a66"), Color("2f8cb0"), Color("62dcf2"), Color("a8f2ff"), Color("f0feff")],  # FROST  ice cyan
	3: [Color("0c1a4a"), Color("15357e"), Color("2464d6"), Color("4f96f0"), Color("a8d4ff")],  # TIDE   deep blue
	4: [Color("10391c"), Color("1f6e2c"), Color("3cc046"), Color("8ae65c"), Color("dcffb0")],  # VERDANT leaf green
	5: [Color("2f5a4c"), Color("5fa58a"), Color("a6f0c8"), Color("d4ffe6"), Color("ffffff")],  # GALE   pale mint
	6: [Color("2a0f2a"), Color("5a1f4e"), Color("b0457e"), Color("e07aac"), Color("ffc4e0")],  # UMBRA  twilight plum
	7: [Color("6e4a10"), Color("c49020"), Color("ffd94a"), Color("fff09a"), Color("fffdf0")],  # LUMEN  gold-white
}

## Leaf ramps per family so a tree's element reads before the fruit is visible.
const FAMILY_LEAF := {
	0: [Color("15283a"), Color("234a52"), Color("356a6a"), Color("4f8c7e"), Color("8ab8a4"), Color("b9a4ff")],
	1: [Color("2a1e14"), Color("4a3a1c"), Color("6e5a26"), Color("94782e"), Color("c4a040"), Color("ff9a3c")],
	2: [Color("16323a"), Color("245458"), Color("3c7c78"), Color("62a69a"), Color("a2d8cc"), Color("e8fffa")],
	3: [Color("0f2a2e"), Color("1a4646"), Color("26665e"), Color("3a8a76"), Color("6cb49a"), Color("a8d4ff")],
	4: [Color("163a2a"), Color("24573a"), Color("357a42"), Color("4f9e48"), Color("7cc35a"), Color("b4e07a")],
	5: [Color("26403a"), Color("3a6458"), Color("5a8c74"), Color("80b496"), Color("b4dcc0"), Color("eafff2")],
	6: [Color("1c1626"), Color("2e2238"), Color("44344c"), Color("5e4a62"), Color("80687e"), Color("e07aac")],
	7: [Color("2a3418"), Color("465622"), Color("6a7c2e"), Color("94a03a"), Color("c8c45a"), Color("fff09a")],
}

## Soil affinity ramps (WindfallTypes.SoilType order).
const SOIL_TYPES := {
	0: [Color("2b1c19"), Color("3f2a22"), Color("5a3c2c"), Color("77513a"), Color("94694a")],  # LOAM   rich brown
	1: [Color("1c1a1c"), Color("2e2a2c"), Color("48403c"), Color("6a5e56"), Color("ff7a3c")],  # ASH    charcoal + ember flecks
	2: [Color("2e3e52"), Color("4a6680"), Color("7c9cb8"), Color("b4d0e4"), Color("eef8ff")],  # RIME   frosted blue-white
	3: [Color("2a2a20"), Color("45422e"), Color("66603e"), Color("8a8456"), Color("4f96f0")],  # SILT   river olive + damp
	4: [Color("1e1830"), Color("33284e"), Color("4e3e74"), Color("6e5ca0"), Color("b9a4ff")],  # STORMGLASS violet glassy
	5: [Color("3a2e18"), Color("5c4a24"), Color("85703a"), Color("ad9856"), Color("fff09a")],  # LEY    golden runic
}


static func ramp(r: Array, t: float) -> Color:
	var i := clampi(int(round(t * (r.size() - 1))), 0, r.size() - 1)
	return r[i]


static func element(fam: int, idx: int = 2) -> Color:
	var r: Array = ELEMENT.get(fam, ELEMENT[4])
	return r[clampi(idx, 0, r.size() - 1)]
