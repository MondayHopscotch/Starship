package objects;

import geometry.ContactBundle;
import nape.geom.Vec2;
import nape.phys.Body;

using extensions.BodyExt;

class RopeSegment {
	public var contact1:RopeContactPoint;
	public var contact2:RopeContactPoint;

	public static function fromContacts(s:RopeContactPoint, e:RopeContactPoint):RopeSegment {
		return new RopeSegment(s.body, s.contact.copy(), e.body, e.contact.copy());
	}

	public function new(b1:Body, c1:ContactBundle, b2:Body, c2:ContactBundle) {
		contact1 = new RopeContactPoint(b1, c1);
		contact2 = new RopeContactPoint(b2, c2);
	}

	public function length():Float {
		return Vec2.distance(contact1.getWorldPoint(), contact2.getWorldPoint());
	}
}
