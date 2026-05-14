package funkin.backend;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.actions.FlxActionInput;

import funkin.input.Controls;
import funkin.data.*;
import funkin.scripts.*;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}
	
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;
	
	inline function get_controls():Controls return Controls.instance;
	
	public var scripted:Bool = false;
	public var scriptName:String = '';
	public var scriptPrefix:String = 'substates';
	public var scriptGroup:ScriptGroup = new ScriptGroup();
	
	public function initStateScript(?scriptName:String, callOnLoad:Bool = true):Bool
	{
		if (scriptName == null)
		{
			final stateName = Type.getClassName(Type.getClass(this)).split('.').pop();
			scriptName = stateName ?? '???';
		}
		
		this.scriptName = scriptName;
		
		final scriptFile = FunkinScript.getPath('scripts/$scriptPrefix/$scriptName');
		
		if (FunkinAssets.exists(scriptFile))
		{
			var _script = FunkinScript.fromFile(scriptFile);
			if (_script.__garbage)
			{
				_script = FlxDestroyUtil.destroy(_script);
				return false;
			}
			
			scriptGroup.parent = this;
			
			Logger.log('script [$scriptName] initialized', NOTICE);
			
			scriptGroup.addScript(_script);
			scripted = true;
		}
		
		if (callOnLoad) scriptGroup.call('onLoad', []);
		
		return scripted;
	}
	
	public function refreshZ(?group:FlxTypedGroup<FlxBasic>)
	{
		group ??= FlxG.state;
		group.sort(SortUtil.sortByZ, flixel.util.FlxSort.ASCENDING);
	}

    #if TOUCH_CONTROLS
	public var mobilePad:MobilePad; //this will be changed later
	public static var mobilec:MobileControls;
	var trackedinputsUI:Array<FlxActionInput> = [];
	var trackedinputsNOTES:Array<FlxActionInput> = [];

	public function addMobilePad(?DPad:String, ?Action:String) {
		mobilePad = new MobilePad(DPad, Action);
		add(mobilePad);
		controls.setMobilePadUI(mobilePad, DPad, Action);
		trackedinputsUI = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
		mobilePad.alpha = ClientPrefs.mobilePadAlpha;
	}

	/*
	public function addVirtualPad(?DPad:String, ?Action:String) {
		return addMobilePad(DPad, Action);
	}
	*/

	public function addMobileControls() {
		mobilec = new MobileControls();

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

	public function removeMobilePad() {
		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		if (mobilePad != null)
			remove(mobilePad);
	}

	public function addMobilePadCamera() {
		var camcontrol = new flixel.FlxCamera();
		camcontrol.bgColor.alpha = 0;
		FlxG.cameras.add(camcontrol, false);
		mobilePad.cameras = [camcontrol];
	}

	/*
	public function removeVirtualPad()
		return removeMobilePad();

	public function addVirtualPadCamera()
		return addMobilePadCamera();
	*/
	#end
	
	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;
		
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
		
		scriptGroup.call('onUpdate', [elapsed]);
		
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
	
	function getBeatsOnSection():Float
	{
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4.0;
	}
	
	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}
	
	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		
		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}
	
	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
		scriptGroup.call('onStepHit', [curStep]);
	}
	
	public function beatHit():Void
	{
		scriptGroup.call('onBeatHit', [curBeat]);
	}
	
	public function sectionHit()
	{
		scriptGroup.call('onSectionHit');
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
		scriptGroup.call('onDestroy', []);
		
		scriptGroup = FlxDestroyUtil.destroy(scriptGroup);
		
		super.destroy();
	}
}
