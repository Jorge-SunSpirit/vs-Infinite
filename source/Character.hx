package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var shadow_Offset:Float;
	var charaFloat:Bool;
	var gameover_Character:String;
	var death_Sound:String;
	var playericon:String;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holding:Bool = false;
	public var singing:Bool = false;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var flipAnim:Bool = false;
	public var hasMissAnimations:Bool = false;

	public var deathsound:String = 'fnf_loss_sfx';
  	public var gameoverchara:String = 'sonic';

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var initFacing:Int = FlxObject.RIGHT;
	var initWidth:Float;
	var facingleft:Bool = false;
	var animdebug:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var baseYPos:Float = 0;
	public var shadowOffset:Float = 50;
	public var hasShadow:Bool = false;
	public var float:Bool;
	var floatshit:Float = 0;

	public static var DEFAULT_CHARACTER:String = 'sonic'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'sonic', ?isPlayer:Bool = false, ?shadowCtx:Bool = false, ?isAnimDebug:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		animdebug = isAnimDebug;
		if (!animdebug)	flipAnim = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		var library:String = null;
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode him instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';
				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				#if MODS_ALLOWED
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);
				if(FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				#else
				if(Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
				//bozo forgot about the packer shits : P
					frames = Paths.getPackerAtlas(json.image);
				}
				else
				{
					frames = Paths.getSparrowAtlas(json.image);
				}
				imageFile = json.image;
				
				if (!animdebug)
				{
					if (!!json.flip_x)
						{
							initFacing = FlxObject.LEFT;
							facingleft = true;
						}
						else
						{
							initFacing = FlxObject.RIGHT;
							facingleft = false;
						}
				}

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				if (isPlayer && json.playericon != null)
					healthIcon = json.playericon;
				else
					healthIcon = json.healthicon;

				singDuration = json.sing_duration;
				shadowOffset = json.shadow_Offset;
				float = json.charaFloat;
				gameoverchara = json.gameover_Character;
  				deathsound = json.death_Sound;

				if (animdebug) flipX = !!json.flip_x;

				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !ClientPrefs.globalAntialiasing ? false : !noAntialiasing;

				animationsArray = json.animations;

				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;

						if (animIndices != null && animIndices.length > 0)
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						else
							animation.addByPrefix(animAnim, animName, animFps, animLoop);

						if (anim.offsets != null && anim.offsets.length > 1)
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}
		}

		if (!animdebug) setFacingFlip((initFacing == FlxObject.LEFT ? FlxObject.RIGHT : FlxObject.LEFT), true, false);
		
		if (animdebug) originalFlipX = flipX;
			
		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (!animdebug) facing = (flipAnim ? FlxObject.LEFT : FlxObject.RIGHT);

		if (animdebug && isPlayer)	flipX = !flipX;

		if (!animdebug && facing != initFacing)
		{
			if (animation.getByName('singRIGHT') != null)
				{
					var oldRight = animation.getByName('singRIGHT').frames;
					var oldOffset = animOffsets['singRIGHT'];
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animOffsets['singRIGHT'] = animOffsets['singLEFT'];
					animation.getByName('singLEFT').frames = oldRight;
					animOffsets['singLEFT'] = oldOffset;
				}
	
				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					var oldOffset = animOffsets['singRIGHTmiss'];
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animOffsets['singRIGHTmiss'] = animOffsets['singLEFTmiss'];
					animation.getByName('singLEFTmiss').frames = oldMiss;
					animOffsets['singLEFTmiss'] = oldOffset;
				}
	
				if (animation.getByName('singRIGHT-alt') != null)
				{
					var oldRight = animation.getByName('singRIGHT-alt').frames;
					var oldOffset = animOffsets['singRIGHT-alt'];
					animation.getByName('singRIGHT-alt').frames = animation.getByName('singLEFT-alt').frames;
					animOffsets['singRIGHT-alt'] = animOffsets['singLEFT-alt'];
					animation.getByName('singLEFT-alt').frames = oldRight;
					animOffsets['singLEFT-alt'] = oldOffset;
				}
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}

		hasShadow = shadowCtx;
	}

	public override function draw():Void
	{
		if (!debugMode && hasShadow)
		{
			var origY = y;
			var origalpha = alpha;
			var origColor = color;

			y = baseYPos + (baseYPos - y) + height + offset.y + shadowOffset;
			flipY = !flipY;
			alpha = 0.5;
			color = FlxColor.BLACK;

			super.draw();

			y = origY;
			alpha = origalpha;
			color = origColor;
			flipY = !flipY;
		}

		super.draw();
	}

	override function update(elapsed:Float)
	{
		floatshit += 0.03 / FramerateTools.timeMultiplier();

		if (!debugMode && float)
			y += Math.sin(floatshit) / FramerateTools.timeMultiplier();

		if(!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			singing = animation.curAnim.name.startsWith("sing") || animation.curAnim.name.startsWith("hold");

			if (isPlayer)
			{
				if (singing)
					holdTimer += elapsed;
				else
					holdTimer = 0;
	
				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
					playAnim('idle', true, false, 10);
			}
			else
			{
				if (singing)
					holdTimer += elapsed;

				if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}

		super.update(elapsed);

		if (!debugMode && animation.curAnim != null)
		{
			// ANDROMEDAAAAAAAAAAAAAAAAAAAAAAA
			var name = animation.curAnim.name;

			if (name.startsWith("hold"))
			{
				if (name.endsWith("start") && animation.curAnim.finished)
				{
					var newName = name.substring(0, name.length - 5);
					var singName = "sing" + name.substring(3, name.length - 5);

					if (animation.getByName(newName) != null)
						playAnim(newName, true);
					else
						playAnim(singName, true);
				}
			}
			else if (holding)
			{
				animation.curAnim.curFrame = 0; // Pause on first frame when holding
			}
		}
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			holding = false;

			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animation.getByName('idle' + idleSuffix) != null)
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			if (!animdebug) offset.set((facing != initFacing ? -1 : 1) * daOffset[0] + (facing != initFacing ? frameWidth - initWidth : 0), daOffset[1]);	
			
			if (animdebug) offset.set(daOffset[0], daOffset[1]);
			
			if (!animdebug && facing != initFacing)	offset.x -= 400;
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}
