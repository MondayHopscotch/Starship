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

	var jointed:Bool = false;
	var joint:DistanceJoint = null;
	var pullied:Bool = false;
	var pulley:PulleyJoint = null;

	var rope:Array<RopeSegment> = [];

	public function new(x:Int, y:Int) {
		super();
		setPosition(x, y);
		loadGraphic(AssetPaths.shot__png);

		controls = new BasicControls();

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

				pullied = false;
				pulley.active = false;
				rope = [];
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
			// add some magic 0.5 here to have the mount point be inside the cargo object
			joint.anchor2.set(ray.at(result.distance).sub(Vec2.weak().set(cargo.body.position)).rotate(-cargo.body.rotation));
			// joint.anchor2.set(Vec2.weak());
			cargo.inTow(joint);
			return true;
		}
	}

	var lastReportedLength:Int = 0;
	var frameCount:Int = 0;
	var addedNewSegmentsDelay:Int = 0;

	public function updateRope() {
		if (pulley == null) {
			pulley = new PulleyJoint(this.body, this.body, this.body, this.body, Vec2.weak(), Vec2.weak(), Vec2.weak(), Vec2.weak(), MIN_TOW_DISTANCE,
				MAX_TOW_DISTANCE, 1);
			pulley.active = false;
			pulley.space = FlxNapeSpace.space;
		}

		var e2eRay = Ray.fromSegment(Vec2.get().set(joint.body1.position), Vec2.get().set(joint.body2.position));
		var e2eResult:RayResult = FlxNapeSpace.space.rayCast(e2eRay, false, new InteractionFilter(CollisionGroups.TERRAIN, CollisionGroups.TERRAIN));

		if (!pullied) {
			// check for initial rope contact
			if (e2eResult != null) {
				FlxG.watch.addQuick("Rope contact: ", true);
				FlxG.log.notice("attaching pulley");
				pullied = true;
				pulley.active = true;
				pulley.body1 = body;
				pulley.body2 = e2eResult.shape.body;
				pulley.body3 = e2eResult.shape.body;
				pulley.body4 = joint.body2;

				pulley.anchor1 = joint.anchor1;
				pulley.anchor2 = e2eResult.shape.body.getLocalPoint(e2eRay.at(e2eResult.distance));
				pulley.anchor3 = e2eResult.shape.body.getLocalPoint(e2eRay.at(e2eResult.distance));
				pulley.anchor4 = joint.anchor2;

				// push our two rope segments into our rope tracker
				rope.push(new RopeSegment(pulley.body1, pulley.anchor1, pulley.body2, pulley.anchor2));
				rope.push(new RopeSegment(pulley.body3, pulley.anchor3, pulley.body4, pulley.anchor4));
			}
		} else {
			FlxG.watch.addQuick("Rope segments:", rope.length);
			// no points of contact end to end, and only one rope touchpoint. This means we are no longer pullied
			if (e2eResult == null && rope.length == 2) {
				var pointNormal = pulley.anchor2.copy().rotate(pulley.body2.rotation);
				var pointPosition = pulley.body2.position.copy().add(pointNormal);
				var shipDirection = pulley.anchor1.copy().rotate(pulley.body1.rotation);
				shipDirection = shipDirection.sub(pointPosition);
				var cargoDirection = pulley.anchor4.copy().rotate(pulley.body4.rotation);
				cargoDirection = cargoDirection.sub(pointPosition);

				// if (shipDirection.dot(pointNormal) > 0 && cargoDirection.dot(pointNormal) > 0) {
				FlxG.log.notice("removing pulley");
				pullied = false;
				pulley.active = false;
				rope = [];
				return;
				// }
			}

			frameCount++;
			if (rope.length != lastReportedLength) {
				var order:String = "";
				for (s in rope) {
					var pos1 = s.contact1.body.getWorldPoint(s.contact1.point);
					var pos2 = s.contact2.body.getWorldPoint(s.contact2.point);
					order += "(" + Math.floor(pos1.x) + ", " + Math.floor(pos1.y) + " -> " + Math.floor(pos2.x) + ", " + Math.floor(pos2.y) + ")";
				}
				// trace("Frame #" + frameCount);
				// trace("Ship : " + Math.floor(body.position.x) + ", " + Math.floor(body.position.y));
				// trace("Cargo: " + Math.floor(joint.body2.position.x) + ", " + Math.floor(joint.body2.position.y));
				// trace(order);
				lastReportedLength = rope.length;
			}

			var start:RopeContactPoint;
			var end:RopeContactPoint;
			var contact:RopeContactPoint;
			var reverseContact:RopeContactPoint;

			// look for new contact points between start and the first contact
			start = rope[0].contact1;
			end = rope[0].contact2;
			contact = castRope(start, end);
			if (contact != null) {
				addedNewSegmentsDelay = 2;
				rope.remove(rope[0]);
				var toEnd = RopeSegment.fromContacts(contact, end);
				rope.unshift(toEnd);
				var toStart = RopeSegment.fromContacts(start, contact);
				rope.unshift(toStart);
				pulley.body2 = contact.body;
				pulley.anchor2 = contact.point;
				pulley.jointMax = getRopeLooseLength();
			}
			// look for new contact points between last contact and the end of the rope
			start = rope[rope.length - 1].contact1;
			end = rope[rope.length - 1].contact2;
			contact = castRope(end, start);
			if (contact != null) {
				addedNewSegmentsDelay = 2;
				rope.remove(rope[rope.length - 1]);
				var toStart = RopeSegment.fromContacts(start, contact);
				rope.push(toStart);
				var toEnd = RopeSegment.fromContacts(contact, end);
				rope.push(toEnd);
				pulley.body3 = contact.body;
				pulley.anchor3 = contact.point;
				pulley.jointMax = getRopeLooseLength();
				// trace("Adding segment  :" + rope.length + " (frame " + frameCount + ")");
			}

			if (addedNewSegmentsDelay > 0) {
				// let's not remove segments on same frame we add
				addedNewSegmentsDelay--;
				return;
			}

			// check for lost contact
			if (rope.length > 2) {
				for (i in 0...rope.length) {
					if (i + 1 < rope.length) {
						start = rope[i].contact1;
						end = rope[i + 1].contact2;
						contact = castRope(start, end);
						reverseContact = castRope(end, start);
						if (contact == null && reverseContact == null) {
							if (start.body == end.body) {
								contact = castRopeSameBody(start, end);

								if (contact == null) {
									// now we are fairly sure we not touching (at least for squares... this might fall apart for more than 4-gons)
									continue;
								}
							}
							var newSegment = RopeSegment.fromContacts(start, end);
							if (i == 0) {
								pulley.body2 = end.body;
								pulley.anchor2 = end.point;
							} else if (i == rope.length - 2) {
								pulley.body3 = start.body;
								pulley.anchor3 = start.point;
							}
							// TODO: this could probably be cleaner
							rope.remove(rope[i + 1]);
							rope.remove(rope[i]);
							rope.insert(i, newSegment);

							pulley.jointMax = getRopeLooseLength();
							// trace("Removing segment:" + rope.length + " (frame " + frameCount + ")");
						}
					}
				}
			}
		}

		// if (pullied && !isPulleyClear()) {
		// 	return;
		// }
	}

	function isPulleyClear():Bool {
		// return true;
		var final1 = checkPulleyContact(joint.body1, joint.anchor1, pulley.body2, pulley.anchor2);
		var final2 = checkPulleyContact(joint.body2, joint.anchor2, pulley.body3, pulley.anchor3);
		FlxG.watch.addQuick("Ship-pulley clear: ", final1);
		FlxG.watch.addQuick("Cargo-pulley clear: ", final2);
		return final1 && final2;
	}

	function getRopeLooseLength():Float {
		if (rope.length < 3) {
			return MAX_TOW_DISTANCE;
		}

		var remaining:Float = MAX_TOW_DISTANCE;
		for (i in 1...rope.length - 1) {
			remaining -= rope[i].length();
		}
		return remaining;
	}

	function checkPulleyContact(body:Body, bodyAnchor:Vec2, pullyBody:Body, pulleyAchor:Vec2):Bool {
		var ray = Ray.fromSegment(joint.body1.getWorldPoint(joint.anchor1), pulley.body2.getWorldPoint(pulley.anchor2));
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, false, new InteractionFilter(CollisionGroups.TERRAIN, CollisionGroups.TERRAIN));
		return result == null || (result.distance / ray.maxDistance) > 0.95;
	}

	function castRopeSameBody(start:RopeContactPoint, end:RopeContactPoint):RopeContactPoint {
		var newStart = start.copy();
		newStart.point = newStart.point.add(newStart.point.normalise());
		var newEnd = end.copy();
		newEnd.point = newEnd.point.add(newEnd.point.normalise());
		return castRope(newStart, newEnd);
	}

	// Casts to find if there is any contact point between the given two points, returning it if found
	function castRope(start:RopeContactPoint, end:RopeContactPoint):RopeContactPoint {
		var startWorldPoint = start.body.getWorldPoint(start.point);
		var endWorldPoint = end.body.getWorldPoint(end.point);
		// if (Vec2.distance(startWorldPoint, endWorldPoint) < 5) {
		// 	// don't allow contacts too close together
		// 	return null;
		// }
		var ray = Ray.fromSegment(startWorldPoint, endWorldPoint);
		var result:RayResult = FlxNapeSpace.space.rayCast(ray, true, new InteractionFilter(CollisionGroups.TERRAIN, CollisionGroups.TERRAIN));
		if (result == null) {
			return null;
		}

		var newContactCoords = ray.at(result.distance);
		if (Vec2.distance(startWorldPoint, newContactCoords) < 5) {
			// don't allow contacts too close together
			return null;
		}
		if (Vec2.distance(endWorldPoint, newContactCoords) < 5) {
			// don't allow contacts too close together
			return null;
		}

		var localPoint = result.shape.body.getLocalPoint(newContactCoords);
		if (result.shape.isPolygon()) {
			var verts:Vec2List = cast(result.shape, Polygon).localVerts;
			var closestVert:Vec2;
			var dist:Float = Math.POSITIVE_INFINITY;
			verts.foreach(v -> {
				var newDist = Vec2.distance(localPoint, v);
				if (newDist < dist) {
					closestVert = v;
					dist = newDist;
				}
			});
			localPoint = closestVert;
		}
		return new RopeContactPoint(result.shape.body, localPoint);
	}

	public function cargoEnterRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.push(cast(clbk.int2.userData.data, Towable));
	}

	public function cargoExitRangeCallback(clbk:InteractionCallback) {
		validCargoTargets.remove(cast(clbk.int2.userData.data, Towable));
	}
}
