package objects;

import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;
import flixel.group.FlxGroup;
import nape.phys.BodyType;

class Wall extends FlxTypedGroup<FlxNapeSprite> {
	var top:FlxNapeSprite;
	var hatch:FlxNapeSprite;
	var bottom:FlxNapeSprite;

	public function new(x:Int) {
		super();

		var segmentHeight = FlxG.height / 2 - 50;
		top = new FlxNapeSprite();
		top.loadGraphic(AssetPaths.debug_square_blue__png);
		top.setPosition(x, segmentHeight / 2);
		top.createRectangularBody(10, segmentHeight);
		top.scale.set(10 / 3, segmentHeight / 3);
		top.body.type = BodyType.STATIC;
		add(top);

		bottom = new FlxNapeSprite();
		bottom.loadGraphic(AssetPaths.debug_square_blue__png);
		bottom.setPosition(x, FlxG.height - segmentHeight / 2);
		bottom.createRectangularBody(10, segmentHeight);
		bottom.scale.set(10 / 3, segmentHeight / 3);
		bottom.body.type = BodyType.STATIC;
		add(bottom);

		var hatchHeight = FlxG.height - 2 * segmentHeight;
		hatch = new FlxNapeSprite();
		hatch.loadGraphic(AssetPaths.debug_square_red__png);
		hatch.setPosition(x, segmentHeight + hatchHeight / 2);
		hatch.createRectangularBody(10, hatchHeight);
		hatch.scale.set(10 / 3, hatchHeight / 3);
		hatch.body.type = BodyType.STATIC;
	}
}
