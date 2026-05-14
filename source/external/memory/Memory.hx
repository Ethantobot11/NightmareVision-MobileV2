package external.memory;

#if cpp
#if (windows || linux)
@:buildXml('<include name="../../../../source/external/memory/build.xml" />')
#elseif android
@:buildXml('<include name="../../../../source/external/memory/build.xml" />')
#elseif (ios || macos)
@:buildXml('<include name="../../../source/external/memory/build.xml" />')
#end
@:include("Memory.h")
extern class Memory
{
	/**
	 * Returns the current resident set size (physical memory use) measured
	 * in bytes, or zero if the value cannot be determined on this OS.
	 */
	@:native("getCurrentRSS")
	public static function getCurrentUsage():Float;
}
#else

// Fallback class for Mac, Linux, and others so the code doesn't crash
class Memory 
{
	public static function getCurrentUsage():Float {
		return 0.0;
	}
}
#end
