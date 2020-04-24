package;

import constants.CbTypes;
import constants.CollisionGroups;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import input.BasicControls;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.callbacks.Listener;
import nape.callbacks.OptionType;
import nape.constraint.DistanceJoint;
import nape.constraint.LineJoint;
import nape.constraint.PulleyJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.geom.RayResultList;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.MassMode;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import openfl.display.FPS;

class PlayState extends FlxState {
	static inline var MIN_TOW_DISTANCE:Float = 10;
	static inline var MAX_TOW_DISTANCE:Float = 200;
	static inline var RADIANS_PER_DEGREE:Float = 0.0174533;

	var controls:BasicControls;

	var ship:FlxNapeSprite;

	var validCargoTargets:Array<FlxNapeSprite> = [];

	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, 200);
	var enginePower:Vec2 = Vec2.get().setxy(500, 0);

	// Units: Pixels/sec
	var grappleRate:Float = 50;

	// Units: Rads/sec
	var TURN_POWER:Float = 4;

	var jointed:Bool = false;
	var joint:DistanceJoint = null;

	override public function create() {
		super.create();

		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);
		FlxNapeSpace.space.gravity.set(gravity);

		createTestObjs();
		setupControls();
	}

	function createTestObjs() {
		createShip();

		createCargo(AssetPaths.debug_square_red__png, 50, FlxG.height - 50, 20);
		createCargo(AssetPaths.debug_square_blue__png, FlxG.width - 50, FlxG.height - 50, 10);

		createBucket(AssetPaths.debug_square_blue__png, 50, FlxG.height - 50, 50, 50);
		createBucket(AssetPaths.debug_square_red__png, FlxG.width - 50, FlxG.height - 50, 50, 50);
	}

	function createShip() {
		ship = new FlxNapeSprite();
		ship.setPosition(300, 300);
		ship.loadGraphic(AssetPaths.shot__png);
		var body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Polygon(Polygon.regular(40, 20, 3)));
		var shipFilter = new InteractionFilter(CollisionGroups.SHIP, ~(CollisionGroups.CARGO));
		body.setShapeFilters(shipFilter);

		var weightless = new Material(0, 1, 2, 0.00000001);
		var sensor = new Circle(MAX_TOW_DISTANCE);
		sensor.sensorEnabled = true;
		sensor.cbTypes.add(CbTypes.CB_SHIP_SENSOR_RANGE);
		sensor.body = body;

		ship.addPremadeBody(body);
		ship.body.shapes.foreach(s -> s.sensorEnabled ? s.material = weightless : s.material = s.material);
		ship.body.rotation = -Math.PI / 2;
		add(ship);

		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_CARGO,
			cargoEnterRangeCallback));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_CARGO,
			cargoExitRangeCallback));
	}

	function createCargo(spriteName:FlxGraphicAsset, x:Int, y:Int, size:Float) {
		var cargo = new FlxNapeSprite();
		cargo.loadGraphic(spriteName);
		cargo.setPosition(x, y);
		cargo.scale.set(size / 3, size / 3);

		var cargoBody = new Body(BodyType.DYNAMIC);
		cargoBody.shapes.add(new Polygon(Polygon.rect(-size / 2, -size / 2, size, size)));
		cargoBody.mass *= 5;
		cargoBody.userData.data = cargo;
		cargoBody.cbTypes.add(CbTypes.CB_CARGO);

		var cargoFilter = new InteractionFilter(CollisionGroups.CARGO, ~(CollisionGroups.SHIP));
		cargoBody.setShapeFilters(cargoFilter);

		cargo.addPremadeBody(cargoBody);
		add(cargo);
	}

	function tetherCargo(cargo:FlxNapeSprite) {
		if (joint == null) {
			joint = new DistanceJoint(ship.body, cargo.body, Vec2.weak(0, 0), Vec2.weak().setxy(0, 0), MIN_TOW_DISTANCE, MAX_TOW_DISTANCE);
			joint.stiff = false;
			joint.frequency = 20;
			joint.damping = 4;
			joint.space = FlxNapeSpace.space;
			joint.breakUnderError = true;
			joint.active = false;
		} else {
			joint.body2 = cargo.body;
			joint.active = true;
			jointed = true;

			joint.jointMax = MAX_TOW_DISTANCE;

			var ray = Ray.fromSegment(new Vec2().setxy(ship.x, ship.y), new Vec2().setxy(cargo.x, cargo.y));
			var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.CARGO, CollisionGroups.CARGO));
			if (result != null) {
				joint.anchor2.set(ray.at(result.distance).sub(Vec2.weak().setxy(cargo.x, cargo.y)).rotate(-cargo.angle * RADIANS_PER_DEGREE));
			}
		}
	}

	function createBucket(spriteGfx:FlxGraphicAsset, x:Int, y:Int, width:Int, height:Int) {
		var wallThickness = 10;
		var left = new FlxNapeSprite();
		left.loadGraphic(spriteGfx);
		left.setPosition(x - width / 2 - wallThickness, y + height / 2);
		left.createRectangularBody(wallThickness, height);
		left.scale.set(wallThickness / 3, height / 3);
		left.body.type = BodyType.STATIC;
		add(left);

		var right = new FlxNapeSprite();
		right.loadGraphic(spriteGfx);
		right.setPosition(x + width / 2, y + height / 2);
		right.createRectangularBody(wallThickness, height);
		right.scale.set(wallThickness / 3, height / 3);
		right.body.type = BodyType.STATIC;
		add(right);

		var bottom = new FlxNapeSprite();
		bottom.loadGraphic(spriteGfx);
		bottom.setPosition(x, y + height);
		bottom.createRectangularBody(width, wallThickness);
		bottom.scale.set(width / 3, wallThickness / 3);
		bottom.body.type = BodyType.STATIC;
		add(bottom);
	}

	function setupControls() {
		controls = new BasicControls();
	}

	public function cargoEnterRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.push(cast(clbk.int2.userData.data, FlxNapeSprite));
	}

	public function cargoExitRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.remove(cast(clbk.int2.userData.data, FlxNapeSprite));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		ship.body.angularVel *= .95;
		if (Math.abs(ship.body.angularVel) < 0.1) {
			ship.body.angularVel = 0;
		}

		if (controls.thruster.x > 0.1) {
			FlxG.watch.addQuick("Thruster     : ", controls.thruster.x);
			ship.body.applyImpulse(Vec2.weak().set(enginePower).mul(elapsed).mul(controls.thruster.x).rotate(ship.body.rotation));
		}

		if (Math.abs(controls.steer.x) > 0.1) {
			FlxG.watch.addQuick("Steering     : ", controls.steer.x);
			ship.body.angularVel = TURN_POWER * Math.pow(controls.steer.x, 3);
		}
		FlxG.watch.addQuick("AngrlarVel     : ", ship.body.angularVel);
		FlxG.watch.addQuick("Net Force      : ", ship.body.totalImpulse());

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
				joint.body2 = null;
				jointed = false;
			} else {
				var shortestDist = Math.POSITIVE_INFINITY;
				var validTarget:FlxNapeSprite = null;
				for (c in validCargoTargets) {
					var cDist = c.getPosition().distanceTo(ship.getPosition());
					if (cDist < shortestDist) {
						shortestDist = cDist;
						validTarget = c;
					}
				}

				if (shortestDist != Math.POSITIVE_INFINITY) {
					tetherCargo(validTarget);
				}
			}
		}
	}
}
