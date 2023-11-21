package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var disclaimer:FlxSprite;

	override function create()
	{
		super.create();

		disclaimer = new FlxSprite().loadGraphic(Paths.image('VSInfiniteWARNING'));
		disclaimer.antialiasing = ClientPrefs.globalAntialiasing;
		disclaimer.setGraphicSize(FlxG.width, FlxG.height);
		disclaimer.screenCenter();
		add(disclaimer);
	}

	override function update(elapsed:Float)
	{
		if (!leftState)
		{
			var back:Bool = controls.BACK;

			if (controls.ACCEPT || back)
			{
				leftState = true;

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				if (!back)
				{
					ClientPrefs.flashing = false;
					ClientPrefs.saveSettings();
				}

				FlxG.sound.play(Paths.sound('confirmMenu'));

				FlxTween.tween(disclaimer, {alpha: 0}, 1.5,
				{
					onComplete: function (twn:FlxTween)
					{
						MusicBeatState.switchState(new TitleState());
					}
				});
			}
		}

		super.update(elapsed);
	}
}
