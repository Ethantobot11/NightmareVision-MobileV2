import funkin.states.substates.GameOverSubstate;
import funkin.objects.Bopper;

import flixel.util.FlxDestroyUtil;

var dead;
var retryTxt;

function onCreatePost()
{
	// preloading death assets so game no lag....
	Paths.getSparrowAtlas("characters/NeneKnifeToss");
	Paths.getSparrowAtlas('characters/Pico_Death_Retry');
}

function onGameOverPost()
{
	dead = (GameOverSubstate.instance);
	dead.camFollow.setPosition(getCharacterCameraPos(dead.boyfriend).x, getCharacterCameraPos(dead.boyfriend).y);
	FlxG.camera.snapToTarget();
	
	neneSpr = new Bopper(gf.x - 100, gf.y).setFrames(Paths.getSparrowAtlas("characters/NeneKnifeToss"));
	neneSpr.addAnimByPrefix('die', 'knife toss', 24, false);
	neneSpr.playAnim('die');
	dead.add(neneSpr);
	
	FlxTween.tween(neneSpr, {alpha: 0}, 0.2, {startDelay: 0.5});
	
	retryTxt = new Bopper(dead.boyfriend.x + 200, dead.boyfriend.y).setFrames(Paths.getSparrowAtlas('characters/Pico_Death_Retry'));
	retryTxt.addAnimByPrefix('idle', 'Retry Text Loop', 24, true);
	retryTxt.addAnimByPrefix('confirm', 'Retry Text Confirm', 24, false);
	retryTxt.addOffset('confirm', 260, 200);
	retryTxt.alpha = 0;
	retryTxt.dance();
	dead.add(retryTxt);
	
	dead.boyfriend.onAnimationFrameChange.add((anim, frame) -> {
		if (anim == 'firstDeath')
		{
			switch (frame)
			{
				case 15:
					FlxTween.tween(dead.camFollow, {x: dead.boyfriend.getGraphicMidpoint().x - 200}, 0.5, {ease: FlxEase.backInOut});
				case 33:
					FlxTween.tween(retryTxt, {alpha: 1, y: retryTxt.y - 100}, 0.7, {ease: FlxEase.circOut});
			}
		}
	});
	
	FlxG.camera.follow(dead.camFollow, FlxCameraFollowStyle.LOCKON, 0);
}

function onGameOverConfirm()
{
	retryTxt.playAnim('confirm', true);
}

function onDestroy()
{
	retryTxt = FlxDestroyUtil.destroy(retryTxt);
}
