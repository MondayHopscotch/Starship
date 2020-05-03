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
import objects.Cargo;
import objects.Ship;
import physics.Creators;

class CargoState extends BackableState {
	var ship:Ship;

	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, 200);

	override public function create() {
		super.create();
		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);
		FlxNapeSpace.space.gravity.set(gravity);

		createTestObjs();
	}

	function createTestObjs() {
		ship = new Ship(300, 300);
		add(ship);

		var x = 50;
		var size = 10;
		for (i in 0...10) {
			add(Cargo.create(AssetPaths.debug_square_red__png, x, FlxG.height - 50, size, 1));
			x += 50;
			size += 5;
		}
		// var light = Cargo.create(AssetPaths.debug_square_red__png, 50, FlxG.height - 50, 15);
		// add(light);
		// add(Cargo.create(AssetPaths.debug_square_blue__png, FlxG.width - 50, FlxG.height - 50, 10));

		// for (b in Creators.createBucket(AssetPaths.debug_square_blue__png, 50, FlxG.height - 50, 50, 50)) {
		// 	add(b);
		// }
		// for (b in Creators.createBucket(AssetPaths.debug_square_red__png, FlxG.width - 50, FlxG.height - 50, 50, 50)) {
		// 	add(b);
		// }
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
