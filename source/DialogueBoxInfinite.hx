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
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
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
	var command:Null<String>;
}

class DialogueBoxInfinite extends FlxSpriteGroup
{
	var dialogueData:InfiniteDialogueFile;

	var bg:FlxSprite;
	var box:FlxSprite;
	var characterPortrait:FlxSprite;
	var characterName:FlxText;
	var dialogueText:FlxTypeText;
	var dialogueVoice:FlxSound;

	public var finishThing:Void->Void = null;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var currentDialogue:Int = 0;

	public function new(dialogueData:InfiniteDialogueFile):Void
	{
		super();

		CoolUtil.precacheMusic('cutscene');

		this.dialogueData = dialogueData;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x77000000);
		bg.antialiasing = ClientPrefs.globalAntialiasing;
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
			FlxG.sound.playMusic(Paths.music('cutscene'), 1);
			startDialogue();
		});
	}

	var allowInput:Bool = true;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if debug
		var posVal:Array<Float> = [50, 10];
		var scaVal:Array<Float> = [0.05, 0.01];

		if (FlxG.keys.pressed.CONTROL && (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L || FlxG.keys.pressed.Q || FlxG.keys.pressed.E))
		{
			if (FlxG.keys.justPressed.I)
				characterPortrait.y -= FlxG.keys.pressed.SHIFT ? posVal[0] : posVal[1];
			else if (FlxG.keys.justPressed.K)
				characterPortrait.y += FlxG.keys.pressed.SHIFT ? posVal[0] : posVal[1];

			if (FlxG.keys.justPressed.J)
				characterPortrait.x -= FlxG.keys.pressed.SHIFT ? posVal[0] : posVal[1];
			else if (FlxG.keys.justPressed.L)
				characterPortrait.x += FlxG.keys.pressed.SHIFT ? posVal[0] : posVal[1];

			if (FlxG.keys.justPressed.Q)
			{
				characterPortrait.scale.x -= FlxG.keys.pressed.SHIFT ? scaVal[0] : scaVal[1];
				characterPortrait.scale.y -= FlxG.keys.pressed.SHIFT ? scaVal[0] : scaVal[1];
			}
			else if (FlxG.keys.justPressed.E)
			{
				characterPortrait.scale.x += FlxG.keys.pressed.SHIFT ? scaVal[0] : scaVal[1];
				characterPortrait.scale.y += FlxG.keys.pressed.SHIFT ? scaVal[0] : scaVal[1];
			}
		}

		FlxG.watch.addQuick("portrait pos", [characterPortrait.x, characterPortrait.y]);
		FlxG.watch.addQuick("portrait scale", [characterPortrait.scale.x]);
		#end

		if (allowInput)
		{
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
						closeDialogue();
					}
				}
			}
		}

		if (PlayerSettings.player1.controls.BACK)
			closeDialogue();
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
		if (curDialogue.command == null || curDialogue.command.length < 1)
			curDialogue.command = '';

		killVoice();

		currentDialogue++;

		if (nextDialogueThing != null)
			nextDialogueThing();

		if (curDialogue.command == '')
		{
			allowInput = true;

			characterName.text = curDialogue.character;

			dialogueText.resetText(curDialogue.text);
			dialogueText.start(0.04, true);
			dialogueText.completeCallback = function()
			{
				dialogueEnded = true;
			};

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
				case 'sonic' | 'tails':
					characterPortrait.scale.set(0.399, 0.399);
					characterPortrait.setPosition(-405, -160);
			}

			dialogueEnded = false;
		}
		else
		{
			allowInput = false;

			switch (curDialogue.command.toLowerCase())
			{
				case 'bg':
				{
					if (curDialogue.text.toLowerCase() == 'dark')
						bg.makeGraphic(FlxG.width, FlxG.height, 0x77000000);
					else
						bg.loadGraphic(Paths.image('dialogue/${curDialogue.text}'));

					endDialogue();
				}
				case 'fadein':
				{
					PlayState.instance.camHUD.fade(0xFF000000, 1.5, true, function()
					{
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							endDialogue();
						});
					});
				}
				case 'fadeout':
				{
					FlxG.sound.music.fadeOut(1.5, 0);
					PlayState.instance.camHUD.fade(0xFF000000, 1.5, false, function()
					{
						endDialogue();
					});
				}
				case 'flash':
				{
					PlayState.instance.camHUD.fade(0xFFFFFFFF, 0.5, true, function()
					{
						endDialogue();
					});
				}
				case 'center':
				{
					box.visible = false;
					characterPortrait.visible = false;
					characterName.visible = false;
					dialogueText.screenCenter();
					dialogueText.setFormat(Paths.font("futura.otf"), 24, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
					endDialogue();
				}
				case 'normal':
				{
					box.visible = true;
					characterPortrait.visible = true;
					characterName.visible = true;
					dialogueText.setPosition(340, 504);
					dialogueText.setFormat(Paths.font("futura.otf"), 24, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF181818);
					dialogueText.visible = true;
					endDialogue();
				}
			}
		}
	}

	function endDialogue():Void
	{
		dialogueEnded = true;
		dialogueText.skip();

		if (dialogueData.dialogue[currentDialogue] != null)
			startDialogue();
		else
			closeDialogue();
	}

	function killVoice():Void
	{
		if (dialogueVoice != null)
		{
			dialogueVoice.stop();
			dialogueVoice.destroy();
		}
	}

	function closeDialogue():Void
	{
		allowInput = false;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 4, 0);

		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			killVoice();
			finishThing();
			kill();
		});
	}
}
