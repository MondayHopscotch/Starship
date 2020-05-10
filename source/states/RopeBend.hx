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
import objects.SwitchWall;
import objects.Wall;
import physics.Creators;

class RopeBend extends BackableState {
	var ship:Ship;

	override public function create() {
		super.create();
		FlxNapeSpace.createWalls(0, 0, 0, 0);

		createTestObjs();
	}

	function createTestObjs() {
		ship = new Ship(300, FlxG.height - 30);
		add(ship);

		add(Creators.makeBlock(500, 400, 30, 200));
		add(Creators.makeBlock(520, 200, 200, 30));
		add(Creators.makeBlock(220, 200, 20, 20));
		add(Creators.makeBlock(210, 210, 20, 20));
		add(Creators.makeBlock(200, 220, 15, 15));
		add(Creators.makeBlock(300, 300, 40, 40));

		add(Cargo.create(AssetPaths.debug_square_red__png, 5, FlxG.height - 5, 10));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
