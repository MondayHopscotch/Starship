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

class ShipBody extends FlxNapeSprite {
	public function new(x:Int, y:Int) {
		super();
		setPosition(x, y);
		loadGraphic(AssetPaths.shot__png);

		var body = new Body(BodyType.DYNAMIC);
		body.isBullet = true;
		body.shapes.add(new Polygon(Polygon.regular(40, 20, 3)));

		var shipFilter = new InteractionFilter(CollisionGroups.SHIP, ~(CollisionGroups.CARGO));
		body.setShapeFilters(shipFilter);

		addPremadeBody(body);
		body.rotation = -Math.PI / 2;
	}
}
