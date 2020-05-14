package geometry;

import nape.geom.Vec2;

class ContactBundle {
	// the point of interest
	public var point:Vec2;
	// the normal for this point relative to the center
	public var normal:Vec2;
	// the center of the shape owning the point
	public var center:Vec2;

	public function new(p:Vec2, n:Vec2, c:Vec2) {
		this.point = p;
		this.normal = n;
		this.center = c;
	}

	public function copy():ContactBundle {
		return new ContactBundle(point.copy(), normal.copy(), center.copy());
	}
}
