package entities;

import constants.CbTypes;
import constants.CollisionGroups;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import input.BasicControls;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.constraint.DistanceJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import objects.Towable;

class Ship extends FlxNapeSprite {
	static inline var MIN_TOW_DISTANCE:Float = 10;
	static inline var MAX_TOW_DISTANCE:Float = 200;
	static inline var RADIANS_PER_DEGREE:Float = 0.0174533;

	var controls:BasicControls;
	var enginePower:Vec2 = Vec2.get().setxy(500, 0);

	var validCargoTargets:Array<Towable> = [];
	// Units: Pixels/sec
	var grappleRate:Float = 50;

	// Units: Rads/sec
	var TURN_POWER:Float = 4;

	var jointed:Bool = false;
	var joint:DistanceJoint = null;

	public function new(x:Int, y:Int) {
		super();
		setPosition(300, 300);
		loadGraphic(AssetPaths.shot__png);

		controls = new BasicControls();

		var body = new Body(BodyType.DYNAMIC);
		body.shapes.add(new Polygon(Polygon.regular(40, 20, 3)));

		var shipFilter = new InteractionFilter(CollisionGroups.SHIP, ~(CollisionGroups.CARGO));
		body.setShapeFilters(shipFilter);

		var weightless = new Material(0, 1, 2, 0.00000001);
		var sensor = new Circle(MAX_TOW_DISTANCE);
		sensor.sensorEnabled = true;
		sensor.cbTypes.add(CbTypes.CB_SHIP_SENSOR_RANGE);
		sensor.body = body;

		addPremadeBody(body);
		body.shapes.foreach(s -> s.sensorEnabled ? s.material = weightless : s.material = s.material);
		body.rotation = -Math.PI / 2;

		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_CARGO,
			cargoEnterRangeCallback));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_CARGO,
			cargoExitRangeCallback));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		body.angularVel *= .95;
		if (Math.abs(body.angularVel) < 0.1) {
			body.angularVel = 0;
		}

		if (controls.thruster.x > 0.1) {
			FlxG.watch.addQuick("Thruster     : ", controls.thruster.x);
			body.applyImpulse(Vec2.weak().set(enginePower).mul(elapsed).mul(controls.thruster.x).rotate(body.rotation));
		}

		if (Math.abs(controls.steer.x) > 0.1) {
			FlxG.watch.addQuick("Steering     : ", controls.steer.x);
			body.angularVel = TURN_POWER * Math.pow(controls.steer.x, 3);
		}
		// FlxG.watch.addQuick("AngrlarVel     : ", body.angularVel);
		// FlxG.watch.addQuick("Net Force      : ", body.totalImpulse());

		if (Math.abs(controls.grappleAdjust.y) > 0.1) {
			// FlxG.watch.addQuick("GrappleAdjust: ", controls.grappleAdjust.y);
			if (jointed) {
				joint.jointMax += grappleRate * elapsed * controls.grappleAdjust.y;
				joint.jointMax = Math.max(MIN_TOW_DISTANCE, joint.jointMax);
				// FlxG.watch.addQuick("Tow Length    : ", joint.jointMax);
			}
		}

		if (jointed && !joint.active) {
			// body has been destroyed
			joint.active = false;
			joint.body2 = null;
			jointed = false;
		}

		if (controls.toggleGrapple.check()) {
			if (jointed) {
				joint.active = false;
				cast(joint.body2.userData.data, Towable).outOfTow();
				joint.body2 = null;
				jointed = false;
			} else {
				var shortestDist = Math.POSITIVE_INFINITY;
				var validTarget:Towable = null;
				for (c in validCargoTargets) {
					var cDist = c.getPosition().distanceTo(getPosition());
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

	function tetherCargo(cargo:Towable) {
		if (joint == null) {
			joint = new DistanceJoint(body, cargo.body, Vec2.weak(0, 0), Vec2.weak().setxy(0, 0), MIN_TOW_DISTANCE, MAX_TOW_DISTANCE);
			joint.stiff = false;
			joint.frequency = 20;
			joint.damping = 4;
			joint.space = FlxNapeSpace.space;
			joint.breakUnderError = true;
			joint.active = false;
			cargo.inTow(joint);
		} else {
			joint.body2 = cargo.body;
			joint.active = true;
			jointed = true;

			joint.jointMax = MAX_TOW_DISTANCE;

			var ray = Ray.fromSegment(new Vec2().setxy(x, y), new Vec2().setxy(cargo.x, cargo.y));
			var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.CARGO, CollisionGroups.CARGO));
			if (result != null) {
				joint.anchor2.set(ray.at(result.distance).sub(Vec2.weak().setxy(cargo.x, cargo.y)).rotate(-cargo.angle * RADIANS_PER_DEGREE));
				cargo.inTow(joint);
			}
		}
	}

	public function cargoEnterRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.push(cast(clbk.int2.userData.data, Towable));
	}

	public function cargoExitRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.remove(cast(clbk.int2.userData.data, Towable));
	}
}
