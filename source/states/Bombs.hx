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
import objects.Cargo;
import objects.DestructibleWall;
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
	}

	function createTestObjs() {
		ship = new Ship(200, 300, 100);
		add(ship);

		var bomb = Bomb.create(50, 50, 8);
		add(bomb);

		for (b in Creators.createBucket(AssetPaths.debug_square_yellow__png, 50, 350, 100, 30, true)) {
			add(b);
		}

		add(DestructibleWall.create(AssetPaths.debug_square_red__png, 550, 400, 300, 10));
		add(Creators.makeBlock(250, 75, 10, 400));
		add(Creators.makeBlock(400, 400, 10, 400));

		add(Cargo.create(AssetPaths.debug_square_blue__png, 550, 450, 10));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
