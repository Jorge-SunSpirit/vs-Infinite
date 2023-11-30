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
import openfl.filters.ColorMatrixFilter;
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
	var number:Null<Float>; // Used for any command that uses a float
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
	var advanceText:FlxText;

	public var finishThing:Void->Void = null;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var currentDialogue:Int = 0;

	public function new(dialogueData:InfiniteDialogueFile):Void
	{
		super();

		this.dialogueData = dialogueData;

		var dark = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x77000000);
		add(dark);

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x00000000);
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		box = new FlxSprite(151, 460).loadGraphic(Paths.image('dialogue/normal/textbox'));
		box.setGraphicSize(Std.int(box.width / 1.5)); // 1080p -> 720p
		box.updateHitbox();
		box.antialiasing = ClientPrefs.globalAntialiasing;
		add(box);

		characterPortrait = new FlxSprite().loadGraphic(Paths.image('dialogue/normal/portrait/Fumo_Normal'));
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

		advanceText = new FlxText(0, 670, "Press ENTER to continue.", 20);
		advanceText.antialiasing = ClientPrefs.globalAntialiasing;
		advanceText.setBorderStyle(OUTLINE, 0xFF181818, 1.5);
		advanceText.font = Paths.font("futura.otf");
		advanceText.screenCenter(X);
		advanceText.alpha = 0;
		add(advanceText);

		startDialogue();
	}

	var allowInput:Bool = true;
	var allowUpdate:Bool = true;

	override function update(elapsed:Float):Void
	{
		if (!allowUpdate)
			return;

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
	var playClose:Bool = true;
	var centerMode:Bool = false;

	function startDialogue():Void
	{
		if (!allowUpdate)
			return;

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

		FlxTween.cancelTweensOf(advanceText);
		advanceText.alpha = 0;

		if (curDialogue.command == '')
		{
			allowInput = true;

			characterName.text = curDialogue.character;

			dialogueText.resetText(curDialogue.text);
			dialogueText.start(0.04, true);
			dialogueText.completeCallback = function()
			{
				dialogueEnded = true;
				if (curDialogue.sound == '') FlxTween.tween(advanceText, {alpha: 1}, 0.5, {ease: FlxEase.linear, startDelay: 0.5});
			};

			if (curDialogue.sound != '')
			{
				dialogueVoice = new FlxSound().loadEmbedded(Paths.sound('dialogue/${Paths.formatToSongPath(PlayState.SONG.song)}/${curDialogue.sound}'));
				dialogueVoice.onComplete = function()
				{
					FlxTween.tween(advanceText, {alpha: 1}, 0.5, {ease: FlxEase.linear, startDelay: 0.5});
				};
			}
			else
			{
				dialogueVoice = new FlxSound();
			}

			dialogueVoice.play();

			if (!centerMode)
			{
				characterPortrait.loadGraphic(Paths.image('dialogue/normal/portrait/${curDialogue.character}_${curDialogue.expression}'));
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
			}

			dialogueEnded = false;
		}
		else
		{
			allowInput = false;

			switch (curDialogue.command.toLowerCase())
			{
				default:
				{
					// Invalid command, immediately end incase this is an older build playing newer commands so we don't softlock
					endDialogue();
				}
				case 'playmusic':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1;

					FlxG.sound.playMusic(Paths.music(curDialogue.text), curDialogue.number);
					endDialogue();
				}
				case 'pausemusic':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1;

					FlxG.sound.music.fadeOut(curDialogue.number, 0, function(twn:FlxTween)
					{
						FlxG.sound.music.pause();
						endDialogue();
					});
				}
				case 'pausemusic2':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1;

					FlxG.sound.music.fadeOut(curDialogue.number, 0, function(twn:FlxTween)
					{
						FlxG.sound.music.pause();
					});

					endDialogue();
				}
				case 'resumemusic':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1;

					FlxG.sound.music.play();
					FlxG.sound.music.fadeIn(curDialogue.number);
					endDialogue();
				}
				case 'stopmusic':
				{
					FlxG.sound.music.stop();
					endDialogue();
				}
				case 'bg':
				{
					bg.loadGraphic(Paths.image('dialogue/normal/bg/${curDialogue.text}'));
					bg.setGraphicSize(FlxG.width);
					bg.updateHitbox();
					bg.screenCenter();
					endDialogue();
				}
				case 'bgfadein':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1.5;

					FlxTween.tween(bg, {alpha: 1}, curDialogue.number, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							endDialogue();
						}
					});
				}
				case 'bgfadeout':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1.5;

					FlxTween.tween(bg, {alpha: 0}, curDialogue.number, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							endDialogue();
						}
					});
				}
				case 'fadein':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1.5;

					PlayState.instance.camOther2.fade(0xFF000000, curDialogue.number, true, function()
					{
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							endDialogue();
						});
					});
				}
				case 'fadeout':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1.5;

					FlxG.sound.music.fadeOut(curDialogue.number, 0);
					PlayState.instance.camOther2.fade(0xFF000000, curDialogue.number, false, function()
					{
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							endDialogue();
						});
					});
				}
				case 'fadeout2':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1.5;

					PlayState.instance.camOther2.fade(0xFF000000, curDialogue.number, false, function()
					{
						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							endDialogue();
						});
					});
				}
				case 'flash':
				{
					if (curDialogue.number == null)
						curDialogue.number = 0.4;

					PlayState.instance.camOther2.fade(0xFFFFFFFF, curDialogue.number, true, function()
					{
						endDialogue();
					});
				}
				case 'rubystart':
				{
					PlayState.instance.camOther2.setFilters([new ColorMatrixFilter([1, -1, -1, 0, 255, -1, 1, -1, 0, 255, -1, -1, 1, 0, 255, 0, 0, 0, 1, 0])]);
					PlayState.instance.camOther2.fade(0xFF000000, 0.4, true);
					FlxG.sound.play(Paths.sound('rubyActivate'), function()
					{
						endDialogue();
					});
				}
				case 'rubyend':
				{
					FlxG.sound.play(Paths.soundRandom('rubyAttack', 1, 6));
					PlayState.instance.camOther2.setFilters(null);
					PlayState.instance.camOther2.fade(0xFFFFFFFF, 0.4, true, function()
					{
						endDialogue();
					});
				}
				case 'center':
				{
					centerMode = true;
					box.visible = false;
					characterPortrait.visible = false;
					characterName.visible = false;
					dialogueText.fieldWidth = FlxG.width;
					dialogueText.screenCenter();
					dialogueText.setFormat(Paths.font("futura.otf"), 24, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
					endDialogue();
				}
				case 'normal':
				{
					centerMode = false;
					box.visible = true;
					characterPortrait.visible = true;
					characterName.visible = true;
					dialogueText.fieldWidth = 776;
					dialogueText.setPosition(340, 504);
					dialogueText.setFormat(Paths.font("futura.otf"), 24, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF181818);
					dialogueText.visible = true;
					endDialogue();
				}
				case 'hidetext':
				{
					dialogueText.visible = false;
					endDialogue();
				}
				case 'showtext':
				{
					dialogueText.visible = true;
					endDialogue();
				}
				case 'playsound':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1;

					FlxG.sound.play(Paths.sound(curDialogue.sound), curDialogue.number, function()
					{
						endDialogue();
					});
				}
				case 'playsound2':
				{
					if (curDialogue.number == null)
						curDialogue.number = 1;

					FlxG.sound.play(Paths.sound(curDialogue.sound), curDialogue.number);
					endDialogue();
				}
				case 'noclosesfx':
				{
					playClose = false;
					endDialogue();
				}
				case 'timer':
				{
					if (curDialogue.number == null)
						curDialogue.number = 0;

					new FlxTimer().start(curDialogue.number, function(tmr:FlxTimer)
					{
						endDialogue();
					});
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

	inline function killVoice():Void
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

		if (playClose)
			FlxG.sound.play(Paths.sound('cancelMenu'));

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 4, 0);

		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			PlayState.instance.camOther2.fade(0xFF000000, 0, true, null, true);
			PlayState.instance.camOther2.setFilters(null);
			allowUpdate = false;
			killVoice();
			finishThing();
			kill();
		});
	}
}
