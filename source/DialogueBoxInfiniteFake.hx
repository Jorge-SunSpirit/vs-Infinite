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

	var currentDialogue:Int = 0;

	public var finishThing:Void->Void = null;

	public function new(dialogueData:InfiniteDialogueFile)
	{
		super();

		this.dialogueData = dialogueData;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x77000000);
		add(bg);

		box = new FlxSprite(151, 460).loadGraphic(Paths.image('textbox'));
		box.setGraphicSize(Std.int(box.width / 1.5)); // 1080p -> 720p
		box.updateHitbox();
		box.antialiasing = ClientPrefs.globalAntialiasing;
		add(box);

		characterPortrait = new FlxSprite().loadGraphic(Paths.image('dialogue/Fumo_Normal'));
		characterPortrait.antialiasing = ClientPrefs.globalAntialiasing;
		characterPortrait.visible = false;
		add(characterPortrait);

		characterName = new FlxText(1044, 616, "", 20);
		characterName.font = Paths.font("futura.otf");
		characterName.antialiasing = ClientPrefs.globalAntialiasing;
		add(characterName);

		dialogueText = new FlxTypeText(340, 504, 776, "");
		dialogueText.setFormat(Paths.font("futura.otf"), 24, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF181818);
		dialogueText.borderSize = 1.5;
		dialogueText.antialiasing = ClientPrefs.globalAntialiasing;
		add(dialogueText);

		FlxG.sound.play(Paths.sound('radioDialogue'), function()
		{
			startDialogue();
		});
	}

	// Because this will be handled via events, here's a function solely for advancing text.
	public function advanceDialogue():Void
	{
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

		characterPortrait.loadGraphic(Paths.image('dialogue/${curDialogue.character}_${curDialogue.expression}'));
		characterPortrait.visible = true;

		switch (curDialogue.character.toLowerCase())
		{
			default:
				characterPortrait.visible = false;
			case 'infinite':
				characterPortrait.scale.set(0.395, 0.395);
				characterPortrait.setPosition(-474, -329);
			case 'sonic':
				characterPortrait.scale.set(0.399, 0.399);
				characterPortrait.setPosition(-405, -160);
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
		FlxG.sound.play(Paths.sound('cancelMenu'));

		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			killVoice();
			finishThing();
			kill();
		});
	}
}
