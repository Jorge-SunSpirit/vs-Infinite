package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
#if desktop
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;
class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var tbdSpr:FlxSprite;
	var ngSpr:FlxSprite;
	var infinite:FlxSprite;
	var squid:FlxSound;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var mustUpdate:Bool = false;
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		squid = new FlxSound().loadEmbedded(Paths.sound("SQUID"));

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		#if CHECK_FOR_UPDATES
		if(!closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/main/gitVersion.txt");
			
			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}
			
			http.onError = function (error) {
				trace('error: $error');
			}
			
			http.request();
		}
		#end

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		super.create();

		FlxG.save.bind('VSInfinite', CoolUtil.getSavePath());
		
		ClientPrefs.loadPrefs();

		Highscore.load();	

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if DISCORD_ALLOWED
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add (function (exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end
	}

	var symbol:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		if (!initialized)
		{
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
		}

		Conductor.bpm = 102.0;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF1B1B1B);
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		symbol = new FlxSprite(-20, 5).loadGraphic(Paths.image('title/Infinite_Symbol'));
		symbol.antialiasing = ClientPrefs.globalAntialiasing;
		add(symbol);

		var tightBarTop:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 48, FlxColor.BLACK);
		tightBarTop.antialiasing = ClientPrefs.globalAntialiasing;
		add(tightBarTop);

		var logo = new FlxSprite().loadGraphic(Paths.image('title/VS_Infinite_Logo'));
		logo.scale.set(0.6, 0.6);
		logo.updateHitbox();
		logo.setPosition(80, 100);
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		add(logo);

		infinite = new FlxSprite(620, -40);
		infinite.frames = Paths.getSparrowAtlas('title/Infinite_Title_Bumpin');
		infinite.animation.addByPrefix('bump', "Infinite_Title_Bumpin", 24, false);
		infinite.antialiasing = ClientPrefs.globalAntialiasing;
		infinite.animation.play('bump');
		add(infinite);

		var tightBarBottom:FlxSprite = new FlxSprite(0, FlxG.height - 48).makeGraphic(FlxG.width, 48, FlxColor.BLACK);
		tightBarBottom.antialiasing = ClientPrefs.globalAntialiasing;
		add(tightBarBottom);

		var segaTxt = new FlxText(52, 682, 0, "ORIGINAL GAME ©SEGA");
		segaTxt.setFormat(Paths.font("gothic.ttf"), 12, FlxColor.WHITE, LEFT);
		segaTxt.scrollFactor.set();
		segaTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(segaTxt);

		var tbdTxt = new FlxText(1158, 682, 0, "TEAM TBD 2023");
		tbdTxt.setFormat(Paths.font("gothic.ttf"), 12, FlxColor.WHITE, LEFT);
		tbdTxt.scrollFactor.set();
		tbdTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(tbdTxt);

		titleText = new FlxSprite(150, 550);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "Press start0", 24);
		titleText.animation.addByPrefix('press', "Press start selected", 24);
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('title/Sega'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.globalAntialiasing;

		tbdSpr = new FlxSprite(0, FlxG.height * 0.45).loadGraphic(Paths.image('title/TBDLogo'));
		add(tbdSpr);
		tbdSpr.visible = false;
		tbdSpr.setGraphicSize(Std.int(tbdSpr.width * 0.9));
		tbdSpr.updateHitbox();
		tbdSpr.screenCenter(X);
		tbdSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		#if sys
		if (!initialized && Argument.parse(Sys.args()))
		{
			initialized = true;
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			return;
		}
		#end

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if(pressedEnter)
			{
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.fade(1.5);
				FlxTransitionableState.skipNextTransIn = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1.5, function(tmr:FlxTimer)
				{
					if (mustUpdate) {
						MusicBeatState.switchState(new OutdatedState());
					} else {
						MusicBeatState.switchState(new MainMenuState());
					}
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if (symbol != null)
		{
			symbol.scale.set(1.1, 1.1);
			FlxTween.cancelTweensOf(symbol);
			FlxTween.tween(symbol, {"scale.x": 1, "scale.y": 1}, 0.15, {});
		}

		if (infinite != null)
			infinite.animation.play('bump', true);

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					createCoolText(['Team TBD']);

				case 3:
					// addMoreText('presents');
					tbdSpr.visible = true;

				case 4:
					tbdSpr.visible = false;
					deleteCoolText();

				case 5:
					createCoolText(['OG COPYRIGHT', 'TO'], -40);
				case 7:
					ngSpr.visible = true;

				case 8:
					deleteCoolText();
					ngSpr.visible = false;

				case 9:
					createCoolText([curWacky[0]]);

				case 11:
					addMoreText(curWacky[1]);

					if (curWacky[1] == "SQUID" && !skippedIntro)
						squid.play();

				case 12:
					deleteCoolText();

					if (curWacky[1] == "SQUID" && !skippedIntro)
						squid.stop();

				case 13:
					addMoreText('FNF');

				case 14:
					addMoreText('VS');

				case 15:
					addMoreText('INFINITE');

				case 16:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(tbdSpr);
			remove(ngSpr);
			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}
