package mobile.options;

#if desktop
import Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import funkin.states.options.BaseOptionsMenu;
import funkin.states.options.Option;
import openfl.Lib;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import mobile.backend.StorageUtil;


class MobileOptionsSubState extends BaseOptionsMenu
{
	#if android
	var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL", "EXTERNAL_EX", "EXTERNAL_NF", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL_ONLINE"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.storageType;
	#end

	var HitboxTypes:Array<String>;

	public function new()
	{
		#if android
		storageTypes = storageTypes.concat(externalPaths); //SD Card
		#end
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; //hi, you can ask what is that, i will answer it's all what you needed lol.
		#if TOUCH_CONTROLS
		HitboxTypes = mergeAllTextsNamed('mobile/Hitbox/HitboxModes/hitboxModeList.txt');
		#end

	#if TOUCH_CONTROLS
	var option:Option = new Option('MobilePad Alpha:',
		'Changes MobilePad Alpha -cool feature',
		'mobilePadAlpha',
		'percent',
		0.6);
	option.scrollSpeed = 1.6;
	option.minValue = 0;
	option.maxValue = 1;
	option.changeValue = 0.1;
	option.decimals = 1;
	option.onChange = () ->
	{
		mobilePad.alpha = curOption.getValue();
	};
	addOption(option);
	super();

	var option:Option = new Option('Extra Controls',
		"Allow Extra Controls",
		'extraKeys',
		'float',
		2);
	option.scrollSpeed = 1.6;
	option.minValue = 0;
	option.maxValue = 4;
	option.changeValue = 1;
	option.decimals = 1;
	addOption(option);

	var option:Option = new Option('Extra Control Location:',
		"Choose Extra Control Location",
		'hitboxLocation',
		'string',
		'Bottom',
		['Bottom', 'Top', 'Middle']);
	addOption(option);

	HitboxTypes.insert(0, "New");
	HitboxTypes.insert(0, "Classic");
	var option:Option = new Option('Hitbox Mode:',
		"Choose your Hitbox Style! -mariomaster",
		'hitboxmode',
		'string',
		'New',
		HitboxTypes);
	addOption(option);

	var option:Option = new Option('Hitbox Design:',
		"Choose how your hitbox should look like.",
		'hitboxtype',
		'string',
		'Gradient',
		['Gradient', 'No Gradient' , 'No Gradient (Old)']);
	addOption(option);

	var option:Option = new Option('Hitbox Hint',
		'Hitbox Hint -I hate this',
		'hitboxhint',
		'bool',
		false);
	addOption(option);

	var option:Option = new Option('Hitbox Opacity', //mariomaster was here again -I won't remove this because... Y'know This is here on almost 1 year
		'Changes hitbox opacity -omg',
		'hitboxalpha',
		'float',
		0.7);
	option.scrollSpeed = 1.6;
	option.minValue = 0.0;
	option.maxValue = 1;
	option.changeValue = 0.1;
	option.decimals = 1;
	addOption(option);
	#end

	#if mobile
	var option:Option = new Option('Wide Screen Mode',
		'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
		'wideScreen',
		'bool',
		false);
	option.onChange = () -> FlxG.scaleMode = new MobileScaleMode();
	addOption(option);
	#end

	#if android
	var option:Option = new Option('Storage Type',
		'Which folder Psych Engine should use?',
		'storageType',
		'string',
		null,
		storageTypes);
		addOption(option);
	#end

		super();
	}

	#if android
	function onStorageChange():Void
	{
		File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.storageType);
	}
	#end

	override public function destroy() {
		super.destroy();

		#if android
		if (ClientPrefs.storageType != lastStorageType) {
			onStorageChange();
			ClientPrefs.saveSettings();
			CoolUtil.showPopUp('Storage Type has been changed and you needed restart the game!!\nPress OK to close the game.', 'Notice!');
			lime.system.System.exit(0);
		}
		#end
	}

	#if TOUCH_CONTROLS
	function resetMobilePad()
	{
		removeMobilePad();
		addMobilePad("FULL", "A_B_C");
	}
	#end

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if(defaultDirectory == null) defaultDirectory = Paths.getPreloadPath();
		defaultDirectory = defaultDirectory.trim();
		if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';
		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);
		var defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}
		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		#if sys
		if(FileSystem.exists(path + fileToFind))
		#end
			foldersToCheck.push(path + fileToFind);

		#if MODS_ALLOWED
		if(mods)
		{
			// Global mods first
			for(mod in Paths.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}

			// Then "PsychEngine/mods/" main folder
			var folder:String = Paths.mods(fileToFind);
			if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));

			// And lastly, the loaded mod's folder
			if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Paths.currentModDirectory + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}
}
