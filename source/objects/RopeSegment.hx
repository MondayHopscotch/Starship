package objects;

import nape.geom.Vec2;
import nape.phys.Body;

using extensions.BodyExt;

class RopeSegment {
	public var contact1:RopeContactPoint;
	public var contact2:RopeContactPoint;

	public static function fromContacts(s:RopeContactPoint, e:RopeContactPoint):RopeSegment {
		return new RopeSegment(s.body, s.point.copy(), e.body, e.point.copy());
	}

	public function new(b1:Body, a1:Vec2, b2:Body, a2:Vec2) {
		contact1 = new RopeContactPoint(b1, a1);
		contact2 = new RopeContactPoint(b2, a2);
	}

	public function length():Float {
		return Vec2.distance(contact1.body.getWorldPoint(contact1.point), contact2.body.getWorldPoint(contact2.point));
	}
}
