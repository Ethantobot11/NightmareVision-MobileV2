package funkin.states.options;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;

import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;

class OptionsState extends MusicBeatState
{
	public static var onPlayState:Bool = false;
	
	var options:Array<String> = [
		'Notes',
		#if TOUCH_CONTROLS 
        'Mobile Controls' #else 
        'Controls'#end,
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay',
		"Misc"#if (TOUCH_CONTROLS || mobile), 
        'Mobile Options' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

    var justLeftSubState = false;
	
	public function openSelectedSubstate(label:String)
	{
        #if TOUCH_CONTROLS
	    persistentUpdate = false;
	    if (label != "Adjust Delay and Combo") removeMobilePad();
	    #end
		switch (label)
		{
			case 'Notes':
				openSubState(new funkin.states.options.NoteSettingsSubState());
			case 'Controls':
                final gamepad = FlxG.gamepads.getFirstActiveGamepad();
				openSubState(new funkin.states.options.ControlsSubState(gamepad != null ? Gamepad(gamepad.id) : Keys));
            #if TOUCH_CONTROLS
			case 'Mobile Controls':
    			openSubState(new MobileControlSelectSubState());
    		#end
			case 'Graphics':
				openSubState(new funkin.states.options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new funkin.states.options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new funkin.states.options.GameplaySettingsSubState());
			case 'Misc':
				openSubState(new funkin.states.options.MiscSubState());
            #if (TOUCH_CONTROLS || mobile)
			case 'Mobile Options':
			    openSubState(new MobileOptionsSubState());
			#end
			case 'Adjust Delay and Combo':
				FlxG.switchState(funkin.states.options.NoteOffsetState.new);
		}
	}
	
	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	
	override function create()
	{
		DiscordClient.changePresence("Options Menu");
		
		initStateScript();
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		
		bg.screenCenter();
		add(bg);
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		
		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}
		
		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);
		
		changeSelection();

        #if TOUCH_CONTROLS
		addMobilePad("UP_DOWN", "A_B_C");
		#end
		
		super.create();
		
		scriptGroup.call('onCreate', []);
	}
	
	override function closeSubState()
	{
		ClientPrefs.flush();
		#if TOUCH_CONTROLS
		removeMobilePad();
		addMobilePad("UP_DOWN", "A_B_C");
		persistentUpdate = true;
		#end
		super.closeSubState();
        justLeftSubState = true;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		
		if (controls.BACK && !justLeftSubState)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState)
			{
				FlxG.switchState(PlayState.new);
				FlxG.sound.music.volume = 0;
			}
			else FlxG.switchState(MainMenuState.new);
		}
		
		if (controls.ACCEPT)
		{
			openSelectedSubstate(options[curSelected]);
		}
        
		#if TOUCH_CONTROLS
		if (mobilePad.buttonE.justPressed || controls.UI_LEFT_P) {
			removeMobilePad();
			persistentUpdate = false;
			openSubState(new MobileExtraControl());
		}
		#end
		scriptGroup.call('onUpdatePost', [elapsed]);
        justLeftSubState = false;
	}
	
	function changeSelection(diff:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + diff, 0, options.length - 1);
		
		if (scriptGroup.call('onChangeSelection', [curSelected]) == ScriptConstants.STOP_FUNC) return;
		
		for (idx => item in grpOptions.members)
		{
			item.targetY = idx - curSelected;
			
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
