package objects;

import constants.CGroups;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import nape.constraint.DistanceJoint;
import nape.constraint.PulleyJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.geom.RayResultList;
import nape.geom.Vec2;
import nape.geom.Vec2List;
import nape.phys.Body;
import nape.shape.Polygon;

using extensions.BodyExt;

class Rope {
	var objA:FlxNapeSprite;
	var objB:Towable;
	var pulley:PulleyJoint;
	var ends:DistanceJoint;
	var maxLength:Float;

	var segments:Array<RopeSegment>;

	var attached:Bool;

	public function new() {
		segments = [];
		attached = false;
	}

	public function attach(a:FlxNapeSprite, aAnchor:Vec2, b:Towable, bAnchor:Vec2, length:Float) {
		objA = a;
		objB = b;
		maxLength = length;

		if (ends == null) {
			ends = new DistanceJoint(a.body, b.body, aAnchor, bAnchor, 0, maxLength);
			ends.stiff = false;
			ends.frequency = 20;
			ends.damping = 4;
			ends.space = FlxNapeSpace.space;
		} else {
			ends.body2 = b.body;
			ends.anchor2 = bAnchor;
		}
		b.inTow(ends);

		var fillerBody1 = new Body();
		var fillerBody2 = new Body();

		if (pulley == null) {
			// to get around limitations of how this can be constructed, we are criss-crossing the bodies
			pulley = new PulleyJoint(a.body, b.body, a.body, b.body, aAnchor, bAnchor, aAnchor, bAnchor, 0, maxLength, 1);
			pulley.active = false;
			pulley.space = FlxNapeSpace.space;
		}
		attached = true;
		ends.active = true;
		ends.space = FlxNapeSpace.space;
	}

	public function detach() {
		objB.outOfTow();
		ends.active = false;
		ends.space = null;
		pulley.active = false;
		pulley.space = null;
		segments = [];
		attached = false;
	}

	public function isAttached():Bool {
		return attached;
	}

	public function update(delta:Float) {
		if (!attached) {
			return;
		}

		if (ends.body1.space == null || ends.body2.space == null) {
			// something doesn't exist, rope is broken
			attached = false;
			return;
		}

		var e2eRay = Ray.fromSegment(ends.body1.getWorldPoint(ends.anchor1), ends.body2.getWorldPoint(ends.anchor2));
		var e2eResult:RayResult = FlxNapeSpace.space.rayCast(e2eRay, false, new InteractionFilter(CGroups.TERRAIN, CGroups.TERRAIN, 0, 0));

		if (segments.length == 0) {
			if (e2eResult == null) {
				// nothing to do
				return;
			}

			FlxG.watch.addQuick("Rope contact: ", true);
			trace("attaching pulley");
			pulley.active = true;
			pulley.space = FlxNapeSpace.space;
			pulley.body1 = ends.body1;
			pulley.body2 = e2eResult.shape.body;
			pulley.body3 = e2eResult.shape.body;
			pulley.body4 = ends.body2;

			pulley.anchor1 = ends.anchor1;
			pulley.anchor2 = e2eResult.shape.body.getLocalPoint(e2eRay.at(e2eResult.distance));
			pulley.anchor3 = e2eResult.shape.body.getLocalPoint(e2eRay.at(e2eResult.distance));
			pulley.anchor4 = ends.anchor2;

			segments.push(new RopeSegment(pulley.body1, pulley.anchor1, pulley.body2, pulley.anchor2));
			segments.push(new RopeSegment(pulley.body3, pulley.anchor3, pulley.body4, pulley.anchor4));
		}

		FlxG.watch.addQuick("Rope segments:", segments.length);
		trace("segments coming into update:");
		for (s in segments) {
			trace("(" + s.contact1.body + "->" + s.contact2.body + ")");
		}
		trace("");
		// no points of contact end to end, and only one rope touchpoint. This means we are no longer pullied
		if (e2eResult == null && segments.length == 2) {
			// TODO: Simplify this... please.
			var pointLocal = pulley.anchor2.copy().rotate(pulley.body2.rotation);
			var pointNormalVector = pointLocal.copy().normalise();
			var pointWorldPosition = pulley.body2.position.add(pointLocal);
			var shipPosition = pulley.anchor1.copy().rotate(pulley.body1.rotation).add(pulley.body1.position);
			var cargoPosition = pulley.anchor4.copy().rotate(pulley.body4.rotation).add(pulley.body4.position);

			var shipVector = shipPosition.sub(pointWorldPosition).normalise();
			var cargoVector = cargoPosition.sub(pointWorldPosition).normalise();

			var totalVector = shipVector.add(cargoVector).normalise();

			if (totalVector.dot(pointNormalVector) > 0) {
				FlxG.log.notice("removing pulley");
				pulley.active = false;
				segments = [];
				return;
			}
		}

		// look for new contact points between start and the first contact
		var start:RopeContactPoint = segments[0].contact1;
		var end:RopeContactPoint = segments[0].contact2;
		var contact:RopeContactPoint = castRope(start, end);
		if (contact != null) {
			trace("-----adding new start-end segment-----");
			trace("--replacing: " + start.body + "(" + start.point + ")->" + end.body + "(" + end.point + ")");
			segments.remove(segments[0]);
			var toEnd = RopeSegment.fromContacts(contact, end);
			segments.unshift(toEnd);
			var toStart = RopeSegment.fromContacts(start, contact);
			segments.unshift(toStart);
			pulley.body2 = contact.body;
			pulley.anchor2 = contact.point;
			pulley.jointMax = getRopeLooseLength();

			trace("new segment added: " + toStart.contact1.body + "(" + toStart.contact1.point + ") -> " + toStart.contact2.body + "("
				+ toStart.contact2.point + ")");
			trace("new segment added: "
				+ toEnd.contact1.body
				+ "("
				+ toEnd.contact1.point
				+ ") -> "
				+ toEnd.contact2.body
				+ "("
				+ toEnd.contact2.point
				+ ")");
			trace("");
		}
		// look for new contact points between last contact and the end of the rope
		start = segments[segments.length - 1].contact1;
		end = segments[segments.length - 1].contact2;
		contact = castRope(end, start);
		if (contact != null) {
			trace("-----adding new tail-end segment-----");
			trace("--replacing: " + start.body + "(" + start.point + ")->" + end.body + "(" + end.point + ")");
			segments.remove(segments[segments.length - 1]);
			var toStart = RopeSegment.fromContacts(start, contact);
			segments.push(toStart);
			var toEnd = RopeSegment.fromContacts(contact, end);
			segments.push(toEnd);
			pulley.body3 = contact.body;
			pulley.anchor3 = contact.point;
			pulley.jointMax = getRopeLooseLength();
			trace("new segment added: " + toStart.contact1.body + "(" + toStart.contact1.point + ") -> " + toStart.contact2.body + "("
				+ toStart.contact2.point + ")");
			trace("new segment added: "
				+ toEnd.contact1.body
				+ "("
				+ toEnd.contact1.point
				+ ") -> "
				+ toEnd.contact2.body
				+ "("
				+ toEnd.contact2.point
				+ ")");
			trace("");
		}

		// check for lost contact
		if (segments.length > 2) {
			for (i in 0...segments.length) {
				if (i + 1 < segments.length) {
					start = segments[i].contact1;
					end = segments[i + 1].contact2;
					contact = castRope(start, end);
					var reverseContact = castRope(end, start);
					if (contact == null && reverseContact == null) {
						if (start.body == end.body) {
							contact = castRopeSameBody(start, end);

							if (contact == null) {
								// now we are fairly sure we not touching (at least for squares... this might fall apart for more than 4-gons)
								continue;
							}
						}
						if (FlxNapeSpace.space.bodiesUnderPoint(end.getWorldPoint()).has(start.body)) {
							// we are inside / on edge. these don't count for removing other points
							continue;
						}
						var newSegment = RopeSegment.fromContacts(start, end);
						if (i == 0) {
							pulley.body2 = end.body;
							pulley.anchor2 = end.point;
						} else if (i == segments.length - 2) {
							pulley.body3 = start.body;
							pulley.anchor3 = start.point;
						}
						// TODO: this could probably be cleaner
						segments.remove(segments[i + 1]);
						segments.remove(segments[i]);
						segments.insert(i, newSegment);

						pulley.jointMax = getRopeLooseLength();
						// trace("Removing segment:" + segments.length + " (frame " + frameCount + ")");
					}
				}
			}
		}
	}

	function castRopeSameBody(start:RopeContactPoint, end:RopeContactPoint):RopeContactPoint {
		var newStart = start.copy();
		newStart.point = newStart.point.add(newStart.point.normalise());
		var newEnd = end.copy();
		newEnd.point = newEnd.point.add(newEnd.point.normalise());
		return castRope(newStart, newEnd);
	}

	function getRopeLooseLength():Float {
		if (segments.length < 3) {
			return maxLength;
		}

		var remaining:Float = maxLength;
		for (i in 1...segments.length - 1) {
			remaining -= segments[i].length();
		}
		return remaining;
	}

	// Casts to find if there is any contact point between the given two points, returning it if found
	function castRope(start:RopeContactPoint, end:RopeContactPoint):RopeContactPoint {
		var startWorldPoint = start.body.getWorldPoint(start.point);
		var endWorldPoint = end.body.getWorldPoint(end.point);

		if (startWorldPoint.x == endWorldPoint.x && startWorldPoint.y == endWorldPoint.y) {
			trace("samsies");
			for (s in segments) {
				// TODO: Print out what the rope looks like when we hit this condition
				trace("segment: " + s.contact1.body + "(" + s.contact1.point + ") -> " + s.contact2.body + "(" + s.contact2.point + ")");
			}
		}

		var ray = Ray.fromSegment(startWorldPoint, endWorldPoint);
		var results:RayResultList = FlxNapeSpace.space.rayMultiCast(ray, true, new InteractionFilter(CGroups.TERRAIN, CGroups.TERRAIN, 0, 0));
		if (results == null || results.length == 0) {
			return null;
		}

		var result:RayResult = null;

		for (r in results) {
			// not sure how to make this not collide with the ship sensor
			// so... we'll just ignore sensors explicitly
			if (!r.shape.sensorEnabled) {
				result = r;
				break;
			}
		}

		if (result == null) {
			return null;
		}

		var newContactCoords = ray.at(result.distance);
		if (Vec2.distance(startWorldPoint, newContactCoords) <= 0) {
			// don't allow contacts too close together
			return null;
		}
		if (Vec2.distance(endWorldPoint, newContactCoords) <= 0) {
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
			localPoint = closestVert.copy();
		}

		if (result.shape.body == start.body && Vec2.distance(localPoint, start.point) == 0) {
			// colliding with the same shape, at same vertex, no new rope point
			// trace("Collided with start point");
			return null;
		}

		if (result.shape.body == end.body && Vec2.distance(localPoint, end.point) == 0) {
			// colliding with the same shape, at same vertex, no new rope point
			// trace("Collided with end point");
			return null;
		}

		// localPoint.subeq(localPoint.copy().normalise());
		return new RopeContactPoint(result.shape.body, localPoint);
	}
}
