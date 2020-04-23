package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.text.FlxText;
import nape.constraint.DistanceJoint;
import nape.constraint.LineJoint;
import nape.constraint.PulleyJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.MassMode;
import nape.phys.Material;
import nape.shape.Polygon;
import openfl.display.FPS;

class PlayState extends FlxState {
	var fps:FPS;

	private static inline var TERRAIN_GROUP:Int = 1;
	private static inline var SHIP_GROUP:Int = 2;
	private static inline var CARGO_GROUP:Int = 4;

	var gravity:Vec2 = Vec2.get().setxy(0, 200);

	var ship:FlxNapeSprite;
	var cargo:FlxNapeSprite;

	// Units: Pixels/sec/sec
	var enginePower:Vec2 = Vec2.get().setxy(10, 0);

	// Units: Rads/sec
	var TURN_POWER:Float = 40;

	var jointed:Bool = false;
	var joint:DistanceJoint = null;

	override public function create() {
		super.create();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;

		FlxNapeSpace.createWalls(0, 0, 0, 0);

		createTestObj();
		FlxNapeSpace.space.gravity.set(gravity);
	}

	function createTestObj() {
		ship = new FlxNapeSprite();
		ship.setPosition(300, 300);
		ship.loadGraphic(AssetPaths.shot__png);
		var body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Polygon(Polygon.regular(40, 20, 3)));
		var shipFilter = new InteractionFilter(SHIP_GROUP, ~(CARGO_GROUP));
		body.setShapeFilters(shipFilter);

		ship.addPremadeBody(body);
		ship.body.rotation = -Math.PI / 2;
		add(ship);

		cargo = new FlxNapeSprite();
		cargo.setPosition(300, 330);
		var cargoBody = new Body(BodyType.DYNAMIC);
		cargoBody.shapes.add(new Polygon(Polygon.rect(-5, -5, 10, 10)));
		cargoBody.gravMassScale = 5;

		var cargoFilter = new InteractionFilter(CARGO_GROUP, ~(SHIP_GROUP));
		cargoBody.setShapeFilters(cargoFilter);

		cargo.addPremadeBody(cargoBody);
		add(cargo);

		joint = new DistanceJoint(ship.body, cargo.body, Vec2.weak(0, 0), Vec2.weak().setxy(0, 0), 0, 100);
		joint.stiff = false;
		joint.frequency = 20;
		joint.damping = 1;
		joint.space = FlxNapeSpace.space;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		ship.body.angularVel *= .95;

		if (FlxG.keys.pressed.A) {
			ship.body.applyAngularImpulse(-TURN_POWER);
		}

		if (FlxG.keys.pressed.D) {
			ship.body.applyAngularImpulse(TURN_POWER);
		}

		if (FlxG.mouse.justPressed) {
			if (jointed) {
				joint.active = false;
				jointed = false;
			} else {
				joint.jointMax = Vec2.distance(ship.body.position, cargo.body.position);
				joint.active = true;
				jointed = true;
			}
		}

		if (FlxG.keys.pressed.SPACE) {
			ship.body.applyImpulse(Vec2.weak().set(enginePower).rotate(ship.body.rotation));
			// ship.body.applyImpulse(Vec2.weak().set(enginePower).rotate(-Math.PI / 2));
		}
	}
}
