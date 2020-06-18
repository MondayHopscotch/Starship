package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxRandom;
import flixel.math.FlxVector;
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

	var thrustEmitter:FlxEmitter;
	var dustEmitter:FlxEmitter;

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

		thrustEmitter = new FlxEmitter();
		thrustEmitter.launchMode = SQUARE;
		thrustEmitter.makeParticles(2, 2, FlxColor.GRAY, 1000);
		thrustEmitter.lifespan.min = 0.5;
		thrustEmitter.lifespan.max = 0.75;
		thrustEmitter.alpha.set(1, 1, 0.01, 0.05);
		thrustEmitter.scale.set(1, 1, 1, 1, 1, 1, 2, 2);
		thrustEmitter.start(false, 0.01);
		thrustEmitter.emitting = false;
		add(thrustEmitter);

		dustEmitter = new FlxEmitter();
		dustEmitter.launchMode = SQUARE;
		dustEmitter.makeParticles(2, 2, FlxColor.GRAY, 1000);
		dustEmitter.lifespan.min = 0.5;
		dustEmitter.lifespan.max = 0.75;
		dustEmitter.alpha.set(1, 1, 0.01, 0.05);
		dustEmitter.scale.set(1, 1, 1, 1, 1, 1, 3, 3);
		dustEmitter.start(false, 0.01);
		dustEmitter.emitting = false;
		add(dustEmitter);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		thrustEmitter.setPosition(shipBody.x + shipBody.boostPos().x, shipBody.y + shipBody.boostPos().y);

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

			setThrustParticles(controls.thruster.x);
			checkEnvironmentDustKickup(controls.thruster.x);
		} else {
			thrustEmitter.emitting = false;
			dustEmitter.emitting = false;
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

	private function setThrustParticles(power:Float):Void {
		thrustEmitter.frequency = (1 - power) * 0.1;
		thrustEmitter.emitting = true;

		var velo = Vec2.get(-100, 0, false);
		var rotation = (shipBody.angle - 90 + (FlxG.random.int(0, 10) - 5)) * FlxAngle.TO_RAD;

		velo.rotate(rotation);
		velo.addeq(shipBody.body.velocity);
		velo.rotate(-rotation);

		// don't let our smoke emit moving forward. At best the smoke is stationary
		velo.x = Math.min(velo.x, 0);
		velo.rotate(rotation);

		thrustEmitter.velocity.set(velo.x, velo.y, velo.x, velo.y, 0, 0, 0, 0);
		velo.dispose();
	}

	public function checkEnvironmentDustKickup(power:Float):Void {
		var maxDistance = power * 70;
		var origin = Vec2.get(shipBody.x + shipBody.boostPos().x, shipBody.y + shipBody.boostPos().y);
		var end = origin.add(Vec2.get(1, 0, true).rotate(shipBody.body.rotation + FlxAngle.asRadians(90)).mul(maxDistance));
		var ray = Ray.fromSegment(origin, end);
		var result = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CGroups.TERRAIN, CGroups.TERRAIN, 0, 0));
		if (result == null) {
			dustEmitter.emitting = false;
			return;
		}

		dustEmitter.frequency = (1 - power) * 0.1;

		var pos = ray.at(result.distance);
		dustEmitter.setPosition(pos.x, pos.y);
		// dustEmitter.angle.set(pos.reflect(result.normal, true).angle);

		var dustVariance = FlxAngle.asRadians(15);

		var dustDir = result.normal.perp();
		if (ray.direction.dot(dustDir) < 0) {
			dustDir.muleq(-1);
		} else {
			dustVariance *= -1;
		}
		// scale the dust splatter based on our power and the distance away from the ship
		dustDir.muleq(100 * (power - (result.distance / ray.maxDistance)));

		// this distance will be between sqrt(2) and 2
		var dist = Vec2.distance(result.normal, ray.direction.normalise());
		// normalize to a value between 0 and 1
		var percentageSameDirection = (dist - FlxMath.SQUARE_ROOT_OF_TWO) / (2 - FlxMath.SQUARE_ROOT_OF_TWO);

		// exagerate our falloff
		percentageSameDirection = Math.pow(percentageSameDirection, 2);

		// make value between 0 and 0.5 as perpendicular will split particles
		percentageSameDirection /= 2;

		if (FlxG.random.float() < percentageSameDirection) {
			dustDir.muleq(-1);
			dustVariance *= -1;
		}

		dustDir = dustDir.rotate(FlxG.random.float(0, dustVariance));

		dustEmitter.velocity.set(dustDir.x, dustDir.y, dustDir.x, dustDir.y, 0, 0, 0, 0);
		dustEmitter.emitting = true;
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
