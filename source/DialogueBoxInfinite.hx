package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

typedef DialogueFile =
{
	var dialogue:Array<DialogueLine>;
}

typedef DialogueLine =
{
	var character:Null<String>; // Should be uppercase (ex. Infinite), will be used visually
	var expression:Null<String>;
	var text:Null<String>;
	var speed:Null<Float>;
	var sound:Null<String>;
}

class DialogueBoxInfinite extends FlxSpriteGroup
{
	var box:FlxSprite;
	var characterPortrait:FlxSprite;
	var characterName:FlxText;
	var dialogueText:FlxTypeText;

	public function new(?dialogueData:DialogueFile)
	{
		super();

		box = new FlxSprite(151, 460).loadGraphic(Paths.image('textbox'));
		box.setGraphicSize(Std.int(box.width / 1.5)); // 1080p -> 720p
		box.updateHitbox();
		box.antialiasing = ClientPrefs.globalAntialiasing;
		add(box);

		// make use of psych json
		characterPortrait = new FlxSprite(-20, 40);
		characterPortrait.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
		characterPortrait.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
		characterPortrait.setGraphicSize(Std.int(characterPortrait.width * 0.9));
		characterPortrait.updateHitbox();
		characterPortrait.scrollFactor.set();
		add(characterPortrait);
		characterPortrait.visible = false;

		// needs positioning and right alignment
		characterName = new FlxText(240, 500, "Infinite", 32);
		characterName.font = Paths.font("futura.otf");
		add(characterName);

		// needs positioning
		dialogueText = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		dialogueText.font = Paths.font("futura.otf");
		dialogueText.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		add(dialogueText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
