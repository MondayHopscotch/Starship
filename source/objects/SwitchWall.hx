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

class SwitchWall extends FlxTypedGroup<FlxNapeSprite> {
	var base:FlxNapeSprite;
	var knob:Towable;

	var wall:FlxNapeSprite;

	static var startAngle:Float = -Math.PI / 3 * 2;
	static var endAngle:Float = -Math.PI / 3;
	static var totalAngle:Float = startAngle - endAngle;

	var joints:Array<Constraint>;

	var switchMaxLife:Float = 10.0;
	var switchLife:Float = 10.0;
	var restoreRate:Float = 3;

	var maxImpulseDamage:Float = 100;

	public function new(x:Int, y:Int) {
		super();

		joints = new Array<Constraint>();

		var baseRadius:Float = 40;

		base = new FlxNapeSprite();
		base.createCircularBody(baseRadius);
		base.body.position.setxy(x, y);
		base.body.shapes.at(0).sensorEnabled = true;
		base.body.type = BodyType.KINEMATIC;
		add(base);

		var knobRadius = 10;

		knob = new Towable();
		knob.loadGraphic(AssetPaths.shot__png);
		knob.scale.set(knobRadius * 2 / 32, knobRadius * 2 / 32);
		knob.createCircularBody(knobRadius);
		knob.body.userData.data = knob;
		knob.body.position.set(Vec2.weak().set(base.body.position).add(Vec2.weak(baseRadius, 0)));
		knob.body.type = BodyType.DYNAMIC;
		knob.body.shapes.at(0).sensorEnabled = true;
		knob.set();
		add(knob);

		var knobJoint = new PivotJoint(base.body, knob.body, Vec2.weak(baseRadius, 0), Vec2.weak());
		knobJoint.stiff = false;
		knobJoint.space = FlxNapeSpace.space;
		joints.push(knobJoint);

		base.body.rotation = startAngle;
	}

	override public function update(delta:Float) {
		super.update(delta);

		FlxG.watch.addQuick("Switch percent: ", switchLife);

		if (knob.alive) {
			var offsetAmount = -totalAngle * (1 - (switchLife / switchMaxLife));
			FlxG.watch.addQuick("Switch offset: ", offsetAmount);
			base.body.rotation = startAngle + offsetAmount;
		}

		if (knob.activeJoint != null) {
			FlxG.watch.addQuick("Switch regen: ", false);
			if (knob.activeJoint.body1 == knob.body || knob.activeJoint.body2 == knob.body) {
				FlxG.watch.addQuick("Knob joint imp: ", knob.activeJoint.bodyImpulse(knob.body));

				switchLife -= Math.min(maxImpulseDamage, Math.abs(knob.activeJoint.bodyImpulse(knob.body).x)) * delta;
			}

			switchLife = Math.min(switchMaxLife, Math.max(0, switchLife));
		}

		if (switchLife < switchMaxLife) {
			switchLife += restoreRate * delta;
		}
	}
}
