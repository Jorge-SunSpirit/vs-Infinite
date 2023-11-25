function onCreatePost()
	makeLuaSprite('black', '', 0, 0);	
    makeGraphic('black', 1280, 720, '000000');
    setScrollFactor('black', 0, 0);
	setObjectCamera('black', 'hud');
    addLuaSprite('black', false);
	
	setProperty('isCameraOnForcedPos', true);
	doTweenZoom('zoomcamera', 'camGame', 1, 0.1);
	setProperty('camFollow.x', 650);
	setProperty('camFollow.y', 300);
end


function onStepHit()
	if curStep == 1 then
		doTweenAlpha('black', 'black', 0, 14, 'linear');
		doTweenZoom('hueh', 'camGame', 0.8, 14, 'linear');
	end
	if curStep == 144 then
		setProperty('isCameraOnForcedPos', false);
	end
	if curStep == 4480 then
		doTweenAlpha('hudAlpha', 'camHUD', 0, 0.4, 'linear');
		setProperty('cameraSpeed', 2);
		triggerEvent('Camera Follow Pos', '620', '326');
	end

	if curStep == 4992 then
		setProperty('camHUD.alpha', 1);
		setProperty('cameraSpeed', 1);
		triggerEvent('Camera Follow Pos', '', '');
	end
end
