package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.utils.Assets;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	public var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	public static var instance:FreeplayState;

	//var freeplaysong:FlxTypedSpriteGroup<Dynamic>;
	var freeplayitems:Array<FlxTypedSpriteGroup<Dynamic>> = [];

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<FreeplayItem>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		instance = this;
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), song[3]);
			}
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('freeplay/bg/default'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.screenCenter();
		add(bg);

		var underlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayunderlay'));
		underlay.antialiasing = ClientPrefs.globalAntialiasing;
		underlay.screenCenter();
		add(underlay);

		grpSongs = new FlxTypedGroup<FreeplayItem>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			Paths.currentModDirectory = songs[i].folder;
			var songObject:FreeplayItem = new FreeplayItem(716 + (i * 2), 62 + (i* 72), songs[i].songName, songs[i].songCharacter, songs[i].artist, songs[i].folder);
			songObject.angle = -6;
			grpSongs.add(songObject);
		}

		var overlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayoverlay'));
		overlay.antialiasing = ClientPrefs.globalAntialiasing;
		overlay.screenCenter();
		add(overlay);

		WeekData.setDirectoryFromWeek();

		diffText = new FlxText(713, 569, 0, "", 24);
		diffText.angle = -3;
		diffText.setFormat(Paths.font("futura.otf"), 35, FlxColor.BLACK, FlxTextAlign.RIGHT);
		diffText.antialiasing = ClientPrefs.globalAntialiasing;
		add(diffText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection(false);
		changeDiff();

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(0, FlxG.height - 25, FlxG.width - 5, leText, size);
		text.setFormat(Paths.font("futura.otf"), size, FlxColor.WHITE, RIGHT);
		text.antialiasing = ClientPrefs.globalAntialiasing;
		add(text);

		for (item in grpSongs.members)
		{
			Paths.currentModDirectory = item.songFolder;
			item.updatescore();
		}

		changeSelection(false);
		changeDiff();

		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, artist:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color, artist));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		#if debug
		if (FlxG.keys.pressed.SHIFT && (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L))
			{
				if (FlxG.keys.pressed.I)
					diffText.y += -1;
				else if (FlxG.keys.pressed.K)
					diffText.y += 1;
				if (FlxG.keys.pressed.J)
					diffText.x += -1;
				else if (FlxG.keys.pressed.L)
					diffText.x += 1;
				}
		#end

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if(ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space)
		{
			if(instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				#end
			}
		}

		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;


			if(colorTween != null) {
				colorTween.cancel();
			}
			
			if (FlxG.keys.pressed.SHIFT){
				LoadingState.loadAndSwitchState(new ChartingState());
			}else{
				LoadingState.loadAndSwitchState(new PlayState());
			}

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';

		for (item in grpSongs.members)
		{
			if (item.ID == 0)
				item.updatescore();
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		var bullShit:Int = 0;
		curSelected += change;

		if (curSelected < 0)
		{
			curSelected = songs.length - 1;
		}
		if (curSelected >= songs.length)
		{
			curSelected = 0;
		}
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}


		for (item in grpSongs.members)
		{
			item.ID = bullShit - curSelected;
			bullShit++;

			FlxTween.cancelTweensOf(item);

			if(curSelected >= 3 && curSelected <= songs.length - 3)
				FlxTween.tween(item, {x: 722 + (item.ID * 2), y: 278 + (item.ID * 72)}, 0.5, {ease: FlxEase.circOut});

			//Hardcoding this cause I hate doing math. Feel free to optimize later
			if(curSelected == 0)
				FlxTween.tween(item, {x: 716 + (item.ID * 2), y: 62 + (item.ID * 72)}, 0.5, {ease: FlxEase.circOut});
			if(curSelected == 1)
				FlxTween.tween(item, {x: 718 + (item.ID * 2), y: 134 + (item.ID * 72)}, 0.5, {ease: FlxEase.circOut});
			if(curSelected == 2)
				FlxTween.tween(item, {x: 720 + (item.ID * 2), y: 206 + (item.ID * 72)}, 0.5, {ease: FlxEase.circOut});

			if (songs.length >= 5)
			{
				if(curSelected == songs.length - 2)
					FlxTween.tween(item, {x: 724 + (item.ID * 2), y: 350 + (item.ID * 72)}, 0.5, {ease: FlxEase.circOut});
				if(curSelected == songs.length - 1)
					FlxTween.tween(item, {x: 726 + (item.ID * 2), y: 422 + (item.ID * 72)}, 0.5, {ease: FlxEase.circOut});	
			}
			

			item.selected(false);

			if (item.ID == 0)
			{
				//FlxTween.tween(item, {x: 716}, 0.5, {ease: FlxEase.elasticOut});
				item.selected(true);
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}

		var songName:String = Paths.formatToSongPath(songs[curSelected].songName);
		var img = Paths.image('freeplay/bg/$songName');
		if (img == null) img = Paths.image('freeplay/bg/default');

		bg.loadGraphic(img);
	}

}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var artist:String = "";
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int, artist:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.artist = artist;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}

class FreeplayItem extends FlxSpriteGroup
{
	var song:String;

	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var ratingSplit:Array<String>;

	var bg:FlxSprite;
	var songname:FlxText;
	var score:FlxText;
	public var songFolder:String;
	var charIcon:HealthIcon;

	public function new(x:Float = 0, y:Float = 0, songs:String, chara:String, artist:String, folder:String)
	{
		song = songs;
		songFolder = folder;
		super(x, y);

		#if !switch
		intendedScore = Highscore.getScore(song.toLowerCase(), FreeplayState.instance.curDifficulty);
		intendedRating = Highscore.getRating(song.toLowerCase(), FreeplayState.instance.curDifficulty);
		#end

		bg = new FlxSprite(0, 0);
		bg.frames = Paths.getSparrowAtlas('freeplay/freeplay selector');
		bg.animation.addByPrefix('idle', 'idle', 24);
		bg.animation.addByPrefix('selected', 'selected', 24);
		bg.animation.play('idle');
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		songname = new FlxText(100, 20, 0, song);
		if (artist != null) songname.text += '\n$artist';
		songname.setFormat(Paths.font("futura.otf"), 20, FlxColor.RED, FlxTextAlign.LEFT);
		songname.antialiasing = ClientPrefs.globalAntialiasing;
		songname.updateHitbox();
		add(songname);

		//Lazy want to get atleast the base of this finished. Gotta implement rating here.
		score = new FlxText(320, 0, 120, '');
		score.setFormat(Paths.font("futura.otf"), 20, FlxColor.RED, FlxTextAlign.RIGHT);
		score.autoSize = false;
		score.wordWrap = false;
		score.alignment = FlxTextAlign.RIGHT;
		score.antialiasing = ClientPrefs.globalAntialiasing;
		score.updateHitbox();
		add(score);

		var icon:HealthIcon = new HealthIcon(chara);
		icon.x = -25;
		icon.y = -25;
		icon.setGraphicSize(Std.int(icon.width * .4));
		icon.updateHitbox();
		add(icon);
	}

	public function updatescore()
	{

		#if !switch
		intendedScore = Highscore.getScore(song.toLowerCase(), FreeplayState.instance.curDifficulty);
		intendedRating = Highscore.getRating(song.toLowerCase(), FreeplayState.instance.curDifficulty);
		#end
		ratingSplit = Std.string(Highscore.floorDecimal(intendedRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}
		
		score.text = intendedScore + '\n (' + ratingSplit.join('.') + '%)';
	}

	public function selected(hueh:Bool)
	{
		if(hueh)
		{
			bg.animation.play('selected');
			songname.color = FlxColor.RED;
			score.color = FlxColor.RED;
		}
		else
		{
			bg.animation.play('idle');
			songname.color = 0xFFE4D4BC;
			score.color = 0xFFE4D4BC;
		}
	}

}