package objects;

import geometry.ContactBundle;
import nape.geom.Vec2;
import nape.phys.Body;

class RopeContactPoint {
	public var body:Body;
	public var contact:ContactBundle;

	public function new(b:Body, c:ContactBundle) {
		body = b;
		contact = c;
	}

	public function getWorldPoint():Vec2 {
		return contact.point.copy().rotate(body.rotation).add(body.position);
	}

	public function getWorldNormal():Vec2 {
		return contact.normal.copy().rotate(body.rotation);
	}

	public function copy():RopeContactPoint {
		return new RopeContactPoint(body, contact.copy());
	}
}
