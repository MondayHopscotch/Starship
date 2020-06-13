package objects;

import constants.CGroups;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.math.FlxAngle;
import geometry.ContactBundle;
import geometry.Shapes;
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

	var tangentDrag:Float = 0.01;

	public function new() {
		segments = [];
	}

	public function attach(a:FlxNapeSprite, aContact:ContactBundle, b:Towable, bContact:ContactBundle, length:Float) {
		objA = a;
		objB = b;
		maxLength = length;

		if (ends == null) {
			ends = new DistanceJoint(a.body, b.body, aContact.point, bContact.point, 0, maxLength);
			ends.stiff = false;
			ends.frequency = 20;
			ends.damping = 4;
			ends.space = FlxNapeSpace.space;
		} else {
			ends.body2 = b.body;
			ends.anchor2 = bContact.point;
		}
		b.inTow(ends);

		if (pulley == null) {
			// to get around limitations of how this can be constructed, we are criss-crossing the bodies
			pulley = new PulleyJoint(a.body, b.body, a.body, b.body, aContact.point, bContact.point, aContact.point, bContact.point, 0, maxLength, 1);
			pulley.space = FlxNapeSpace.space;
			pulley.stiff = false;
			ends.frequency = 20;
			ends.damping = 4;
		} else {
			pulley.space = FlxNapeSpace.space;
			pulley.body1 = a.body;
			pulley.anchor1 = aContact.point;
			pulley.body2 = b.body;
			pulley.anchor2 = bContact.point;
			pulley.body3 = a.body;
			pulley.anchor3 = aContact.point;
			pulley.body4 = b.body;
			pulley.anchor4 = bContact.point;
		}
		pulley.active = false;
		ends.active = true;
		ends.space = FlxNapeSpace.space;

		var bNormal = bContact.point.copy().normalise();
		segments = [];
		var seg = new RopeSegment(a.body, new ContactBundle(aContact.point.copy(), Vec2.get(), Vec2.get()), b.body,
			new ContactBundle(bContact.point.copy(), bNormal, Vec2.get()));
		addSegment(seg);
	}

	public function addSegment(s:RopeSegment, index:Int = -1) {
		if (index == -1) {
			segments.push(s);
		} else {
			segments.insert(index, s);
		}
		FlxG.state.add(s);
	}

	public function removeSegment(index:Int) {
		segments[index].kill();
		segments[index].contact1.kill();
		segments[index].contact2.kill();
		segments.remove(segments[index]);
	}

	public function detach() {
		objB.outOfTow();
		ends.active = false;
		ends.space = null;
		pulley.active = false;
		pulley.space = null;
		for (s in segments) {
			s.contact1.kill();
			s.contact2.kill();
			s.kill();
		}
		segments = [];
	}

	public function isAttached():Bool {
		return segments.length > 0;
	}

	public function update(delta:Float) {
		FlxG.watch.addQuick("Segments:", segments.length);
		if (!isAttached()) {
			return;
		}

		if (ends.body1.space == null || ends.body2.space == null) {
			// something doesn't exist, rope is broken
			segments = [];
		}

		if (segments.length == 0) {
			return;
		}

		// only update the ends as they are the only points that can move currently.
		segments[0].update(delta);

		if (segments.length > 1) {
			segments[segments.length - 1].update(delta);
			FlxG.watch.addQuick("Head Delta:", segments[0].delta());
			FlxG.watch.addQuick("Tail Delta:", segments[segments.length - 1].delta());
		}

		// only checking ends
		checkNewContact(0);
		checkNewContact(segments.length - 1);

		if (segments.length > 1) {
			checkForRemoval(0, 1);
		}

		if (segments.length > 1) {
			checkForRemoval(segments.length - 2, segments.length - 1);
		}

		if (segments.length > 1) {
			pulley.active = true;
			pulley.space = FlxNapeSpace.space;
			pulley.body2 = segments[0].contact2.body;
			pulley.anchor2 = segments[0].contact2.contact.point;
			pulley.body3 = segments[segments.length - 1].contact1.body;
			pulley.anchor3 = segments[segments.length - 1].contact1.contact.point;
			pulley.jointMax = getRopeLooseLength();
		} else {
			pulley.active = false;
			pulley.space = null;
		}

		var offset = 0.0;
		var i = segments.length - 1;
		while (i >= 0) {
			FlxG.state.add(segments[i]);
			offset += segments[i].getSpriteOffsetAmount();
			segments[i].setSpriteOffset(offset);
			// To display normals
			FlxG.state.add(segments[i].contact2);

			i--;
		}
	}

	function getRopeNormal(segment:RopeSegment):Vec2 {
		var delta = segment.delta().muleq(-1);
		var ropeNormal = segment.contact1.worldPoint.sub(segment.contact2.worldPoint).perp().normalise();
		if (delta.dot(ropeNormal) > 0) {
			return ropeNormal;
		} else {
			return ropeNormal.muleq(-1);
		}
	}

	function checkNewContact(index:Int) {
		var start = segments[index].contact1;
		var end = segments[index].contact2;
		var norm = getRopeNormal(segments[index]);
		var contact = castRope(start, end, norm);
		if (contact == null) {
			contact = castRope(end, start, norm);
		}

		if (contact != null) {
			var distFromStart = Vec2.distance(start.worldPoint, contact.worldPoint);
			var distFromEnd = Vec2.distance(end.worldPoint, contact.worldPoint);
			if (distFromStart < 1 || distFromEnd < 1) {
				return;
			}

			segments[index].contact1.kill();
			segments[index].contact2.kill();
			removeSegment(index);
			var toStart = RopeSegment.fromContacts(start, contact);
			addSegment(toStart, index);
			var toEnd = RopeSegment.fromContacts(contact, end);
			addSegment(toEnd, index + 1);
		}
	}

	function checkForRemoval(a:Int, b:Int) {
		var start = segments[a].contact1;
		var end = segments[b].contact2;
		var contact = castRope(start, end);
		var reverseContact = castRope(end, start);
		if (contact == null && reverseContact == null) {
			if (start.body == end.body) {
				contact = castRopeSameBody(start, end);

				if (contact == null) {
					// now we are fairly sure we not touching (at least for squares... this might fall apart for more than 4-gons)
					return;
				}
			}
			if (FlxNapeSpace.space.bodiesUnderPoint(end.worldPoint).has(start.body)) {
				// we are inside / on edge. these don't count for removing other points
				return;
			}

			var pointNormalVector = segments[a].contact2.worldNormal;

			// we want all 3 of these to be relative to their respective shapes' centers
			var pointWorldPosition = segments[a].contact2.worldPoint;
			var startPosition = start.worldPoint;
			var endPosition = end.worldPoint;

			var startVector = startPosition.sub(pointWorldPosition).normalise();
			var endVector = endPosition.sub(pointWorldPosition).normalise();

			var totalVector = startVector.add(endVector).normalise();

			if (totalVector.dot(pointNormalVector) > 0) {
				var newSegment = RopeSegment.fromContacts(start, end);
				removeSegment(b);
				removeSegment(a);
				addSegment(newSegment, a);
			}
		}
	}

	function castRopeSameBody(start:RopeContactPoint, end:RopeContactPoint):RopeContactPoint {
		var newStart = start.copy();
		newStart.contact.point = newStart.contact.point.add(newStart.contact.point.normalise());
		var newEnd = end.copy();
		newEnd.contact.point = newEnd.contact.point.add(newEnd.contact.point.normalise());
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

		FlxG.watch.addQuick("LooseEndLength:", remaining);
		return remaining;
	}

	// Casts to find if there is any contact point between the given two points, returning it if found
	function castRope(start:RopeContactPoint, end:RopeContactPoint, normalInfluece:Vec2 = null):RopeContactPoint {
		var startWorldPoint = start.worldPoint;
		var endWorldPoint = end.worldPoint;

		// if (startWorldPoint.x == endWorldPoint.x && startWorldPoint.y == endWorldPoint.y) {
		// 	trace("samsies");
		// 	// for (s in segments) {
		// 	// 	// TODO: Print out what the rope looks like when we hit this condition
		// 	// 	trace("segment: " + s.contact1.body + "(" + s.contact1.point + ") -> " + s.contact2.body + "(" + s.contact2.point + ")");
		// 	// }
		// }

		var ray = Ray.fromSegment(startWorldPoint, endWorldPoint);
		ray.maxDistance = Vec2.distance(startWorldPoint, endWorldPoint);
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

		var localPoint = result.shape.body.getLocalPoint(newContactCoords);
		var localCenter = Shapes.getCenter(result.shape);
		var localNormal = Vec2.get();
		var vertexResolveVec = Vec2.get();

		if (!result.shape.isPolygon()) {
			FlxG.watch.addQuick("collision detected:", false);
		} else {
			var verts:Vec2List = cast(result.shape, Polygon).localVerts;
			var dist:Float = Math.POSITIVE_INFINITY;
			var matchIndex:Int = -1;
			for (i in 0...verts.length) {
				var newDist = Vec2.distance(localPoint, verts.at(i));
				if (newDist < dist) {
					matchIndex = i;
					dist = newDist;
				}
			}
			vertexResolveVec.set(verts.at(matchIndex).sub(localPoint));
			localPoint = verts.at(matchIndex).copy();

			if (Vec2.distance(startWorldPoint, result.shape.body.getWorldPoint(localPoint)) == 0) {
				// don't allow redundant too close together
				return null;
			}
			if (Vec2.distance(endWorldPoint, result.shape.body.getWorldPoint(localPoint)) == 0) {
				// don't allow redundant too close together
				return null;
			}

			if (normalInfluece != null && normalInfluece.length > 0) {
				localNormal = normalInfluece.normalise();
			} else {
				var leftNormal = verts.at((matchIndex + verts.length - 1) % verts.length)
					.copy()
					.sub(verts.at(matchIndex))
					.rotate(Math.PI / 2)
					.normalise();
				var rightNormal = verts.at(matchIndex)
					.copy()
					.sub(verts.at((matchIndex + verts.length + 1) % verts.length))
					.rotate(Math.PI / 2)
					.normalise();

				var ropeNormal = ray.direction.perp().normalise();
				var normalCandidate = leftNormal.add(rightNormal).normalise();
				if (normalCandidate.dot(ropeNormal) > 0) {
					localNormal = ropeNormal;
				} else {
					localNormal = ropeNormal.muleq(-1);
				}
			}
		}

		if (result.shape.body == start.body && Vec2.distance(localPoint, start.contact.point) == 0) {
			// colliding with the same shape, at same vertex, no new rope point
			// trace("Collided with start point");
			return null;
		}

		if (result.shape.body == end.body && Vec2.distance(localPoint, end.contact.point) == 0) {
			// colliding with the same shape, at same vertex, no new rope point
			// trace("Collided with end point");
			return null;
		}

		return new RopeContactPoint(result.shape.body, new ContactBundle(localPoint, localNormal, localCenter));
		// return new RopeContactPoint(result.shape.body, new ContactBundle(localPoint, result.normal, localCenter));
	}
}
