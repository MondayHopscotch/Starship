package objects;

import constants.CbTypes;
import constants.CollisionGroups;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import nape.constraint.Constraint;
import nape.constraint.DistanceJoint;
import nape.constraint.LineJoint;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.BodyType;

using extensions.FlxObjectExt;

class Wall extends FlxTypedGroup<FlxNapeSprite> {
	var top:FlxNapeSprite;
	var topHatch:FlxNapeSprite;
	var bottomHatch:FlxNapeSprite;

	var hatchOriginalPos:Vec2;
	var knobOriginalPos:Vec2;

	var joints:Array<Constraint>;

	var bottom:FlxNapeSprite;

	var rando:FlxRandom = new FlxRandom(100);

	var knob:Towable = null;
	var knobWorldJoint:PivotJoint;

	var knobMaxLife:Float = 10.0;
	var knobLife:Float = 10.0;
	var restoreRate:Float = 5;

	var knobFlex:Float = 20;

	var maxImpulseDamage:Float = 100;

	public function new(x:Int) {
		super();

		joints = new Array<Constraint>();

		var segmentHeight = FlxG.height / 2 - 50;
		top = new FlxNapeSprite();
		top.loadGraphic(AssetPaths.debug_square_blue__png);
		top.setPosition(x, segmentHeight / 2);
		top.createRectangularBody(10, segmentHeight);
		top.scale.set(10 / 3, segmentHeight / 3);
		top.body.type = BodyType.STATIC;
		top.body.setShapeFilters(new InteractionFilter(CollisionGroups.TERRAIN));
		add(top);

		bottom = new FlxNapeSprite();
		bottom.loadGraphic(AssetPaths.debug_square_blue__png);
		bottom.setPosition(x, FlxG.height - segmentHeight / 2);
		bottom.createRectangularBody(10, segmentHeight);
		bottom.scale.set(10 / 3, segmentHeight / 3);
		bottom.body.type = BodyType.STATIC;
		bottom.body.setShapeFilters(new InteractionFilter(CollisionGroups.TERRAIN));
		add(bottom);

		var gateHeight = FlxG.height - 2 * segmentHeight;
		var hatchHeight = gateHeight / 2;
		topHatch = new FlxNapeSprite();
		topHatch.loadGraphic(AssetPaths.debug_square_red__png);
		topHatch.setPosition(x, segmentHeight + hatchHeight / 2);
		topHatch.createRectangularBody(10, hatchHeight);
		topHatch.scale.set(10 / 3, hatchHeight / 3);
		topHatch.body.type = BodyType.DYNAMIC;
		topHatch.body.setShapeFilters(new InteractionFilter((CollisionGroups.SHIP | CollisionGroups.CARGO), ~(CollisionGroups.TERRAIN)));

		bottomHatch = new FlxNapeSprite();
		bottomHatch.loadGraphic(AssetPaths.debug_square_red__png);
		bottomHatch.setPosition(x, segmentHeight + hatchHeight + hatchHeight / 2);
		bottomHatch.createRectangularBody(10, hatchHeight);
		bottomHatch.scale.set(10 / 3, hatchHeight / 3);
		bottomHatch.body.type = BodyType.DYNAMIC;
		bottomHatch.body.setShapeFilters(new InteractionFilter((CollisionGroups.SHIP | CollisionGroups.CARGO), ~(CollisionGroups.TERRAIN)));

		var topPivot = Vec2.get(x - 5, segmentHeight);

		var topHatchJoint = new PivotJoint(top.body, topHatch.body, top.body.worldPointToLocal(topPivot, true),
			topHatch.body.worldPointToLocal(topPivot, true));
		topHatchJoint.space = FlxNapeSpace.space;
		joints.push(topHatchJoint);

		var bottomPivot = Vec2.get(x - 5, FlxG.height - segmentHeight);

		var bottomHatchJoint = new PivotJoint(bottom.body, bottomHatch.body, bottom.body.worldPointToLocal(bottomPivot),
			bottomHatch.body.worldPointToLocal(bottomPivot));
		bottomHatchJoint.space = FlxNapeSpace.space;
		joints.push(bottomHatchJoint);

		knob = new Towable();
		var knobRadius = 10;

		var knobPosition = Vec2.get(x - 5, segmentHeight + hatchHeight);

		knob.loadGraphic(AssetPaths.shot__png);
		knob.scale.set(knobRadius * 2 / 32, knobRadius * 2 / 32);
		knob.createCircularBody(knobRadius);
		knob.body.userData.data = knob;
		knob.body.position.set(knobPosition);
		knob.body.type = BodyType.DYNAMIC;
		knob.body.shapes.at(0).sensorEnabled = true;

		knobOriginalPos = new Vec2().set(knob.body.position);

		knob.set();

		var knobJointPos = Vec2.get(x - 5, segmentHeight + hatchHeight);

		var knobTopJoint = new LineJoint(knob.body, topHatch.body, knob.body.worldPointToLocal(knobJointPos, true),
			topHatch.body.worldPointToLocal(knobJointPos, true), Vec2.weak(0, -1), -30, 30);
		knobTopJoint.stiff = false;
		knobTopJoint.space = FlxNapeSpace.space;
		joints.push(knobTopJoint);

		var knobBottomJoint = new LineJoint(knob.body, bottomHatch.body, knob.body.worldPointToLocal(knobJointPos, true),
			bottomHatch.body.worldPointToLocal(knobJointPos, true), Vec2.weak(0, 1), -30, 30);
		knobBottomJoint.stiff = false;
		knobBottomJoint.space = FlxNapeSpace.space;
		joints.push(knobBottomJoint);

		knobWorldJoint = new PivotJoint(FlxNapeSpace.space.world, knob.body, knob.body.position, Vec2.weak());
		knobWorldJoint.space = FlxNapeSpace.space;
		joints.push(knobWorldJoint);

		add(knob);
	}

	override public function update(delta:Float) {
		super.update(delta);

		FlxG.watch.addQuick("Hatch life: ", knobLife);

		if (knob.alive) {
			var offsetAmount = Vec2.weak().setxy(-knobFlex, 0).mul(1 - (knobLife / knobMaxLife));
			FlxG.watch.addQuick("Knob offset: ", offsetAmount);
			knobWorldJoint.anchor1.set(Vec2.weak().set(knobOriginalPos).add(offsetAmount));
		}

		if (knob.activeJoint != null) {
			FlxG.watch.addQuick("Knob regen: ", false);
			if (knob.activeJoint.body1 == knob.body || knob.activeJoint.body2 == knob.body) {
				FlxG.watch.addQuick("Knob joint imp: ", knob.activeJoint.bodyImpulse(knob.body));

				knobLife -= Math.min(maxImpulseDamage, knob.activeJoint.bodyImpulse(knob.body).length) * delta;
			}

			if (knobLife <= 0) {
				knob.activeJoint.active = false;
				for (c in joints) {
					c.active = false;
				}
				knob.kill();
				topHatch.kill();
				bottomHatch.kill();
			}
		}

		if (knobLife < knobMaxLife) {
			FlxG.watch.addQuick("Knob regen: ", true);
			knobLife += restoreRate * delta;
		} else {
			topHatch.body.rotation = 0;
			bottomHatch.body.rotation = 0;
		}
	}
}
