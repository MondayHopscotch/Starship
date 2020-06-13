package states;

import constants.CbTypes;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.ui.FlxButton;
import nape.geom.Vec2;

class BackableState extends FlxState {
	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, CompileTime.parseJsonFile("assets/config/environment.json").gravity.y);

	override public function create() {
		var backBtn = new FlxButton(FlxG.width - 100, 0, "Back", () -> FlxG.switchState(new MainMenuState()));
		add(backBtn);

		CbTypes.initTypes();
		FlxNapeSpace.init();
		// FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.space.gravity.set(gravity);
	}
}
