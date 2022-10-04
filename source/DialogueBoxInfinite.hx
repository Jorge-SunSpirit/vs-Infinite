package;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef InfiniteDialogueFile =
{
	var dialogue:Array<InfiniteDialogueLine>;
}

typedef InfiniteDialogueLine =
{
	var character:Null<String>; // Should be uppercase (ex. Infinite), will be used visually
	var expression:Null<String>;
	var text:Null<String>;
	var sound:Null<String>; // Used for the voice clips (if we're proceeding with that)
}

class DialogueBoxInfinite extends FlxSpriteGroup
{
	var box:FlxSprite;
	var characterPortrait:FlxSprite;
	var characterName:FlxText;
	var dialogueText:FlxTypeText;
	var dialogueVoice:FlxSound;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	public function new(dialogueList:InfiniteDialogueFile)
	{
		super();

		box = new FlxSprite(151, 460).loadGraphic(Paths.image('textbox'));
		box.setGraphicSize(Std.int(box.width / 1.5)); // 1080p -> 720p
		box.updateHitbox();
		box.antialiasing = ClientPrefs.globalAntialiasing;
		add(box);

		/*
		characterPortrait = new FlxSprite(-20, 40);
		characterPortrait.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
		characterPortrait.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
		characterPortrait.setGraphicSize(Std.int(characterPortrait.width * 0.9));
		characterPortrait.updateHitbox();
		characterPortrait.scrollFactor.set();
		add(characterPortrait);
		characterPortrait.visible = false;
		*/

		// needs positioning and right alignment
		characterName = new FlxText(1044, 616, "Infinite", 20);
		characterName.font = Paths.font("futura.otf");
		characterName.antialiasing = ClientPrefs.globalAntialiasing;
		add(characterName);

		// needs positioning
		dialogueText = new FlxTypeText(0, 0, 0, "soap shoes mf", 32);
		dialogueText.font = Paths.font("futura.otf");
		dialogueText.antialiasing = ClientPrefs.globalAntialiasing;
		add(dialogueText);
	}

	override function update(elapsed:Float)
	{
		if (PlayerSettings.player1.controls.ACCEPT)
		{
			finishThing();
			kill();
		}

		super.update(elapsed);
	}

	public static function parseDialogue(path:String):InfiniteDialogueFile
	{
		return cast Json.parse(Assets.getText(path));
	}
}
