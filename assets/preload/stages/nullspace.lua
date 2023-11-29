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
	
	makeAnimatedLuaSprite('lightning', 'nullspace/bolt', 0, posY);
	addAnimationByPrefix('lightning', 'stike', 'BGLightning', 24, false);
	setScrollFactor('lightning', 0.3, 0.3);
	setProperty('lightning.alpha', 0.001);
	
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
	addLuaSprite('lightning', false);
	addLuaSprite('ground', false);
	addLuaSprite('stageCurtains', true);
end

function onCreatePost()
	addLuaScript('custom_events/Spawn Spinning Particles');
	addLuaScript('custom_events/Spawn Particles');
	triggerEvent('Spawn Particles', 'nullspace/particle1', '600');
	triggerEvent('Spawn Spinning Particles', 'nullspace/particle2', '600');
end

local lightningStrikeBeat = 0;
local lightningOffset = 8;

function onBeatHit()
	if getRandomBool(25) and curBeat > lightningStrikeBeat + lightningOffset then
		lightingStrike()
	end
end

function lightingStrike()
	setProperty('lightning.x', getRandomInt(-1000,500));
	setProperty('lightning.alpha', 1);
	objectPlayAnimation('lightning', 'stike', true);
	lightningOffset = getRandomInt(4,15);
	lightningStrikeBeat = curBeat;
end
