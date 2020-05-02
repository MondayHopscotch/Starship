package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.addons.nape.FlxNapeSprite;
import nape.dynamics.InteractionFilter;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;

class ShipSensor extends SelfAssigningFlxNapeSprite {
	var follow:FlxNapeSprite;

	public function new(radius:Float, follow:FlxNapeSprite) {
		super();
		visible = false;

		this.follow = follow;

		var body = new Body(BodyType.DYNAMIC);
		var weightless = new Material(0, 1, 2, 0.00000001);
		var sensor = new Circle(radius);
		sensor.sensorEnabled = true;
		var filters = new InteractionFilter(CGroups.SHIP_SENSOR, CGroups.CARGO);
		body.setShapeFilters(filters);
		sensor.cbTypes.add(CbTypes.CB_SHIP_SENSOR_RANGE);
		sensor.body = body;

		addPremadeBody(body);
		body.shapes.foreach(s -> s.material = weightless);
		body.rotation = -Math.PI / 2;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		this.body.position.set(follow.body.position);
		this.body.rotation = follow.body.rotation;
	}
}
