package states;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import objects.Bomb;
import objects.Ship;
import physics.Creators;

class Bombs extends BackableState {
	var ship:Ship;

	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, 200);

	override public function create() {
		super.create();
		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		var walls = FlxNapeSpace.createWalls(0, 0, 0, 0);
		walls.cbTypes.add(CbTypes.CB_TERRAIN);
		FlxNapeSpace.space.gravity.set(gravity);

		createTestObjs();
		for (b in Creators.createBucket(AssetPaths.debug_square_yellow__png, 50, 350, 100, 30, true)) {
			add(b);
		}
	}

	function createTestObjs() {
		ship = new Ship(300, 300);
		add(ship);

		var bomb = Bomb.create(50, 50, 10);
		add(bomb);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
