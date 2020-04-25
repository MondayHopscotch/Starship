package;

import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import states.CargoState;
import states.DestructableObjects;
import states.MainMenuState;

class Main extends Sprite {
	public function new() {
		super();
		addChild(new FlxGame(0, 0, MainMenuState, 1, 60, 60, true, false));
	}
}
