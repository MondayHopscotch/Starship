package states;

import constants.CbTypes;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import nape.geom.Vec2;
import objects.Ship;
import objects.Wall;

class DestructableObjects extends BackableState {
	var ship:Ship;

	override public function create() {
		super.create();
		CbTypes.initTypes();
		FlxNapeSpace.createWalls(0, 0, 0, 0);

		createTestObjs();
	}

	function createTestObjs() {
		ship = new Ship(300, 300);
		add(ship);

		var wall = new Wall(cast(FlxG.width * 0.75, Int));
		add(wall);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
