package states;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.addons.ui.FlxSlider;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import objects.Cargo;
import objects.Ship;
import physics.Creators;
import test.UpdaterTest;

class CargoState extends BackableState {
	var ship:Ship;

	var weights:Vec2 = Vec2.get().setxy(0, 1);

	var cargos:Array<Cargo>;

	var gravSlider:FlxSlider;
	var weightSlider:FlxSlider;
	var thrustSlider:FlxSlider;
	var spinSlider:FlxSlider;

	override public function create() {
		super.create();
		FlxNapeSpace.createWalls(0, 0, 0, 0);

		UpdaterTest.init();
		createTestObjs();

		gravSlider = new FlxSlider(gravity, "y", 10, 10, 1, 2000, 300, 30, 3, 0xff555555, 0xff828282);
		gravSlider.nameLabel.text = "gravity";
		add(gravSlider);

		weightSlider = new FlxSlider(weights, "y", 10, 80, .01, 1, 300, 30, 3, 0xff555555, 0xff828282);
		weightSlider.nameLabel.text = "cargo weight";
		add(weightSlider);

		thrustSlider = new FlxSlider(ship.enginePower, "x", 10, 150, 1, 1000, 300, 30, 3, 0xff555555, 0xff828282);
		thrustSlider.nameLabel.text = "ship power";
		add(thrustSlider);

		spinSlider = new FlxSlider(ship, "TURN_POWER", 10, 220, .01, 10, 300, 30, 3, 0xff555555, 0xff828282);
		spinSlider.nameLabel.text = "steering";
		add(spinSlider);
	}

	function createTestObjs() {
		ship = new Ship(300, 300);
		add(ship);

		cargos = new Array();

		var x = 30;
		var size = 10;
		for (i in 0...11) {
			var c = Cargo.create(AssetPaths.debug_square_red__png, x, FlxG.height - 50, size, 1);
			cargos.push(c);
			add(c);
			x += (i + 1) * 10;
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

		FlxNapeSpace.space.gravity.set(gravity);
		for (c in cargos) {
			c.body.shapes.at(0).material.density = weights.y;
		}

		if (FlxG.keys.justPressed.SPACE) {
			trace("Gravity: " + gravSlider.value);
			trace("Weight : " + weightSlider.value);
			trace("Thrust : " + thrustSlider.value);
			trace("Turning: " + spinSlider.value);
		}
	}
}
