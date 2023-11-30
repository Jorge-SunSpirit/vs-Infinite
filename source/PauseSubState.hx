package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxText>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Exit to Menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var itemY:Float = 575;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();
		FlxG.sound.play(Paths.sound('pause'));
		if(CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!

		var num:Int = 0;

		if (PlayState.instance.hasCheckpoints && PlayState.checkpointHit)
		{
			menuItemsOG.insert(2, 'Restart from Checkpoint');
			num++;
		}

		if (PlayState.chartingMode)
		{
			menuItemsOG.insert(2 + num, 'Leave Charting Mode');
			
			if (!PlayState.instance.startingSong)
			{
				menuItemsOG.insert(3 + num, 'Skip Time');
				num++;
			}

			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}

		menuItems = menuItemsOG;

		for (i in 0...CoolUtil.difficulties.length) {
			var diff:String = '' + CoolUtil.difficulties[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');


		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		// pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		pauseMusic.play(false);

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var bg1:FlxSprite = new FlxSprite(-250).loadGraphic(Paths.image('pause/pause_bottom', 'shared'));
		bg1.scrollFactor.set();
		bg1.screenCenter(Y);
		bg1.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg1);

		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);

		var bg2:FlxSprite = new FlxSprite(-250).loadGraphic(Paths.image('pause/pause_top', 'shared'));
		bg2.scrollFactor.set();
		bg2.screenCenter(Y);
		bg2.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg2);

		var curRank:FlxText = new FlxText(-10, 299, 0, PlayState.instance.ratingFC);
		curRank.angle = -3.5;
		curRank.scrollFactor.set();
		curRank.setFormat(Paths.font("futura.otf"), 64);
		curRank.color = 0xFFDF00;
		curRank.antialiasing = ClientPrefs.globalAntialiasing;
		curRank.updateHitbox();
		add(curRank);
		
		var accuracy:FlxText = new FlxText(-10, 342, 0, '');
		accuracy.text = Highscore.floorDecimal(PlayState.instance.ratingPercent * 100, 2) + '%';
		accuracy.angle = -3.5;
		accuracy.scrollFactor.set();
		accuracy.setFormat(Paths.font("futura.otf"), 25);
		accuracy.color = 0xFF181818;
		accuracy.antialiasing = ClientPrefs.globalAntialiasing;
		accuracy.updateHitbox();
		add(accuracy);

		var missednotes:FlxText = new FlxText(-10, 368, 0, "");
		missednotes.text = Std.string(PlayState.instance.songMisses);
		missednotes.angle = -3.5;
		missednotes.scrollFactor.set();
		missednotes.setFormat(Paths.font("futura.otf"), 25);
		missednotes.color = 0xFF181818;
		missednotes.antialiasing = ClientPrefs.globalAntialiasing;
		missednotes.updateHitbox();
		add(missednotes);

		var levelInfo:FlxText = new FlxText(-10, 199, 0, "", 8);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.angle = -3.5;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("futura.otf"), 32);
		levelInfo.color = 0xFF181818;
		levelInfo.antialiasing = ClientPrefs.globalAntialiasing;
		levelInfo.updateHitbox();
		add(levelInfo);



		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(bg2, {x: 0}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(bg1, {x: 0}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(levelInfo, {x: 66}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(missednotes, {x: 423}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(accuracy, {x: 423}, 0.4, {ease: FlxEase.elasticOut});
		FlxTween.tween(curRank, {x: 250}, 0.4, {ease: FlxEase.elasticOut});

		FlxTween.tween(levelInfo, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		if (daSelected == 'Skip Time')
		{
			if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
			if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

			if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (accepted)
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, curSelected);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			if (daSelected == 'Resume')
				FlxG.sound.play(Paths.sound('cancelMenu'));
			else
				FlxG.sound.play(Paths.sound('confirmMenu'));

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					// practiceText.visible = PlayState.instance.practiceMode;
				case "Restart from Checkpoint":
					PlayState.deathCounter++; // you're not getting away with that lmao
					restartSong();
				case "Restart Song":
					PlayState.startOnTime = 0;
					PlayState.checkpointHit = false;
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case "End Song":
					close();
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case "Exit to Menu":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					if(PlayState.isStoryMode) {
						// MusicBeatState.switchState(new StoryMenuState());
						MusicBeatState.switchState(new MainMenuState());
					} else {
						MusicBeatState.switchState(new FreeplayState());
					}
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
			}
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'));

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.ID = bullShit - curSelected;
			bullShit++;

			if (item.ID == 0)
			{
				//Yes I need to do this. Flixel is dumb
				item.y = itemY;
				item.color = 0xFFC90000;

				if (menuItems[curSelected] == 'Skip Time')
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
			else
			{
				item.y = itemY + (item.ID * 40);
				item.color = 0xFFE8D8C0;
			}			

		}
	}

	function updateSkipTimeText()
	{
		for (item in grpMenuShit.members)
		{
			if (item.ID == 0 && menuItems[curSelected] == 'Skip Time')
				item.text == FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);

			trace(FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false));
		}
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item:FlxText = new FlxText(-10, itemY + (i * 40), 0, menuItems[i]);
			item.setFormat(Paths.font("futura.otf"), 25);
			item.ID = i;
			item.angle = -3.5;
			FlxTween.tween(item, {x: 40}, 0.4, {ease: FlxEase.elasticOut});
			item.antialiasing = ClientPrefs.globalAntialiasing;
			grpMenuShit.add(item);
		}
		curSelected = 0;
		changeSelection();
	}
	
}
