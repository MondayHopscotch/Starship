package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import input.BasicControls;
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
	static inline var MIN_TOW_DISTANCE:Float = 10;

	var controls:BasicControls;

	private static inline var TERRAIN_GROUP:Int = 1;
	private static inline var SHIP_GROUP:Int = 2;
	private static inline var CARGO_GROUP:Int = 4;

	var ship:FlxNapeSprite;
	var cargo:FlxNapeSprite;

	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, 200);
	var enginePower:Vec2 = Vec2.get().setxy(500, 0);

	// Units: Pixels/sec
	var grappleRate:Float = 50;

	// Units: Rads/sec
	var TURN_POWER:Float = 2;

	var jointed:Bool = false;
	var joint:DistanceJoint = null;

	override public function create() {
		super.create();

		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);
		FlxNapeSpace.space.gravity.set(gravity);

		createTestObjs();
		setupControls();
	}

	function createTestObjs() {
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
		cargo.setPosition(50, FlxG.height - 50);
		var cargoBody = new Body(BodyType.DYNAMIC);
		cargoBody.shapes.add(new Polygon(Polygon.rect(-5, -5, 10, 10)));
		cargoBody.mass *= 5;

		var cargoFilter = new InteractionFilter(CARGO_GROUP, ~(SHIP_GROUP));
		cargoBody.setShapeFilters(cargoFilter);

		cargo.addPremadeBody(cargoBody);
		add(cargo);

		joint = new DistanceJoint(ship.body, cargo.body, Vec2.weak(0, 0), Vec2.weak().setxy(0, 0), MIN_TOW_DISTANCE, 100);
		joint.stiff = false;
		joint.frequency = 20;
		joint.damping = 4;
		joint.space = FlxNapeSpace.space;
		joint.breakUnderError = true;
		joint.active = false;

		createBucket(50, FlxG.height - 50, 50, 50);
		createBucket(FlxG.width - 50, FlxG.height - 50, 50, 50);
	}

	function createBucket(x:Int, y:Int, width:Int, height:Int) {
		var wallThickness = 10;
		var left = new FlxNapeSprite();
		left.setPosition(x - width / 2 - wallThickness, y + height / 2);
		left.createRectangularBody(wallThickness, height);
		left.body.type = BodyType.STATIC;
		add(left);

		var right = new FlxNapeSprite();
		right.setPosition(x + width / 2, y + height / 2);
		right.createRectangularBody(wallThickness, height);
		right.body.type = BodyType.STATIC;
		add(right);

		var bottom = new FlxNapeSprite();
		bottom.setPosition(x, y + height);
		bottom.createRectangularBody(width, wallThickness);
		bottom.body.type = BodyType.STATIC;
		add(bottom);
	}

	function setupControls() {
		controls = new BasicControls();
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		ship.body.angularVel *= .95;

		if (controls.thruster.x > 0.1) {
			FlxG.watch.addQuick("Thruster     : ", controls.thruster.x);
			ship.body.applyImpulse(Vec2.weak().set(enginePower).mul(elapsed).mul(controls.thruster.x).rotate(ship.body.rotation));
		}

		if (Math.abs(controls.steer.x) > 0.1) {
			FlxG.watch.addQuick("Steering     : ", controls.steer.x);
			// ship.body.applyAngularImpulse(TURN_POWER * controls.steer.x);
			ship.body.angularVel = TURN_POWER * controls.steer.x;
		}

		if (Math.abs(controls.grappleAdjust.y) > 0.1) {
			FlxG.watch.addQuick("GrappleAdjust: ", controls.grappleAdjust.y);
			if (jointed) {
				joint.jointMax += grappleRate * elapsed * controls.grappleAdjust.y;
				joint.jointMax = Math.max(MIN_TOW_DISTANCE, joint.jointMax);
				FlxG.watch.addQuick("Tow Length    : ", joint.jointMax);
			}
		}

		if (controls.toggleGrapple.check()) {
			if (jointed) {
				joint.active = false;
				jointed = false;
			} else {
				joint.jointMax = Vec2.distance(ship.body.position, cargo.body.position);
				joint.active = true;
				jointed = true;
			}
		}
	}
}
