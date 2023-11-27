function onCreate()
	posX = 0;
	posY = 0;
	scale = 1;
	
	makeLuaSprite('ruby', '', -200, -200);	
    makeGraphic('ruby', 1280*2, 720*2, '0xFF0046');
    setScrollFactor('ruby', 0, 0);
	setObjectCamera('ruby', 'Game');
	setProperty('ruby.alpha', 0.0001);
    addLuaSprite('ruby', false);

	makeAnimatedLuaSprite('rubyspeed', 'SSH/infinitespeed', posX, posY);
	addAnimationByPrefix('rubyspeed', 'infinitewin', 'RedSpeed', 24, true);
	setScrollFactor('rubyspeed', 0, 0);
	scaleObject('rubyspeed', 1.5, 1.5);
	setProperty('rubyspeed.alpha', 0.001);
	addLuaSprite('rubyspeed', false);
    screenCenter('rubyspeed');

	makeLuaSprite('dramashadow', 'SSH/dramablack', -600, -300);
	setScrollFactor('dramashadow', 1, 1);
	scaleObject('dramashadow', 2, 2);
	addLuaSprite('dramashadow', false);
	setProperty('dramashadow.alpha', 0.0001);

	makeLuaSprite('black', '', 0, 0);	
    makeGraphic('black', 1280, 720, '0x000000');
    setScrollFactor('black', 0, 0);
	setObjectCamera('black', 'hud');
	setProperty('black.alpha', 0.001);
    addLuaSprite('black', true);
	
	makeLuaSprite('rubyglow', 'SSH/infinitelight', posX, posY);
	scaleObject('rubyglow', 1.1, 1.1);
	setProperty('rubyglow.alpha', 0.001);
	setObjectCamera('rubyglow', 'hud');
	addLuaSprite('rubyglow', false);
    screenCenter('rubyglow');
end

function onStepHit()
	if curStep == 256 then
		setProperty('ruby.alpha', 0.07);
		setProperty('rubyglow.alpha', 1);
	end
	if curStep == 512 then
		setProperty('ruby.alpha', 0.25);
	end
	if curStep == 1024 then
		setProperty('rubyspeed.alpha', 1);
	end
	if curStep == 1280 then
		setProperty('rubyspeed.alpha', 0.0001);
		setProperty('ruby.alpha', 0.0001);
		setProperty('rubyglow.alpha', 0.0001);
	end
	if curStep == 1840 then
		setProperty('rubyspeed.alpha', 1);
		setProperty('rubyglow.alpha', 1);
	end
	if curStep == 2096 then
		doTweenAlpha('black', 'black', 1, 3);
	end
	if curStep == 2152 then
		setProperty('rubyspeed.alpha', 0.0001);
		setProperty('rubyglow.alpha', 0.0001);
		setProperty('dramashadow.alpha', 1);
		doTweenAlpha('black', 'black', 0.0001, 1);
	end
	if curStep == 2655 then
		setProperty('ruby.alpha', 0.3);
		doTweenAlpha('rubyglow', 'rubyglow', 0.7, 1);
	end
	if curStep == 2932 then
		doTweenAlpha('black', 'black', 1, 7);
	end
end