package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Mods'];
	private var grpOptions:FlxTypedGroup<FlxText>;
	var grayArray:Array<FlxSprite> = [];
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
			case 'Mods':
				LoadingState.loadAndSwitchState(new ModsMenuState());
		}
	}

	var selector:FlxSprite;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('options/optionsBG', 'preload'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);


		for (i in 0...options.length)
		{
			var graybox:FlxSprite = new FlxSprite(146 + (i * 4), 178 + (i * 57)).loadGraphic(Paths.image('options/box', 'preload'));
			graybox.antialiasing = ClientPrefs.globalAntialiasing;
			graybox.ID = i;
			grayArray.push(graybox);
			add(graybox);
		}

		selector = new FlxSprite(146, 178).loadGraphic(Paths.image('options/selected', 'preload'));
		selector.antialiasing = ClientPrefs.globalAntialiasing;
		add(selector);

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var menuItem:FlxText = new FlxText(197 + (i * 4), 190 + (i * 57), 1000, options[i]);
			menuItem.setFormat(Paths.font("futura.otf"), 27, FlxColor.BLACK, LEFT);
			menuItem.angle = -4;
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.ID = i;
			grpOptions.add(menuItem);
		}
		

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;


		grpOptions.forEach(function(txt:FlxText)
		{
			txt.color = FlxColor.BLACK;
			if (txt.ID == curSelected) 
			{
				txt.color = FlxColor.RED;
				selector.setPosition(grayArray[curSelected].x, grayArray[curSelected].y);
			}
		});


		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}