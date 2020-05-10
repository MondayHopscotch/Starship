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

class InteractableEnvironment extends BackableState {
	var ship:Ship;

	override public function create() {
		super.create();
		FlxNapeSpace.createWalls(0, 0, 0, 0);

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

		add(Cargo.create(AssetPaths.debug_square_red__png, 20, FlxG.height - 5, 10));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
