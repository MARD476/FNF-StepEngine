package;

class CppAPI
{
	#if cpp
	public static function obtainRAM():Int
	{
		return WindowsData.obtainRAM();
	}

	public static function darkMode()
	{
		WindowsData.setWindowColorMode(DARK);
	}

	public static function lightMode()
	{
		WindowsData.setWindowColorMode(LIGHT);
	}

	public static function setWindowOppacity(a:Float)
	{
		WindowsData.setWindowAlpha(a);
	}

	public static function _setWindowLayered()
	{
		WindowsData._setWindowLayered();
	}

	public static function setWallpaper(path:String)
	{
		if(path == 'old') {
			if(Wallpaper.oldWallpaper != null) {
			path = Wallpaper.oldWallpaper;
			}else{
				return;
			}}
		Wallpaper.setWallpaper(path);
	}

	public static function setOld()
	{
		Wallpaper.setOld();
	}

	public static function hideTaskbar()
	{
		WindowsData.hideTaskbar();
	}

	public static function restoreTaskbar()
	{
		WindowsData.restoreTaskbar();
	}

	public static function hideWindows()
	{
		WindowsData.hideWindows();
	}

	public static function restoreWindows()
	{
		WindowsData.restoreWindows();
	}

	public static function setTransparency(winName:String, color:Int)
	{
		Transparency.setTransparency(winName, color);
	}
	
	public static function removeWindowIcon()
	{
		WindowsData.removeWindowIcon();
	}

	public static function restoreWindowIcon()
	{
		WindowsData.restoreWindowIcon();
	}

	public static function hideDesktopIcons()
	{
		WindowsData.hideDesktopIcons();
	}

	public static function restoreDesktopIcons()
	{
		WindowsData.restoreDesktopIcons();
	}

	public static function shutdownPC()
	{
		WindowsData.shutdownPC();
	}

	public static function invertScreenColors()
	{
		WindowsData.invertScreenColors();
	}

	public static function restoreScreenColors()
	{
		WindowsData.restoreScreenColors();
	}

	public static function showNotification(titulo:String, des:String)
	{
		WindowsData.showNotification(titulo, des);
	}

	public static function setTemporaryTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int):Bool
	{
		return WindowsData.setTemporaryTime(year, month, day, hour, minute, second);
	}

	public static function restoreTime():Bool
	{
		return WindowsData.restoreTime();
	}

    public static function subtractMinutes(minutes:Int):Bool
	{
		return WindowsData.subtractMinutes(minutes);
	}

	public static function reset()
	{
		Transparency.reset();
	}
	public static function allowHighDPI() {
		WindowsData.registerHighDpi();
	}
	#end
}