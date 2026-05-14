package funkin.backend;

import funkin.scripting.PluginsManager;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.input.actions.FlxActionInput;
import funkin.backend.BaseTransitionState;
import funkin.states.transitions.SwipeTransition;
import funkin.data.*;
import funkin.scripts.*;
import funkin.input.Controls;

class MusicBeatState extends FlxUIState
{
	static final _defaultTransState:Class<BaseTransitionState> = SwipeTransition;
	
	// change these to change the transition
	public static var transitionInState:Null<Class<BaseTransitionState>> = null;
	public static var transitionOutState:Null<Class<BaseTransitionState>> = null;
	
	public function new() super();
	
	private var stepsToDo:Int = 0;
	
	public var curSection:Int = 0;
	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;
	
	// script related vars
	public var scripted:Bool = false;
	public var scriptName:String = '';
	public var scriptGroup:ScriptGroup = new ScriptGroup();
	
	public function initStateScript(?scriptName:String, callOnLoad:Bool = true):Bool
	{
		if (scriptName == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
			scriptName = stateName ?? '???';
		}
		
		final scriptFile = FunkinScript.getPath('scripts/states/$scriptName');
		if (scriptGroup.exists(scriptFile)) return true;
		
		this.scriptName = scriptName;
		
		if (FunkinAssets.exists(scriptFile))
		{
			var newScript = FunkinScript.fromFile(scriptFile, scriptName);
			if (newScript.__garbage)
			{
				newScript = FlxDestroyUtil.destroy(newScript);
				return false;
			}
			
			scriptGroup.parent = this;
			
			Logger.log('script [$scriptName] initialized', NOTICE);
			
			scriptGroup.addScript(newScript);
			scripted = true;
		}
		
		if (callOnLoad) scriptGroup.call('onLoad', []);
		
		return scripted;
	}
	
	inline function get_controls():Controls return Controls.instance;

    #if TOUCH_CONTROLS
	public static var checkHitbox:Bool = false;
	public var mobilePad:MobilePad;
	public static var mobilec:MobileControls;

	var trackedinputsUI:Array<FlxActionInput> = [];
	var trackedinputsNOTES:Array<FlxActionInput> = [];

	public function addMobilePad(?DPad:String, ?Action:String) {
		if (mobilePad != null)
			removeMobilePad();

		mobilePad = new MobilePad(DPad, Action);
		add(mobilePad);

		controls.setMobilePadUI(mobilePad, DPad, Action);
		trackedinputsUI = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
		mobilePad.alpha = ClientPrefs.mobilePadAlpha;
	}

	public function removeMobilePad() {
		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		if (mobilePad != null)
			remove(mobilePad);
	}

	/*
	public function addVirtualPad(?DPad:String, ?Action:String)
		return addMobilePad(DPad, Action);

	public function removeVirtualPad()
		return removeMobilePad();
	*/

	public function removeMobileControls() {
		if (trackedinputsNOTES.length > 0)
			controls.removeVirtualControlsInput(trackedinputsNOTES);

		if (mobilec != null)
			remove(mobilec);
	}

	public function addMobileControls(?customControllerValue:Int, ?mode:String, ?action:String) {
		mobilec = new MobileControls(customControllerValue, mode, action);

		switch (MobileControls.mode)
		{
			case MOBILEPAD_RIGHT | MOBILEPAD_LEFT | MOBILEPAD_CUSTOM:
				controls.setMobilePadNOTES(mobilec.vpad, "FULL", "NONE");
				MusicBeatState.checkHitbox = false;
			case DUO:
				controls.setMobilePadNOTES(mobilec.vpad, "DUO", "NONE");
				MusicBeatState.checkHitbox = false;
			case HITBOX:
				controls.setHitBox(mobilec.newhbox, mobilec.hbox);
				MusicBeatState.checkHitbox = true;
			default:
		}

		trackedinputsNOTES = controls.trackedInputsNOTES.copy();

		var camcontrol = new flixel.FlxCamera();
		FlxG.cameras.add(camcontrol, false);
		camcontrol.bgColor.alpha = 0;
		mobilec.cameras = [camcontrol];

		add(mobilec);
	}

	public function addMobilePadCamera() {
		var camcontrol = new flixel.FlxCamera();
		camcontrol.bgColor.alpha = 0;
		FlxG.cameras.add(camcontrol, false);
		mobilePad.cameras = [camcontrol];
	}

	/*
	public function addVirtualPadCamera()
		return addMobilePadCamera();
	*/
	#end
	
	override function create()
	{
		super.create();
		
		if (!FlxTransitionableState.skipNextTransOut)
		{
			openSubState(Type.createInstance(transitionOutState ?? _defaultTransState, [TransitionStatus.OUT]));
		}
		
		FlxTransitionableState.skipNextTransOut = false;
		
		PluginsManager.callOnScripts('onStateCreate');
	}
	
	/**
	 * Sorts a `FlxTypedGroup` based on objects `zIndex`.
	 * 
	 * used for stage layering primarily
	 * @param group 
	 */
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	override function update(elapsed:Float)
	{
		final oldStep:Int = curStep;
		
		updateCurStep();
		updateBeat();
		
		if (oldStep != curStep)
		{
			if (curStep > 0) stepHit();
			
			if (PlayState.SONG != null)
			{
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}
		
		final scriptArgs = [elapsed];
		scriptGroup.call('onUpdate', scriptArgs);
		PluginsManager.callOnScripts('onUpdate', scriptArgs);
		super.update(elapsed);
	}
	
	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}
	
	private function rollbackSection():Void
	{
		if (curStep < 0) return;
		
		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				
				curSection++;
			}
		}
		
		if (curSection > lastSection) sectionHit();
	}
	
	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}
	
	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		
		var stepOffset:Float = (((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet);
		curStep = Math.floor(curDecStep = (lastChange.stepTime + stepOffset));
	}
	
	public static function getState():MusicBeatState
	{
		return cast FlxG.state;
	}
	
	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
		scriptGroup.call('onStepHit', []);
		PluginsManager.callOnScripts('onStepHit');
	}
	
	public function beatHit():Void
	{
		scriptGroup.call('onBeatHit', []);
		PluginsManager.callOnScripts('onBeatHit');
	}
	
	public function sectionHit():Void
	{
		scriptGroup.call('onSectionHit', []);
		PluginsManager.callOnScripts('onSectionHit');
	}
	
	function getBeatsOnSection():Float
	{
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4.0;
	}
	
	@:access(funkin.states.FreeplayState)
	override function startOutro(onOutroComplete:() -> Void)
	{
		FlxG.sound?.music?.fadeTween?.cancel();
		FreeplayState.vocals?.fadeTween?.cancel();
		@:nullSafety(Off)
		if (FlxG.sound != null && FlxG.sound.music != null) FlxG.sound.music.onComplete = null;
		
		if (!FlxTransitionableState.skipNextTransIn)
		{
			openSubState(Type.createInstance(transitionInState ?? _defaultTransState, [TransitionStatus.IN, onOutroComplete]));
			return;
		}
		
		FlxTransitionableState.skipNextTransIn = false;
		
		super.startOutro(onOutroComplete);
	}
	
	override function destroy()
	{
        #if TOUCH_CONTROLS
        if (trackedinputsNOTES.length > 0)
			controls.removeVirtualControlsInput(trackedinputsNOTES);

		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		super.destroy();

		if (mobilePad != null)
			mobilePad = FlxDestroyUtil.destroy(mobilePad);

		if (mobilec != null)
			mobilec = FlxDestroyUtil.destroy(mobilec);
        #end
		scriptGroup.call('onDestroy');
		
		scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
		
		super.destroy();
	}
	
	override function closeSubState()
	{
		scriptGroup.call('onCloseSubState', []);
		super.closeSubState();
	}
}
