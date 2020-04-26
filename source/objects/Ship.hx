package objects;

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
import nape.constraint.PulleyJoint;
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

	public var enginePower:Vec2 = Vec2.get().setxy(500, 0);

	var validCargoTargets:Array<Towable> = [];
	// Units: Pixels/sec
	var grappleRate:Float = 50;

	// Units: Rads/sec
	var TURN_POWER:Float = 4;

	var jointed:Bool = false;
	var joint:DistanceJoint = null;
	var pullied:Bool = false;
	var pulley:PulleyJoint = null;

	public function new(x:Int, y:Int) {
		super();
		setPosition(x, y);
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
			// FlxG.watch.addQuick("Thruster     : ", controls.thruster.x);
			body.applyImpulse(Vec2.weak().set(enginePower).mul(elapsed).mul(controls.thruster.x).rotate(body.rotation));
		}

		if (Math.abs(controls.steer.x) > 0.1) {
			// FlxG.watch.addQuick("Steering     : ", controls.steer.x);
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

		if (jointed) {
			if (!joint.active) {
				// body has been destroyed
				joint.active = false;
				joint.body2 = null;
				jointed = false;
			} else {
				updateRope();
			}
		}

		if (controls.toggleGrapple.check()) {
			FlxG.log.notice("Tow toggled");
			if (jointed) {
				joint.active = false;
				cast(joint.body2.userData.data, Towable).outOfTow();
				joint.body2 = null;
				jointed = false;
			} else {
				validCargoTargets.sort((t1,
						t2) -> return Math.floor(Math.abs(Vec2.distance(this.body.position,
						t2.body.position) - Vec2.distance(this.body.position, t1.body.position))));
				for (c in validCargoTargets) {
					if (tetherCargo(c)) {
						return;
					}
				}
				FlxG.log.notice("no tow in range");
			}
		}
	}

	function tetherCargo(cargo:Towable):Bool {
		if (joint == null) {
			joint = new DistanceJoint(body, cargo.body, Vec2.weak(0, 0), Vec2.weak().setxy(0, 0), MIN_TOW_DISTANCE, MAX_TOW_DISTANCE);
			joint.stiff = false;
			joint.frequency = 20;
			joint.damping = 4;
			joint.space = FlxNapeSpace.space;
			joint.breakUnderError = true;
			joint.active = false;
		}
		var ray = Ray.fromSegment(Vec2.get().set(body.position), Vec2.get().set(cargo.body.position));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.ALL, CollisionGroups.ALL));

		if (result == null) {
			FlxG.log.notice("no valid tow result");
			return false;
		} else if (!Std.is(result.shape.body.userData.data, Towable)) {
			FlxG.log.notice("nearest target is type: " + Type.typeof(result.shape.body.userData.data));
			return false;
		} else {
			jointed = true;
			joint.active = true;
			joint.body2 = cargo.body;
			joint.jointMax = MAX_TOW_DISTANCE;
			joint.anchor2.set(ray.at(result.distance).sub(Vec2.weak().set(cargo.body.position)).rotate(-cargo.body.rotation));
			cargo.inTow(joint);
			return true;
		}
	}

	public function updateRope() {
		if (pulley == null) {
			pulley = new PulleyJoint(this.body, this.body, this.body, this.body, Vec2.weak(), Vec2.weak(), Vec2.weak(), Vec2.weak(), MIN_TOW_DISTANCE,
				MAX_TOW_DISTANCE, 1);
			pulley.active = false;
			pulley.space = FlxNapeSpace.space;
		}

		var ray = Ray.fromSegment(Vec2.get().set(body.position), Vec2.get().set(joint.body2.position));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.TERRAIN, CollisionGroups.TERRAIN));

		if (pullied && !isPulleyClear()) {
			return;
		}

		if (result != null) {
			FlxG.watch.addQuick("Rope contact: ", true);
		} else {
			FlxG.watch.addQuick("Rope contact: ", false);
		}

		if (result == null && pullied) {
			FlxG.log.notice("removing pulley");
			pullied = false;
			pulley.active = false;
			return;
		} else if (result != null && !pullied) {
			FlxG.log.notice("attaching pulley");
			pullied = true;
			pulley.active = true;
			pulley.body1 = body;
			pulley.body2 = result.shape.body;
			pulley.body3 = result.shape.body;
			pulley.body4 = joint.body2;

			pulley.anchor1 = joint.anchor1;
			// pulley.anchor2 = ray.at(result.distance).sub(Vec2.weak().set(result.shape.body.position)).rotate(-result.shape.body.rotation);
			pulley.anchor2 = getLocalPointOnBody(result.shape.body, ray.at(result.distance));
			// pulley.anchor3 = ray.at(result.distance).sub(Vec2.weak().set(result.shape.body.position)).rotate(-result.shape.body.rotation);
			pulley.anchor3 = getLocalPointOnBody(result.shape.body, ray.at(result.distance));
			pulley.anchor4 = joint.anchor2;
		}
	}

	function getLocalPointOnBody(b:Body, worldPoint:Vec2):Vec2 {
		return worldPoint.copy().sub(Vec2.weak().set(b.position)).rotate(-b.rotation);
	}

	function getWorldPointFromBody(b:Body, localPoint:Vec2):Vec2 {
		return localPoint.copy().rotate(b.rotation).add(b.position);
	}

	function isPulleyClear():Bool {
		// return true;
		var final1 = checkPulleyContact(joint.body1, joint.anchor1, pulley.body2, pulley.anchor2);
		var final2 = checkPulleyContact(joint.body2, joint.anchor2, pulley.body3, pulley.anchor3);
		FlxG.watch.addQuick("Ship-pulley clear: ", final1);
		FlxG.watch.addQuick("Cargo-pulley clear: ", final2);
		return final1 && final2;
	}

	function checkPulleyContact(body:Body, bodyAnchor:Vec2, pullyBody:Body, pulleyAchor:Vec2):Bool {
		var ray = Ray.fromSegment(getWorldPointFromBody(joint.body1, joint.anchor1), getWorldPointFromBody(pulley.body2, pulley.anchor2));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.TERRAIN, CollisionGroups.TERRAIN));
		return result == null || (result.distance / ray.maxDistance) > 0.95;
	}

	public function cargoEnterRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.push(cast(clbk.int2.userData.data, Towable));
	}

	public function cargoExitRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.remove(cast(clbk.int2.userData.data, Towable));
	}
}
