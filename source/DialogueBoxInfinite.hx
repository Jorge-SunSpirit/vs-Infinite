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
	var dialogueData:InfiniteDialogueFile = null;

	var box:FlxSprite;
	var characterPortrait:FlxSprite;
	var characterName:FlxText;
	var dialogueText:FlxTypeText;
	var dialogueVoice:FlxSound;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var currentDialogue:Int = 0;

	public function new(dialogueData:InfiniteDialogueFile)
	{
		super();

		this.dialogueData = dialogueData;

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

		characterName = new FlxText(1044, 616, "", 20);
		characterName.font = Paths.font("futura.otf");
		characterName.antialiasing = ClientPrefs.globalAntialiasing;
		add(characterName);

		dialogueText = new FlxTypeText(340, 504, 776, "", 24);
		dialogueText.font = Paths.font("futura.otf");
		dialogueText.antialiasing = ClientPrefs.globalAntialiasing;
		add(dialogueText);

		startDialogue();
	}

	override function update(elapsed:Float)
	{
		if (PlayerSettings.player1.controls.ACCEPT)
		{
			if (dialogueData.dialogue[currentDialogue] != null)
			{
				startDialogue();
			}
			else
			{
				finishThing();
				kill();
			}
		}

		super.update(elapsed);
	}

	public static function parseDialogue(path:String):InfiniteDialogueFile
	{
		return cast Json.parse(Assets.getText(path));
	}

	var dialogueEnded:Bool = false;

	function startDialogue():Void
	{
		var curDialogue:InfiniteDialogueLine = null;
		do
		{
			curDialogue = dialogueData.dialogue[currentDialogue];
		}
		while (curDialogue == null);

		if (curDialogue.character == null || curDialogue.character.length < 1)
			curDialogue.character = '';
		if (curDialogue.text == null || curDialogue.text.length < 1)
			curDialogue.text = '';

		characterName.text = curDialogue.character;

		dialogueText.resetText(curDialogue.text);
		dialogueText.start(0.04, true);
		dialogueText.completeCallback = function()
		{
			dialogueEnded = true;
		};

		dialogueEnded = false; 

		currentDialogue++;

		if (nextDialogueThing != null)
		{
			nextDialogueThing();
		}
	}
}
