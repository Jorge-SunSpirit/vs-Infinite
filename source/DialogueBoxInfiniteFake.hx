package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.utils.Assets;
import DialogueBoxInfinite;

using StringTools;

class DialogueBoxInfiniteFake extends FlxSpriteGroup
{
	var dialogueData:InfiniteDialogueFile;

	var box:FlxSprite;
	var characterPortrait:FlxSprite;
	var characterName:FlxText;
	var dialogueText:FlxTypeText;
	var dialogueVoice:FlxSound;

	public var finishThing:Void->Void = null;

	var currentDialogue:Int = 0;

	public function new(dialogueData:InfiniteDialogueFile)
	{
		super();

		this.dialogueData = dialogueData;

		box = new FlxSprite().loadGraphic(Paths.image('dialogue/fake/textbox'));
		box.antialiasing = ClientPrefs.globalAntialiasing;
		add(box);

		characterPortrait = new FlxSprite(145, 93).loadGraphic(Paths.image('dialogue/fake/portrait/Fumo_Normal'));
		characterPortrait.antialiasing = ClientPrefs.globalAntialiasing;
		characterPortrait.visible = false;
		add(characterPortrait);

		characterName = new FlxText(566, 606, "", 36);
		characterName.font = Paths.font("futura.otf");
		characterName.antialiasing = ClientPrefs.globalAntialiasing;
		add(characterName);

		dialogueText = new FlxTypeText(567, 151, 548, "", 26);
		dialogueText.font = Paths.font("futura.otf");
		dialogueText.antialiasing = ClientPrefs.globalAntialiasing;
		add(dialogueText);

		startDialogue();
	}

	var allowInput:Bool = true;

	// Because this will be handled via events, here's a function solely for advancing text.
	public function advanceDialogue():Void
	{
		if (!allowInput)
			return;

		dialogueText.skip();
		if (dialogueData.dialogue[currentDialogue] != null)
		{
			if (dialogueData.dialogue[currentDialogue].sound == '')
				FlxG.sound.play(Paths.sound('scrollMenu'));

			startDialogue();
		}
		else
		{
			closeDialogue();
		}
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

		characterPortrait.loadGraphic(Paths.image('dialogue/fake/portrait/${curDialogue.character}_${curDialogue.expression}'));
		characterPortrait.visible = true;

		switch (curDialogue.character.toLowerCase())
		{
			default:
				characterPortrait.visible = false;
			case 'sonic' | 'infinite':
				// nothing
		}

		dialogueEnded = false;

		currentDialogue++;
	}

	function killVoice():Void
	{
		if (dialogueVoice != null)
		{
			dialogueVoice.stop();
			dialogueVoice.destroy();
		}
	}

	public function closeDialogue():Void
	{
		allowInput = false;
		killVoice();
		finishThing();
		kill();
	}
}
