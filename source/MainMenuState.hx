package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];

	var selector:FlxSprite;

	var debugKeys:Array<FlxKey>;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		// persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, 0);
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		selector = new FlxSprite(-13, 51).loadGraphic(Paths.image('mainmenu/selector'));
		selector.antialiasing = ClientPrefs.globalAntialiasing;
		add(selector);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(35, 68 + (i * 105));
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_assets');
			menuItem.animation.addByPrefix('idle', optionShit[i] + '_idle', 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + '_selected', 24);
			menuItem.animation.play('idle');
			menuItem.angle = -6;
			menuItem.ID = i;
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.updateHitbox();
		}

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font("futura.otf"), 16, FlxColor.RED, LEFT);
		versionShit.setBorderStyle(OUTLINE, 0xFFF9EDD7, 1.25);
		versionShit.antialiasing = ClientPrefs.globalAntialiasing;
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "VS. Infinite v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font("futura.otf"), 16, FlxColor.RED, LEFT);
		versionShit.setBorderStyle(OUTLINE, 0xFFF9EDD7, 1.25);
		versionShit.antialiasing = ClientPrefs.globalAntialiasing;
		add(versionShit);

		changeItem();

		super.create();
	}


	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (FlxG.keys.justPressed.CONTROL && optionShit[curSelected] == 'story_mode')
			{
				openSubState(new GameplayChangersSubstate());
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;

					var duration:Float = 1;

					if (optionShit[curSelected] == 'story_mode')
					{
						duration = 1.5;
						FlxG.sound.play(Paths.sound('confirmMenuWeek'));
						FlxG.sound.music.fadeOut(1.5);
						FlxG.camera.fade(FlxColor.BLACK, 1.5);
						FlxTransitionableState.skipNextTransIn = true;
					}
					else
					{
						FlxG.sound.play(Paths.sound('confirmMenu'));
					}

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, duration, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
									{
										//MusicBeatState.switchState(new StoryMenuState());
										PlayState.storyPlaylist = ['Phantom', 'Masked', 'Fragility', 'RUBY INSANITY'];
										PlayState.isStoryMode = true;
										PlayState.storyDifficulty = 2;
										PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + '-hard',
											PlayState.storyPlaylist[0].toLowerCase());
										PlayState.campaignScore = 0;
										PlayState.campaignMisses = 0;
										LoadingState.loadAndSwitchState(new PlayState(), true);
										FreeplayState.destroyFreeplayVocals();
									}
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'credits':
										MusicBeatState.switchState(new InfCreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		selector.x = -90;
		/*
		switch (curSelected)
		{
			case 0:
				selector.x = -115;
				selector.y = 35;
			case 1:
				selector.x = -90;
				selector.y = 140;
			case 2:
				selector.x = -90;
				selector.y = 246;
			case 3:
				selector.x = -90;
				selector.y = 350;
		}*/

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var selxpos:Float;
				selxpos = selector.x;
				selector.x = -250;
				selector.y = spr.y - 35;
				FlxTween.cancelTweensOf(selector);
				FlxTween.tween(selector, {x: selxpos}, 0.5, {ease: FlxEase.elasticOut});
			}
		});
	}
}
