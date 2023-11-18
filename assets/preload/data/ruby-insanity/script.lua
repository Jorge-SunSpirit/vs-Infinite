function onStepHit()
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
