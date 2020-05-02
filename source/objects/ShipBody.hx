package objects;

import constants.CGroups;
import nape.dynamics.InteractionFilter;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;

class ShipBody extends SelfAssigningFlxNapeSprite {
	public function new(x:Int, y:Int) {
		super();
		setPosition(x, y);
		loadGraphic(AssetPaths.shot__png);

		var body = new Body(BodyType.DYNAMIC);
		body.isBullet = true;
		body.shapes.add(new Polygon(Polygon.regular(40, 20, 3)));

		var shipFilter = new InteractionFilter(CGroups.SHIP, ~(CGroups.CARGO));
		body.setShapeFilters(shipFilter);

		addPremadeBody(body);
		body.rotation = -Math.PI / 2;
	}
}
