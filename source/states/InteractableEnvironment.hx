package states;

import constants.CbTypes;
import constants.CollisionGroups;
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
import objects.SwitchWall;
import objects.Wall;

class InteractableEnvironment extends BackableState {
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

		var wall = new Wall(cast(FlxG.width * 0.75, Int));
		add(wall);

		// var lever = new SwitchWall(cast(FlxG.width / 4, Int), FlxG.height);
		var lever = new SwitchWall(200, FlxG.height, true);
		add(lever);

		add(Cargo.create(AssetPaths.debug_square_red__png, 5, FlxG.height - 5, 10));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
