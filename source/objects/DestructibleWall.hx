package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;

class DestructibleWall extends SelfAssigningFlxNapeSprite {
	public static function create(spriteName:FlxGraphicAsset, x:Int, y:Int, width:Float, height:Float):DestructibleWall {
		var wall = new DestructibleWall();
		wall.loadGraphic(spriteName);
		wall.setPosition(x, y);
		wall.scale.set(width / 3, height / 3);

		var wallBody = new Body(BodyType.STATIC);
		wallBody.isBullet = true;
		wallBody.shapes.add(new Polygon(Polygon.rect(-width / 2, -height / 2, width, height)));
		wallBody.mass *= 5;
		wallBody.cbTypes.add(CbTypes.CB_TERRAIN);
		wallBody.cbTypes.add(CbTypes.CB_DESTRUCTIBLE);

		var wallFilter = new InteractionFilter(CGroups.TERRAIN);
		wallBody.setShapeFilters(wallFilter);

		wall.addPremadeBody(wallBody);
		return wall;
	}
}
