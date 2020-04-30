package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.ui.FlxButton;

class BackableState extends FlxState {
	override public function create() {
		var backBtn = new FlxButton(FlxG.width - 100, 0, "Back", () -> FlxG.switchState(new MainMenuState()));
		add(backBtn);
	}
}
