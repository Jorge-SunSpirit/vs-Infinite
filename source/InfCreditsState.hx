package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

using StringTools;

class InfCreditsState extends MusicBeatState
{
	var curSelected:Int = 0;
	var curRow:Int = 0;

	var graybox:FlxSprite;

	private var grpOptions:FlxTypedGroup<CreditsItem>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var userChara:Array<Array<String>> = [ //Name - Icon name - role - Quote of the day - Link - Which Row - position
		//column 1
		['JACKALRUIN',	'jackalruin',	'Director, Music, UI',	"BECKON THE SKY",	'https://www.youtube.com/@JACKALRUIN',	"0", "0"],
		['Crim',	'crim',	'Main Artist',	":v",	'https://twitter.com/ScrimbloCrimbo',	"0", "1"],
		['SirDusterBuster',	'duster',	'Sprite Animator',	"When is vs Zavok?",	'https://twitter.com/SirDusterBuster',	"0", "2"],
		['Miss Beepy',	'beepy',	'Infinite Sketches',	"hueh",	'https://www.youtube.com/watch?v=0MW9Nrg_kZU',	"0", "3"],
		['LezaLeza',	'leza',	'BG Artist',	"hueh",	'https://twitter.com/lezanikat',	"0", "4"],

		
		['M&M',	'mandm',	'Main Programmer',	"i put fortnite on a scu burner account",	'https://linktr.ee/ActualMandM',	"1", "0"],
		['Jorge - SunSpirit',	'jorge',	'UI Programmer',	"Defeat me with heat beams, you're crazy!",	'https://twitter.com/Jorge_SunSpirit',	"1", "1"],
		['HighPoweredKeyz',	'hpk',	'Chromatic Assistance',	"Stay creative, and stay powerful.",	'https://twitter.com/HighPoweredArt',	"1", "2"],
		['Flootena',	'flootena',	'Charter',	"hueh",	'https://twitter.com/FlootenaDX',	"1", "3"],
		['Psych Engine Team',	'psych',	'Psych Engine Credits',	"Open the Psych Engine Credits Here!",	'hueh',	"1", "4"]
	];

	var bg:FlxSprite;
	var descText:FlxText;

	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('credits/VSInfiniteCredits'));
		add(bg);
		bg.screenCenter();

		graybox = new FlxSprite(0, 10).makeGraphic(346, 88, FlxColor.BLACK);
		graybox.alpha = 0.5;
		add(graybox);
		
		grpOptions = new FlxTypedGroup<CreditsItem>();
		add(grpOptions);
		
		for(i in userChara){
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var creditObject:CreditsItem = new CreditsItem(290 + (346 * Std.parseFloat(creditsStuff[i][5])), 171 + (88 * Std.parseFloat(creditsStuff[i][6])), creditsStuff[i][0], creditsStuff[i][2], creditsStuff[i][1]);
			grpOptions.add(creditObject);
		}

		
		descText = new FlxText(264, 640, 753, "", 32);
		descText.setFormat(Paths.font("futura.otf"), 32, 0xFFFFBDBD, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.antialiasing = ClientPrefs.globalAntialiasing;
		add(descText);

		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{

				if (controls.UI_UP_P)
				{
					changeSelection('up');
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection('down');
				}
				if (controls.UI_LEFT_P)
				{
					changeSelection('left');
				}
				if (controls.UI_RIGHT_P)
				{
					changeSelection('right');
				}
			}

			if(controls.ACCEPT && creditsStuff[curSelected][4] != 'hueh')
				CoolUtil.browserLoad(creditsStuff[curSelected][4]);
			else if(controls.ACCEPT && creditsStuff[curSelected][4] == 'hueh')
			{
				MusicBeatState.switchState(new CreditsState());
				quitting = true;
			}

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		super.update(elapsed);
	}

	function changeSelection(?direction:String)
	{
		var change:Int = 0;
		switch(direction)
		{
			case 'left':
				change = -5;
			case 'right':
				change = 5;
			case 'up':
				change = -1;
			case 'down':
				change = 1;
			default:
				change = 0;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;
		if (curSelected < 0)
		{
			var quickmaths:Int = 0;
			quickmaths = curSelected + creditsStuff.length; //I'm dumb
			curSelected = quickmaths;
		}
		if (curSelected >= creditsStuff.length)
		{
			var quickmaths:Int = 0;
			quickmaths = curSelected - creditsStuff.length; //I'm dumb
			curSelected = quickmaths;
		}

		curRow = Std.parseInt(creditsStuff[curSelected][5]);

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.ID = bullShit - curSelected;
			bullShit++;

			if (item.ID == 0)
			{
				FlxTween.cancelTweensOf(graybox);
				FlxTween.tween(graybox, {x: item.x, y:item.y}, 0.1, {ease: FlxEase.circOut});
			}

		}
		descText.text = creditsStuff[curSelected][3];
	}
}

class CreditsItem extends FlxSpriteGroup
{
	var graybox:FlxSprite;

	public function new (x:Float = 0, y:Float = 0, name:String, role:String, chara:String)
	{
		super(x, y);

		var icon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('credits/icons/infinite/' + chara));
		icon.x = 0;
		icon.y = 15;
		icon.setGraphicSize(Std.int(icon.width * .4));
		icon.updateHitbox();
		icon.antialiasing = ClientPrefs.globalAntialiasing;
		add(icon);

		var username:FlxText = new FlxText(70, 10, 300, name);
		username.setFormat(Paths.font("futura.otf"), 30, 0xFFddcdb7, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		username.antialiasing = ClientPrefs.globalAntialiasing;
		add(username);

		var userrole:FlxText = new FlxText(70, 45, 200, role);
		userrole.setFormat(Paths.font("futura.otf"), 20, 0xFFddcdb7, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		userrole.antialiasing = ClientPrefs.globalAntialiasing;
		add(userrole);
	}
}