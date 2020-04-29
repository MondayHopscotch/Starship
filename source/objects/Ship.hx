package objects;

import constants.CbTypes;
import constants.CollisionGroups;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.group.FlxGroup;
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
import nape.geom.Vec2List;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.EdgeList;
import nape.shape.Polygon;
import objects.Towable;

using extensions.BodyExt;

class Ship extends FlxGroup {
	static inline var MIN_TOW_DISTANCE:Float = 10;
	static inline var MAX_TOW_DISTANCE:Float = 200;
	static inline var RADIANS_PER_DEGREE:Float = 0.0174533;

	var controls:BasicControls;

	public var enginePower:Vec2 = Vec2.get().setxy(500, 0);

	var validCargoTargets:Array<Towable> = [];

	// Units: Rads/sec
	var TURN_POWER:Float = 4;

	var rope:Rope;

	var shipBody:ShipBody;
	var sensor:ShipSensor;

	public function new(x:Int, y:Int) {
		super();

		controls = new BasicControls();
		rope = new Rope();

		shipBody = new ShipBody(x, y);
		add(shipBody);
		sensor = new ShipSensor(MAX_TOW_DISTANCE, shipBody);
		add(sensor);

		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_CARGO,
			cargoEnterRangeCallback));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_CARGO,
			cargoExitRangeCallback));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.mouse.justPressedRight) {
			trace(Vec2.get(FlxG.mouse.x, FlxG.mouse.y));
			trace(FlxNapeSpace.space.bodiesUnderPoint(Vec2.get(FlxG.mouse.x, FlxG.mouse.y), null));
		}

		shipBody.body.angularVel *= .95;
		if (Math.abs(shipBody.body.angularVel) < 0.1) {
			shipBody.body.angularVel = 0;
		}

		if (controls.thruster.x > 0.1) {
			// FlxG.watch.addQuick("Thruster     : ", controls.thruster.x);
			shipBody.body.applyImpulse(Vec2.weak()
				.set(enginePower)
				.mul(elapsed)
				.mul(controls.thruster.x)
				.rotate(shipBody.body.rotation));
		}

		if (Math.abs(controls.steer.x) > 0.1) {
			// FlxG.watch.addQuick("Steering     : ", controls.steer.x);
			shipBody.body.angularVel = TURN_POWER * Math.pow(controls.steer.x, 3);
		}

		rope.update(elapsed);

		if (controls.toggleGrapple.check()) {
			FlxG.log.notice("Tow toggled @ " + elapsed);
			if (rope.isAttached()) {
				rope.detach();
			} else {
				validCargoTargets.sort((t1,
						t2) -> return Math.floor(Math.abs(Vec2.distance(shipBody.body.position, t2.body.position)
						- Vec2.distance(shipBody.body.position, t1.body.position))));
				for (c in validCargoTargets) {
					trace("grabbing at " + c + ": " + tetherCargo(c));
				}
				FlxG.log.notice("no tow in range");
			}
		}
	}

	public function tetherCargo(cargo:Towable):Bool {
		var ray = Ray.fromSegment(Vec2.get().set(shipBody.body.position), Vec2.get().set(cargo.body.position));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.ALL, CollisionGroups.ALL));

		if (result == null) {
			trace("no valid tow ray result");
			return false;
		} else if (!Std.is(result.shape.body.userData.data, Towable)) {
			trace("nearest target is type: " + Type.typeof(result.shape.body.userData.data));
			return false;
		} else {
			rope.attach(shipBody, Vec2.get(), cargo, ray.at(result.distance).sub(Vec2.weak().set(cargo.body.position)).rotate(-cargo.body.rotation),
				MAX_TOW_DISTANCE);
			return true;
		}
	}

	public function cargoEnterRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.push(cast(clbk.int2.userData.data, Towable));
	}

	public function cargoExitRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.remove(cast(clbk.int2.userData.data, Towable));
	}
}
