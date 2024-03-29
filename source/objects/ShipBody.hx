package objects;

import constants.CGroups;
import flixel.FlxG;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;

class ShipBody extends SelfAssigningFlxNapeSprite {
	var boostLocation:Vec2 = Vec2.get();
	var finalBoostLocation:Vec2 = Vec2.get();

	public function new(x:Int, y:Int) {
		super();
		setPosition(x, y);
		loadGraphic(AssetPaths.shipFiller__png);

		var body = new Body(BodyType.DYNAMIC);
		body.isBullet = true;
		// var poly = new Polygon(Polygon.regular(40, 20, 3));
		// trace(poly.localVerts);
		// body.shapes.add(poly);

		var poly = new Polygon([Vec2.get(-17, 20), Vec2.get(0, -40), Vec2.get(17, 20)]);
		trace(poly.localVerts);
		body.shapes.add(poly);

		boostLocation.setxy(0, 20);

		var shipFilter = new InteractionFilter(CGroups.SHIP, ~(CGroups.CARGO));
		body.setShapeFilters(shipFilter);

		addPremadeBody(body);
	}

	override public function update(delta:Float) {
		super.update(delta);
		// This is to handle the fact that the FlxSprite offset doesn't work properly with rotation to
		// keep it properly aligned with the physics body
		var newVec = Vec2.weak(0, 10).rotate(body.rotation);
		this.offset.set(newVec.x, newVec.y);

		newVec.setxy(getMidpoint().x, getMidpoint().y);

		finalBoostLocation.set(boostLocation).rotate(body.rotation).addeq(Vec2.weak(17, 30));
		FlxG.watch.addQuick("final Boost pos: ", finalBoostLocation);
	}

	public function boostPos():Vec2 {
		return finalBoostLocation;
	}
}
