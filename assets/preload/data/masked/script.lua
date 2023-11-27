function onCreate()
	posX = 0;
	posY = 0;
	scale = 1;
	
	makeAnimatedLuaSprite('sonicspeed', 'SSH/sonicspeed', posX, posY);
	addAnimationByPrefix('sonicspeed', 'sonicwin', 'BlueSpeed', 24, true);
	setScrollFactor('sonicspeed', 0, 0);
	scaleObject('sonicspeed', 1.5, 1.5);
	setProperty('sonicspeed.alpha', 0.001);
	addLuaSprite('sonicspeed', false);
    screenCenter('sonicspeed');
end

function onStepHit()
	if curStep == 1056 then
		setProperty('sonicspeed.alpha', 1);
	end
	if curStep == 1296 then
		setProperty('sonicspeed.alpha', 0.0001);
	end
end