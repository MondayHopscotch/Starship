package physics;

import constants.CGroups;
import constants.CbTypes;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.phys.BodyType;
import nape.phys.Material;

class Creators {
	public static function createBucket(spriteGfx:FlxGraphicAsset, x:Int, y:Int, width:Int, height:Int, bombProof:Bool = false):Array<FlxNapeSprite> {
		var wallThickness = 10;
		var left = new FlxNapeSprite();
		left.loadGraphic(spriteGfx);
		left.setPosition(x - width / 2 - wallThickness, y + height / 2);
		left.createRectangularBody(wallThickness, height);
		left.scale.set(wallThickness / 3, height / 3);
		left.body.type = BodyType.STATIC;
		left.body.cbTypes.add(CbTypes.CB_TERRAIN);

		var right = new FlxNapeSprite();
		right.loadGraphic(spriteGfx);
		right.setPosition(x + width / 2, y + height / 2);
		right.createRectangularBody(wallThickness, height);
		right.scale.set(wallThickness / 3, height / 3);
		right.body.type = BodyType.STATIC;
		right.body.cbTypes.add(CbTypes.CB_TERRAIN);

		var bottom = new FlxNapeSprite();
		bottom.loadGraphic(spriteGfx);
		bottom.setPosition(x, y + height);
		bottom.createRectangularBody(width, wallThickness);
		bottom.scale.set(width / 3, wallThickness / 3);
		bottom.body.type = BodyType.STATIC;
		bottom.body.cbTypes.add(CbTypes.CB_TERRAIN);

		if (bombProof) {
			left.body.cbTypes.add(CbTypes.CB_BOMB);
			right.body.cbTypes.add(CbTypes.CB_BOMB);
			bottom.body.cbTypes.add(CbTypes.CB_BOMB);
		}

		var pieces = [left, bottom, right];

		for (p in pieces) {
			for (s in p.body.shapes) {
				s.material = Material.wood();
			}
		}

		return pieces;
	}

	public static function makeBlock(x:Float, y:Float, width:Float, height:Float) {
		var testBlock = new FlxNapeSprite();
		testBlock.loadGraphic(AssetPaths.debug_square_blue__png);
		testBlock.setPosition(x, y);
		testBlock.createRectangularBody(width, height);
		testBlock.scale.set(width / 3, height / 3);
		testBlock.body.type = BodyType.STATIC;
		testBlock.body.setShapeFilters(new InteractionFilter(CGroups.TERRAIN));
		return testBlock;
	}
}
