function onCreate()

	posX = -600;
	posY = -300;
	scale = 2;
	-- background shit
	makeLuaSprite('bg', 'SSH/skybox', posX, posY);
	setScrollFactor('bg', 0.2, 1);
	scaleObject('bg', scale, scale);
	updateHitbox('bg');
	
	makeLuaSprite('stageback3', 'SSH/bg3', posX, posY);
	setScrollFactor('stageback3', 0.75, 1);
	scaleObject('stageback3', scale, scale);
	updateHitbox('stageback3');
	
	makeLuaSprite('stageback2', 'SSH/bg2', posX, posY);
	setScrollFactor('stageback2', 0.8, 1);
	scaleObject('stageback2', scale, scale);
	updateHitbox('stageback2');
	
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
	addLuaSprite('stageback3', false);
	addLuaSprite('stageback2', false);
	addLuaSprite('stageback', false);
	addLuaSprite('ground', false);
	addLuaSprite('foreground', true);
end

function onCreatePost()
	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end