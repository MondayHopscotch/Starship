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
import nape.geom.Vec2List;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.EdgeList;
import nape.shape.Polygon;
import objects.Towable;

using extensions.BodyExt;

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

	var rope:Rope;

	public function new(x:Int, y:Int) {
		super();
		setPosition(x, y);
		loadGraphic(AssetPaths.shot__png);

		controls = new BasicControls();

		rope = new Rope();

		var body = new Body(BodyType.DYNAMIC);
		body.isBullet = true;
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

		if (controls.pause.check()) {
			FlxG.vcr. = true;
		}

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

		rope.update(elapsed);

		if (controls.toggleGrapple.check()) {
			FlxG.log.notice("Tow toggled");
			if (rope.isAttached()) {
				rope.detach();
			} else {
				validCargoTargets.sort((t1,
						t2) -> return Math.floor(Math.abs(Vec2.distance(this.body.position,
						t2.body.position) - Vec2.distance(this.body.position, t1.body.position))));
				for (c in validCargoTargets) {
					tetherCargo(c);
				}
				FlxG.log.notice("no tow in range");
			}
		}
	}

	function tetherCargo(cargo:Towable):Bool {
		var ray = Ray.fromSegment(Vec2.get().set(body.position), Vec2.get().set(cargo.body.position));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.ALL, CollisionGroups.ALL));

		if (result == null) {
			FlxG.log.notice("no valid tow result");
			return false;
		} else if (!Std.is(result.shape.body.userData.data, Towable)) {
			FlxG.log.notice("nearest target is type: " + Type.typeof(result.shape.body.userData.data));
			return false;
		} else {
			rope.attach(this, Vec2.get(), cargo, ray.at(result.distance).sub(Vec2.weak().set(cargo.body.position)).rotate(-cargo.body.rotation),
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
