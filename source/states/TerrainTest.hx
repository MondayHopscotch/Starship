package states;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.nape.FlxNapeSpace;
import nape.geom.AABB;
import objects.Cargo;
import objects.Ship;
import physics.Terrain;

class TerrainTest extends BackableState {
	var ship:Ship;
	var cam:FlxCamera;
	var bg:FlxSprite;

	override public function create() {
		super.create();
		createTestObjs();

		cam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		cam.setScrollBoundsRect(0, 0, bg.width, bg.height);

		FlxG.cameras.reset(cam);
		cam.target = ship.shipBody;
	}

	function createTestObjs() {
		ship = new Ship(200, 300);
		add(ship);

		bg = new FlxSprite(0, 0, AssetPaths.testLevel__png);
		add(bg);
		FlxG.bitmap.add(AssetPaths.testLevel__png, true, "terrainTest");
		var gfx = FlxG.bitmap.get("terrainTest");

		var terrain = new Terrain(gfx.bitmap, 30, 5);
		terrain.invalidate(new AABB(0, 0, gfx.width, gfx.height), FlxNapeSpace.space);

		add(Cargo.create(AssetPaths.debug_square_red__png, 320, 100, 15));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
