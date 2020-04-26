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

class RopeBend extends FlxState {
	var ship:FlxNapeSprite;

	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, 200);

	override public function create() {
		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);
		FlxNapeSpace.space.gravity.set(gravity);

		createTestObjs();
	}

	function createTestObjs() {
		ship = new Ship(300, FlxG.height - 30);
		add(ship);

		var testBlock = new FlxNapeSprite();
		testBlock.loadGraphic(AssetPaths.debug_square_blue__png);
		testBlock.setPosition(500, 240);
		testBlock.createRectangularBody(200, 30);
		testBlock.scale.set(30 / 3, 30 / 3);
		testBlock.body.type = BodyType.STATIC;
		testBlock.body.setShapeFilters(new InteractionFilter(CollisionGroups.TERRAIN));
		add(testBlock);

		add(Cargo.create(AssetPaths.debug_square_red__png, 5, FlxG.height - 5, 10));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
