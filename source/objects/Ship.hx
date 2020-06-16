package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import geometry.ContactBundle;
import input.BasicControls;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.geom.Vec2;
import objects.Towable;

class Ship extends FlxGroup {
	var stats:ShipStats = CompileTime.parseJsonFile("assets/config/shipStats.json");

	public var enginePower:Vec2;
	// Units: Rads/sec
	public var TURN_POWER:Float;

	public var MIN_TOW_DISTANCE:Float = 10;
	public var MAX_TOW_DISTANCE:Float = 200;

	var controls:BasicControls;
	var validCargoTargets:Array<Towable> = [];

	var rope:Rope;
	var maxLength:Float;

	public var shipBody:ShipBody;

	var sensor:ShipSensor;

	var emitter:FlxEmitter;

	public function new(x:Int, y:Int) {
		super();

		enginePower = Vec2.get().setxy(0, -stats.thrust);
		TURN_POWER = stats.turning;
		MIN_TOW_DISTANCE = stats.minTowDistance;
		MAX_TOW_DISTANCE = stats.maxTowDistance;

		maxLength = MAX_TOW_DISTANCE;

		controls = new BasicControls();
		rope = new Rope();

		shipBody = new ShipBody(x, y);
		add(shipBody);
		sensor = new ShipSensor(maxLength, shipBody);
		add(sensor);

		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_TOWABLE,
			cargoEnterRangeCallback));
		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.END, InteractionType.SENSOR, CbTypes.CB_SHIP_SENSOR_RANGE, CbTypes.CB_TOWABLE,
			cargoExitRangeCallback));

		emitter = new FlxEmitter();
		emitter.launchMode = SQUARE;
		emitter.makeParticles(2, 2, FlxColor.GRAY);
		emitter.lifespan.min = 0.5;
		emitter.lifespan.max = 0.75;
		add(emitter);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		emitter.setPosition(shipBody.x + shipBody.boostPos().x, shipBody.y + shipBody.boostPos().y);

		if (FlxG.mouse.justPressedRight) {
			trace(Vec2.get(FlxG.mouse.x, FlxG.mouse.y));
			trace(FlxNapeSpace.space.bodiesUnderPoint(Vec2.get(FlxG.mouse.x, FlxG.mouse.y), null));
		}

		if (controls.thruster.x > 0.1) {
			// FlxG.watch.addQuick("Thruster     : ", controls.thruster.x);
			shipBody.body.applyImpulse(Vec2.weak()
				.set(enginePower)
				.mul(elapsed)
				.mul(controls.thruster.x)
				.rotate(shipBody.body.rotation));

			if (!emitter.exists) {
				emitter.start(false);
			} else {
				emitter.emitting = true;
			}

			var velo = Vec2.get(-100, 0, true);
			velo.rotate((shipBody.angle - 90) * FlxAngle.TO_RAD);
			emitter.velocity.set(velo.x, velo.y, velo.x, velo.y, 0, 0, 0, 0);
			velo.dispose();
		} else {
			emitter.emitting = false;
		}

		if (Math.abs(controls.steer.x) > 0.1) {
			// FlxG.watch.addQuick("Steering     : ", controls.steer.x);
			shipBody.body.angularVel *= .95;
			// if (Math.abs(shipBody.body.angularVel) < 0.1) {
			// 	shipBody.body.angularVel = 0;
			// }
			shipBody.body.angularVel = TURN_POWER * Math.pow(controls.steer.x, 3);
		} else {
			shipBody.body.angularVel = 0;
		}

		rope.update(elapsed);

		if (controls.toggleGrapple.check()) {
			FlxG.log.notice("Tow toggled @ " + elapsed);
			if (rope.isAttached()) {
				rope.detach();
			} else {
				validCargoTargets.sort((t1, t2) -> {
					return Math.floor(Vec2.distance(shipBody.body.position, t1.body.position) - Vec2.distance(shipBody.body.position, t2.body.position));
				});
				for (c in validCargoTargets) {
					if (tetherCargo(c)) {
						trace("grabbing at: " + c);
						break;
					}
				}
				FlxG.log.notice("no tow in range");
			}
		}
	}

	public function tetherCargo(cargo:Towable):Bool {
		var ray = Ray.fromSegment(Vec2.get().set(shipBody.body.position), Vec2.get().set(cargo.body.position));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CGroups.ALL, CGroups.ALL));

		if (result == null) {
			trace("no valid tow ray result");
			return false;
		} else if (!Std.is(result.shape.body.userData.data, Towable)) {
			trace("nearest target is type: " + Type.typeof(result.shape.body.userData.data));
			return false;
		} else {
			var norm = result.normal;
			var cargoContactPoint = ray.at(result.distance).sub(cargo.body.position).rotate(-cargo.body.rotation);
			var cargoCol = new ContactBundle(cargoContactPoint, norm, Vec2.get());
			var shipCol = new ContactBundle(Vec2.get(), Vec2.get(), Vec2.get());
			rope.attach(shipBody, shipCol, cargo, cargoCol, maxLength);
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
