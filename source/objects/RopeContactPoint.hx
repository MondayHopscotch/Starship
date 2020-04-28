package objects;

import nape.geom.Vec2;
import nape.phys.Body;

class RopeContactPoint {
	public var body:Body;
	public var point:Vec2;

	public function new(b:Body, p:Vec2) {
		body = b;
		point = p;
	}

	public function getWorldPoint():Vec2 {
		return point.copy().rotate(body.rotation).add(body.position);
	}

	public function copy():RopeContactPoint {
		return new RopeContactPoint(body, point.copy());
	}
}
