package states;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import objects.Cargo;
import objects.Ship;
import objects.SwitchWall;
import objects.Towable;
import objects.Wall;

class LowPower extends BackableState {
	var ship:Ship;

	override public function create() {
		super.create();
		camera.zoom = 0.5;
		createWallsForCam(camera);

		createTestObjs();
	}

	function createWallsForCam(cam:FlxCamera) {
		var center = new FlxPoint(cam.x + FlxG.width / 2, cam.y + FlxG.height / 2);
		var halfWidth = FlxG.width / 2;
		var halfHeight = FlxG.height / 2;
		FlxNapeSpace.createWalls(center.x
			- (halfWidth / camera.zoom), center.y
			- (halfHeight / camera.zoom), center.x
			+ (halfWidth / camera.zoom),
			center.y
			+ (halfHeight / camera.zoom));
	}

	function createTestObjs() {
		ship = new Ship(cast(FlxG.width / 2, Int), FlxG.height - 50);
		add(ship);

		ship.enginePower.setxy(0, -150);

		var knobRadius = 10;

		var tow1 = new Towable();
		tow1.loadGraphic(AssetPaths.shot__png);
		tow1.scale.set(knobRadius * 2 / 32, knobRadius * 2 / 32);
		tow1.createCircularBody(knobRadius);
		tow1.body.userData.data = tow1;
		tow1.body.position.setxy(100, FlxG.height);
		tow1.body.type = BodyType.STATIC;
		tow1.set();
		add(tow1);

		var tow2 = new Towable();
		tow2.loadGraphic(AssetPaths.shot__png);
		tow2.scale.set(knobRadius * 2 / 32, knobRadius * 2 / 32);
		tow2.createCircularBody(knobRadius);
		tow2.body.userData.data = tow2;
		tow2.body.position.setxy(500, 100);
		tow2.body.type = BodyType.STATIC;
		tow2.set();
		add(tow2);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
