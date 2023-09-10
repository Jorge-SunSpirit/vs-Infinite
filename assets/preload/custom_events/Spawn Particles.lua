local particles = false;
local particleSprite = '';
local direction = '';
function onEvent(name, value1, value2) 
	if name == 'Spawn Particles' and not flashingLights then
		particles = not particles;
		particleSprite = value1;
		direction = value2;
		debugPrint(particleSprite);
	end
end

function onBeatHit()
	if particles then
		runHaxeCode([[
			var funniSprite:String;
			var direction:String;
			funniSprite = "]]..particleSprite..[[";
			direction = "]]..direction..[[";

			var parti:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(funniSprite));
			parti.antialiasing = ClientPrefs.globalAntialiasing;
			parti.x = FlxG.random.int(-700, 1700);
			parti.y = game.boyfriend.y + 700;
			game.add(parti);

			FlxTween.tween(parti, {y: parti.y - 600, alpha: 0}, FlxG.random.float(1, 7) / game.playbackRate, {
			onComplete: function(tween:FlxTween){
				parti.destroy();
			}});
		]])
	end
end
