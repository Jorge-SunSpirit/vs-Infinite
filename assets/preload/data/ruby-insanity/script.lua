function onStepHit()
	if curStep == 4480 then
		doTweenAlpha('hudAlpha', 'camHUD', 0, 0.4, 'linear');
	end

	if curStep == 4992 then
		setProperty('camHUD.alpha', 1);
	end
end
