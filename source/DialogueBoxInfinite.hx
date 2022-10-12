package;

import flixel.FlxG;
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
	var character:Null<String>; // Should be capitalized (ex. Infinite)
	var expression:Null<String>;
	var text:Null<String>;
	var sound:Null<String>; // Used for the voice clips
}

class DialogueBoxInfinite extends FlxSpriteGroup
{
	var dialogueData:InfiniteDialogueFile;

	var box:FlxSprite;
	var characterPortrait:FlxSprite;
	var characterName:FlxText;
	var dialogueText:FlxTypeText;
	var dialogueVoice:FlxSound;

	public var finishThing:Void->Void = null;
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

		characterPortrait = new FlxSprite(179, 489).loadGraphic(Paths.image('dialogue/temp'));
		characterPortrait.setGraphicSize(Std.int(characterPortrait.width / 1.5)); // 1080p -> 720p
		characterPortrait.updateHitbox();
		characterPortrait.antialiasing = ClientPrefs.globalAntialiasing;
		characterPortrait.visible = false;
		add(characterPortrait);

		characterName = new FlxText(1044, 616, "", 20);
		characterName.font = Paths.font("futura.otf");
		characterName.antialiasing = ClientPrefs.globalAntialiasing;
		add(characterName);

		dialogueText = new FlxTypeText(340, 504, 776, "", 24);
		dialogueText.font = Paths.font("futura.otf");
		dialogueText.antialiasing = ClientPrefs.globalAntialiasing;
		add(dialogueText);

		FlxG.sound.play(Paths.sound('radioDialogue'), function()
		{
			startDialogue();
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PlayerSettings.player1.controls.ACCEPT)
		{
			if (!dialogueEnded)
			{
				dialogueText.skip();

				if (skipDialogueThing != null)
					skipDialogueThing();
			}
			else
			{
				if (dialogueData.dialogue[currentDialogue] != null)
				{
					if (dialogueData.dialogue[currentDialogue].sound == '')
						FlxG.sound.play(Paths.sound('scrollMenu'));

					startDialogue();
				}
				else
				{
					killVoice();
					finishThing();
					kill();
				}
			}
		}
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
		if (curDialogue.expression == null || curDialogue.expression.length < 1)
			curDialogue.expression = '';
		if (curDialogue.text == null || curDialogue.text.length < 1)
			curDialogue.text = '';
		if (curDialogue.sound == null || curDialogue.sound.length < 1)
			curDialogue.sound = '';

		characterName.text = curDialogue.character;

		dialogueText.resetText(curDialogue.text);
		dialogueText.start(0.04, true);
		dialogueText.completeCallback = function()
		{
			dialogueEnded = true;
		};

		killVoice();

		if (curDialogue.sound != '')
			dialogueVoice = new FlxSound().loadEmbedded(Paths.sound('dialogue/${curDialogue.sound}'));
		else
			dialogueVoice = new FlxSound();

		dialogueVoice.play();

		characterPortrait.loadGraphic(Paths.image('dialogue/${curDialogue.character}_${curDialogue.expression}'));
		characterPortrait.visible = true;

		dialogueEnded = false; 

		currentDialogue++;

		if (nextDialogueThing != null)
			nextDialogueThing();
	}

	function killVoice()
	{
		if (dialogueVoice != null)
		{
			dialogueVoice.stop();
			dialogueVoice.destroy();
		}
	}
}
