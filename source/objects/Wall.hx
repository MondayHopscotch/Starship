package objects;

import constants.CbTypes;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import nape.geom.Vec2;
import nape.phys.BodyType;

using extensions.FlxObjectExt;

class Wall extends FlxTypedGroup<FlxNapeSprite> {
	var top:FlxNapeSprite;
	var hatch:FlxNapeSprite;

	var hatchOriginalPos:Vec2;

	var bottom:FlxNapeSprite;

	var rando:FlxRandom = new FlxRandom(100);

	var knob:Towable = null;
	var knobLife:Float = 20.0;

	var maxImpulseDamage:Float = 8;

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
		hatch.body.type = BodyType.KINEMATIC;

		hatchOriginalPos = new Vec2().set(hatch.body.position);

		knob = new Towable();
		var knobRadius = 10;

		knob.loadGraphic(AssetPaths.shot__png);
		knob.scale.set(knobRadius * 2 / 32, knobRadius * 2 / 32);

		knob.setMidpoint(x + knobRadius * 2, segmentHeight + hatchHeight / 2);
		knob.createCircularBody(knobRadius);
		knob.body.type = BodyType.STATIC;
		knob.body.userData.data = knob;

		knob.body.cbTypes.add(CbTypes.CB_CARGO);

		add(knob);
	}

	override public function update(delta:Float) {
		super.update(delta);

		FlxG.watch.addQuick("Hatch life: ", knobLife);

		if (knob.body.totalImpulse().length > 0) {
			hatch.body.position.setxy(hatchOriginalPos.x + rando.float(-5, 5), hatchOriginalPos.y + rando.float(-5, 5));
			knobLife -= Math.max(maxImpulseDamage, knob.body.totalImpulse().length) * delta;
			if (knobLife <= 0) {
				knob.activeJoint.active = false;
				knob.kill();
				hatch.kill();
			}
		} else {
			hatch.body.position.set(hatchOriginalPos);
		}
	}
}
