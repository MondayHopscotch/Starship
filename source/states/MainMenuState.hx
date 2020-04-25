package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class MainMenuState extends FlxState {
	var _btnPlay:FlxButton;
	var _btnWall:FlxButton;

	override public function create():Void {
		super.create();
		FlxG.debugger.visible = true;
		bgColor = FlxColor.TRANSPARENT;

		_btnPlay = new FlxButton(0, 0, "Cargo", () -> FlxG.switchState(new PlayState()));
		_btnPlay.updateHitbox();
		_btnPlay.screenCenter();
		add(_btnPlay);

		_btnWall = new FlxButton(0, 0, "Walls", () -> FlxG.switchState(new DestructableObjects()));
		_btnWall.updateHitbox();
		_btnWall.screenCenter();
		_btnWall.y += 30;
		add(_btnWall);
	}
}
