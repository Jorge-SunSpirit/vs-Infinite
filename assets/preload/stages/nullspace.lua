function onCreate()
	posX = -400;
	posY = -425;
	scale = 1.7;

	-- background shit
	makeLuaSprite('bg', 'nullspace/bg1', posX, posY);
	setScrollFactor('bg', 0.2, 0.2);
	scaleObject('bg', scale, scale);
	updateHitbox('bg');
	
	makeLuaSprite('bg2', 'nullspace/bg2', posX, posY);
	setScrollFactor('bg2', 0.3, 0.3);
	scaleObject('bg2', scale, scale);
	updateHitbox('bg2');
	
	makeLuaSprite('bg3', 'nullspace/bg3', posX, posY);
	setScrollFactor('bg3', 0.3, 0.3);
	scaleObject('bg3', scale, scale);
	updateHitbox('bg3');
	
	makeLuaSprite('ground', 'nullspace/floor', posX, posY);
	setScrollFactor('ground', 1, 1);
	scaleObject('ground', scale, scale);
	updateHitbox('ground');
	
	makeLuaSprite('stageCurtains', 'nullspace/purple smoke', posX - 20, posY);
	setScrollFactor('stageCurtains', 1.1, 1.1);
	scaleObject('stageCurtains', scale, scale);
	updateHitbox('stageCurtains');

	
	addLuaSprite('bg', false);
	addLuaSprite('bg2', false);
	addLuaSprite('bg3', false);
	addLuaSprite('ground', false);
	addLuaSprite('stageCurtains', true);
end

function onCreatePost()
	triggerEvent('Spawn Particles', 'nullspace/particle1', 'down');
end
