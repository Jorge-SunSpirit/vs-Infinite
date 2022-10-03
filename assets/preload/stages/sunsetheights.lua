function onCreate()

	posX = -580;
	posY = -300;
	scale = 3;
	-- background shit
	makeLuaSprite('bg', 'SSH/skybox', posX, posY);
	setScrollFactor('bg', 0.2, 1);
	scaleObject('bg', scale, scale);
	updateHitbox('bg');
	
	makeLuaSprite('stageback', 'SSH/bg', posX, posY);
	setScrollFactor('stageback', 0.9, 1);
	scaleObject('stageback', scale, scale);
	updateHitbox('stageback');
	
	makeLuaSprite('ground', 'SSH/main', posX, posY);
	setScrollFactor('ground', 1, 1);
	scaleObject('ground', scale, scale);
	updateHitbox('ground');
	
	makeLuaSprite('foreground', 'SSH/foreground', posX, posY);
	setScrollFactor('foreground', 1.2, 1);
	scaleObject('foreground', scale, scale);
	updateHitbox('foreground');

	
	addLuaSprite('bg', false);
	addLuaSprite('stageback', false);
	addLuaSprite('ground', false);
	addLuaSprite('foreground', true);
end

function onCreatePost()
	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end