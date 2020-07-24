package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.nape.FlxNapeSpace;
import flixel.util.FlxSpriteUtil;
import nape.geom.AABB;
import objects.Cargo;
import objects.Ship;
import physics.Terrain;

class TerrainDebug extends BackableState {
	var ship:Ship;
	var bg:FlxSprite;

	override public function create() {
		super.create();
		createTestObjs();
	}

	function createTestObjs() {
		ship = new Ship(200, 300);
		add(ship);

		bg = new FlxSprite(0, 0, AssetPaths.terrainDebug__png);
		add(bg);
		FlxG.bitmap.add(AssetPaths.terrainDebug__png, true, "terrainTest");
		var gfx = FlxG.bitmap.get("terrainTest");

		var terrain = new Terrain(gfx.bitmap, bg, 30, 5);
		terrain.invalidate(new AABB(0, 0, gfx.width, gfx.height), FlxNapeSpace.space);

		add(Cargo.create(AssetPaths.debug_square_red__png, 320, 100, 15));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
