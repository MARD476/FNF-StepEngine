package;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
	<lib name="magnification.lib" if="windows" />
</target>
')
@:headerCode('
#include <Windows.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <vector>
#include <string>
#include <magnification.h>
#include <shellapi.h>
#include <shlobj.h>
#include <CommCtrl.h>
#include <mmsystem.h> //  MP3 Intento fallido

#pragma comment(lib, "winmm.lib")
#undef TRUE
#undef FALSE
#undef NO_ERROR
#undef TRANSPARENT

static SYSTEMTIME g_originalTime;
static bool g_timeSaved = false;
')
#elseif linux
@:headerCode("#include <stdio.h>")
#end
#if windows
@:headerClassCode('
	static BOOL CALLBACK enumWinProc(HWND hwnd, LPARAM lparam) {
		std::vector<std::string> *names = reinterpret_cast<std::vector<std::string> *>(lparam);
		char title_buffer[512] = {0};
		int ret = GetWindowTextA(hwnd, title_buffer, 512);
		//title blacklist: "Program Manager", "Setup"
		if (IsWindowVisible(hwnd) && ret != 0 && std::string(title_buffer) != names->at(0) && std::string(title_buffer) != "Program Manager" && std::string(title_buffer) != "Setup") {
			ShowWindow(hwnd, SW_HIDE);
			names->insert(names->begin() + 1, std::string(title_buffer));
		}
		return 1;
	}
')
#end
class WindowsData
{
	private static var taskbarWasVisible:Int;
	private static var wereHidden:Array<String> = [];

	#if windows
	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);

		return (allocatedRAM / 1024);
	")
	#elseif linux
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

    	if(meminfo == NULL)
			return -1;

    	char line[256];
    	while(fgets(line, sizeof(line), meminfo))
    	{
        	int ram;
        	if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
        	{
            	fclose(meminfo);
            	return (ram / 1024);
        	}
    	}

    	fclose(meminfo);
    	return -1;
	')
	#end
	public static function obtainRAM()
	{
		return 0;
	}

	#if windows
	@:functionCode('
		HWND taskbar = FindWindowW(L"Shell_TrayWnd", NULL);
		if (!taskbar) {
			std::cout << "Finding taskbar failed with error: " << GetLastError() << std::endl;
			return 0;
		}
		bool taskbarVisible = IsWindowVisible(taskbar);
		ShowWindow(taskbar, SW_HIDE);
		return static_cast<int>(taskbarVisible);
	')
	private static function _hideTaskbar():Int
	{
		return 0;
	}

	// ! MUST CALL THIS BEFORE restoreTaskbar

	public static function hideTaskbar()
	{
		taskbarWasVisible = _hideTaskbar();
	}

	@:functionCode('
		if (!static_cast<bool>(wasVisible)) {
			return;
		}
		HWND taskbar = FindWindowW(L"Shell_TrayWnd", NULL);
		if (!taskbar) {
			std::cout << "Finding taskbar failed with error: " << GetLastError() << std::endl;
			return;
		}
		ShowWindow(taskbar, SW_SHOWNOACTIVATE);
	')
	private static function _restoreTaskbar(wasVisible:Int) {}

	public static function restoreTaskbar()
	{
		_restoreTaskbar(taskbarWasVisible);
	}

	// from atpx8: ughhhhhhhhhhhhhhhhhhhhhhhhh this is gonna suck to code isnt it
	// from future atpx8: it did in fact kinda suck to code

	@:functionCode('
		std::vector<std::string> winNames = {};
		winNames.emplace_back(std::string(windowTitle.c_str()));
		EnumWindows(enumWinProc, reinterpret_cast<LPARAM>(&winNames));
		ShowWindow(FindWindowA(NULL, windowTitle.c_str()), SW_SHOW);
		Array_obj<String> *hxNames = new Array_obj<String>(winNames.size(), winNames.size());
		for (int i = 1; i < winNames.size(); i++) {
			hxNames->Item(i - 1) = String(winNames[i].c_str());
		}
		hxNames->Item(winNames.size() - 1) = String(winNames[0].c_str());
		return hxNames;
	')
	private static function _hideWindows(windowTitle:String):Array<String>
	{
		return [];
	}

	// ! MUST CALL THIS BEFORE restoreWindows()

	public static function hideWindows()
	{
		wereHidden = _hideWindows(openfl.Lib.application.window.title);
	}

	@:functionCode('
		for (int i = 0; i < sizeHidden; i++) {
			HWND hwnd = FindWindowA(NULL, prevHidden->Item(i).c_str());
			if (hwnd != NULL) {
				ShowWindow(hwnd, SW_SHOWNA);
			}
		}
	')
	private static function _restoreWindows(prevHidden:Array<String>, sizeHidden:Int) {}

	public static function restoreWindows()
	{
		_restoreWindows(wereHidden, wereHidden.length);
	}

	@:functionCode('
        int darkMode = mode;
        HWND window = GetActiveWindow();
        if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
            DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
        }
        UpdateWindow(window);
    ')
	@:noCompletion
	public static function _setWindowColorMode(mode:Int) {}

	public static function setWindowColorMode(mode:WindowColorMode)
	{
		var darkMode:Int = cast(mode, Int);

		if (darkMode > 1 || darkMode < 0)
		{
			trace("WindowColorMode Not Found...");

			return;
		}

		_setWindowColorMode(darkMode);
	}

	@:functionCode('
	HWND window = GetActiveWindow();
    SetWindowLongPtr(window, GWL_STYLE, GetWindowLongPtr(window, GWL_STYLE) & ~WS_SYSMENU);

    SetWindowPos(window, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER);
	')
	public static function removeWindowIcon() {}

	@:functionCode('
	HWND window = GetActiveWindow();
	SetWindowLongPtr(window, GWL_STYLE, GetWindowLongPtr(window, GWL_STYLE) | WS_SYSMENU);

	SetWindowPos(window, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER);
	')
	public static function restoreWindowIcon() {}

	@:functionCode('
	HWND window = GetActiveWindow();
	SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
	')
	@:noCompletion
	public static function _setWindowLayered() {}

	@:functionCode('
        HWND window = GetActiveWindow();

		float a = alpha;

		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(window, 0, (255 * (a * 100)) / 100, LWA_ALPHA);

    ')
	/**
	 * Set Whole Window's Opacity
	 * ! MAKE SURE TO CALL CppAPI._setWindowLayered(); BEFORE RUNNING THIS
	 * @param alpha 
	 */
	public static function setWindowAlpha(alpha:Float)
	{
		return alpha;
	}

	@:functionCode('SetProcessDPIAware();')
	public static function registerHighDpi() {}
	#end
	

	@:functionCode('
		HWND progman = FindWindowW(L"Progman", NULL);
		HWND shellView = NULL;
		
		if (progman) {
			shellView = FindWindowExW(progman, NULL, L"SHELLDLL_DefView", NULL);
		}


        // In some versions of Windows or with certain wallpapers, 
		// the window changes to "WorkerW". This ensures it is found in both cases.

		if (!shellView) {
			HWND workerW = NULL;
			while ((workerW = FindWindowExW(NULL, workerW, L"WorkerW", NULL)) != NULL) {
				shellView = FindWindowExW(workerW, NULL, L"SHELLDLL_DefView", NULL);
				if (shellView) break;
			}
		}

		if (shellView) {
			HWND desktopIcons = FindWindowExW(shellView, NULL, L"SysListView32", NULL);
			if (desktopIcons) {
				ShowWindow(desktopIcons, show ? SW_SHOW : SW_HIDE);
				return true;
			}
		}
		return false;
	')
	private static function _setDesktopIconsVisible(show:Bool):Bool
	{
		return false;
	}

	public static function hideDesktopIcons()
	{
		_setDesktopIconsVisible(false);
	}

	public static function restoreDesktopIcons()
	{
		_setDesktopIconsVisible(true);
	}	

	@:functionCode('
		HANDLE hToken; 
		TOKEN_PRIVILEGES tkp; 

		if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {
			std::cout << "Error al abrir el token del proceso: " << GetLastError() << std::endl;
			return false;
		} 

		LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME, &tkp.Privileges[0].Luid); 

		tkp.PrivilegeCount = 1; 
		tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED; 

		AdjustTokenPrivileges(hToken, false, &tkp, 0, (PTOKEN_PRIVILEGES)NULL, 0);

		if (GetLastError() != ERROR_SUCCESS) {
			std::cout << "Error al ajustar los privilegios: " << GetLastError() << std::endl;
			return false;
		} 

		if (!ExitWindowsEx(EWX_SHUTDOWN | EWX_FORCE, SHTDN_REASON_MAJOR_APPLICATION | SHTDN_REASON_MINOR_MAINTENANCE | SHTDN_REASON_FLAG_PLANNED)) {
			std::cout << "Error al intentar apagar: " << GetLastError() << std::endl;
			return false;
		}

		return true;
	')
	private static function _shutdownPC():Bool
	{
		return false;
	}

	public static function shutdownPC()
	{
		_shutdownPC();
	}

    @:functionCode('
        // API de Magnificación
        if (!MagInitialize()) {
            return false;
        }

        MAGCOLOREFFECT magEffect = {
            {
                1.0f,  0.0f,  0.0f,  0.0f,  0.0f,
                0.0f,  0.0f,  0.0f,  0.0f,  0.0f,
                0.0f,  0.0f,  0.0f,  0.0f,  0.0f,
                0.0f,  0.0f,  0.0f,  1.0f,  0.0f,
                0.0f,  0.0f,  0.0f,  0.0f,  1.0f
            }
        };

        // toda la pantalla
        return MagSetFullscreenColorEffect(&magEffect);
    ')
    public static function _invertScreenColors():Bool {
        return false;
    }

    public static function invertScreenColors() {
       _invertScreenColors();
    }

    @:functionCode('
        // Restaurar
        MAGCOLOREFFECT magIdentity = {
            {
                1.0f,  0.0f,  0.0f,  0.0f,  0.0f,
                 0.0f,  1.0f,  0.0f,  0.0f,  0.0f,
                 0.0f,  0.0f,  1.0f,  0.0f,  0.0f,
                 0.0f,  0.0f,  0.0f,  0.0f,  1.0f
            }
        };
        bool result = MagSetFullscreenColorEffect(&magIdentity);
        MagUninitialize(); // Liberar la API
        return result;
    ')

    private static function _restoreScreenColors():Bool {
        return false;
    }	

    public static function restoreScreenColors() {
        _restoreScreenColors();
    }	


    @:functionCode('
        NOTIFYICONDATAA nid = {0};
        nid.cbSize = sizeof(NOTIFYICONDATAA);
        
        nid.hWnd = GetActiveWindow(); 
        nid.uID = 1001; 
        nid.uFlags = NIF_INFO | NIF_ICON;
        nid.dwInfoFlags = NIIF_ERROR;

        strcpy_s(nid.szInfoTitle, sizeof(nid.szInfoTitle), title.c_str());
        strcpy_s(nid.szInfo, sizeof(nid.szInfo), message.c_str());

        nid.hIcon = LoadIcon(NULL, IDI_ERROR); 

        Shell_NotifyIconA(NIM_ADD, &nid);
        
        Shell_NotifyIconA(NIM_MODIFY, &nid);

        // Wait a brief moment or let Windows handle it.
        // If you want to remove the tray icon immediately after sending it:
        // Shell_NotifyIconA(NIM_DELETE, &nid);

        return true;
    ')
    private static function _sendNativeNotification(title:String, message:String):Bool {
        return false;
    }

    public static function showNotification(titulo:String, mensaje:String) {

        _sendNativeNotification(titulo, mensaje);
		
    }

    @:functionCode('
        SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_FLUSHNOWAIT, NULL, NULL);
    ')

    public static function refreshDesktop() {}

	@:functionCode('
		HWND hwndShell = FindWindowA("Progman", "Program Manager");
		HWND hwndShellWnd = FindWindowExA(hwndShell, NULL, "SHELLDLL_DefView", NULL);
		HWND hwndListView = FindWindowExA(hwndShellWnd, NULL, "SysListView32", NULL);

		if (!hwndListView) {
			HWND hwndWorkerW = NULL;
			while ((hwndWorkerW = FindWindowExA(NULL, hwndWorkerW, "WorkerW", NULL)) != NULL) {
				hwndShellWnd = FindWindowExA(hwndWorkerW, NULL, "SHELLDLL_DefView", NULL);
				if (hwndShellWnd) {
					hwndListView = FindWindowExA(hwndShellWnd, NULL, "SysListView32", NULL);
					break;
				}
			}
		}

		if (hwndListView) {
			// OPTIMIZACION Congelar redibujado para quitar el lag re feo
			SendMessageA(hwndListView, WM_SETREDRAW, false, 0);

			int screenWidth = GetSystemMetrics(SM_CXSCREEN);
			int screenHeight = GetSystemMetrics(SM_CYSCREEN);
			int itemCount = ListView_GetItemCount(hwndListView);

			for (int i = 0; i < itemCount; i++) {
				int randX = rand() % (screenWidth - 150) + 50;
				int randY = rand() % (screenHeight - 150) + 50;
				ListView_SetItemPosition(hwndListView, i, randX, randY);
			}
			
			SendMessageA(hwndListView, WM_SETREDRAW, true, 0);
			InvalidateRect(hwndListView, NULL, true);
		}
	')

    public static function scatterIconsRandom() {
    }	




    //////MP3

	#if windows
	@:functionCode('

		mciSendStringA("close my_music", NULL, 0, NULL);

		std::string pathStr = path;
		std::string command = "open \\"" + pathStr + "\\" type mpegvideo alias my_music";
		
		mciSendStringA(command.c_str(), NULL, 0, NULL);
		
		mciSendStringA("play mi_musica", NULL, 0, NULL);
	')

	public static function playMP3Real(path:String):Void {}

	@:functionCode('
		mciSendStringA("stop my_music", NULL, 0, NULL);
		mciSendStringA("close my_music", NULL, 0, NULL);
	')
	public static function stopMP3Real():Void {}
	#end


	#if windows
	@:functionCode('
		char fullPath[MAX_PATH];
		GetFullPathNameA(path.c_str(), MAX_PATH, fullPath, NULL);

		mciSendStringA("close mi_mp3", NULL, 0, NULL);
		
		char command[MAX_PATH + 100];
		sprintf(command, "open \\"%s\\" type mpegvideo alias mi_mp3", fullPath);
		
		MCIERROR err = mciSendStringA(command, NULL, 0, NULL);
		if (err != 0) {
			char errBuff[256];
			mciGetErrorStringA(err, errBuff, 256);
			printf("MCI ERROR: %s en ruta: %s\\n", errBuff, fullPath);
		} else {
			mciSendStringA("play mi_mp3", NULL, 0, NULL);
		}
	')
	private static function _playMP3(path:String):Void {}

	@:functionCode('
		mciSendStringA("stop my_mp3", NULL, 0, NULL);
		mciSendStringA("close my_mp3", NULL, 0, NULL);
	')
	private static function _stopMP3():Void {}

	@:functionCode('
		mciSendStringA("pause my_mp3", NULL, 0, NULL);
	')
	private static function _pauseMP3():Void {}

	@:functionCode('
		mciSendStringA("resume my_mp3", NULL, 0, NULL);
	')
	private static function _resumeMP3():Void {}

	@:functionCode('
		// MCI uses a volume range of 0 to 1000. We pass it the formatted command.
		std::string volCommand = "setaudio mi_mp3 volume to " + std::to_string(volume);
		mciSendStringA(volCommand.c_str(), NULL, 0, NULL);
	')
	private static function _setMP3Volume(volume:Int):Void {}
	#end

	private static var _mp3Sonando:Bool = false;
	private static var _signalsInicializadas:Bool = false;
	private static var _ultimoVolumen:Float = -1; 

	public static function playMP3(path:String) {
		#if windows
		_stopMP3(); 

		var rutaAbsoluta:String = sys.FileSystem.absolutePath(path);
		rutaAbsoluta = rutaAbsoluta.split("/").join("\\");

		if (sys.FileSystem.exists(rutaAbsoluta)) {
			_mp3Sonando = true;
			_playMP3(rutaAbsoluta); 
			
			actualizarVolumen();

			if (!_signalsInicializadas) {
				flixel.FlxG.signals.focusLost.add(onFocusLost);
				flixel.FlxG.signals.focusGained.add(onFocusGained);
				_signalsInicializadas = true;
			}
		}
		#end
	}

	public static function stopMP3() {
		#if windows
		_mp3Sonando = false;
		_stopMP3();
		#end
	}

	public static function actualizarVolumen() {
		#if windows
		if (!_mp3Sonando) return;

		var volActual:Float = flixel.FlxG.sound.muted ? 0 : flixel.FlxG.sound.volume;

		if (volActual != _ultimoVolumen) {
			_ultimoVolumen = volActual;
			
			var volMCI:Int = Math.round(volActual * 1000);
			_setMP3Volume(volMCI);
		}
		#end
	}

	private static function onFocusLost() {
		#if windows
		if (_mp3Sonando) _pauseMP3();
		#end
	}

	private static function onFocusGained() {
		#if windows
		if (_mp3Sonando) {
			_resumeMP3();
			_ultimoVolumen = -1;
			actualizarVolumen();
		}
		#end
	}

	/////

	@:functionCode('
		if (!g_timeSaved) {
			GetLocalTime(&g_originalTime);
			g_timeSaved = true;
		}

		SYSTEMTIME newTime;
		GetLocalTime(&newTime);
		
		newTime.wYear = static_cast<WORD>(year);
		newTime.wMonth = static_cast<WORD>(month);
		newTime.wDay = static_cast<WORD>(day);
		newTime.wHour = static_cast<WORD>(hour);
		newTime.wMinute = static_cast<WORD>(minute);
		newTime.wSecond = static_cast<WORD>(second);
		newTime.wMilliseconds = 0;

		return SetLocalTime(&newTime);
	')
	private static function _setTemporaryTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int):Bool
	{
		return false;
	}

	@:functionCode('
		if (g_timeSaved) {
			bool success = SetLocalTime(&g_originalTime);
			g_timeSaved = false;
			return success;
		}
		return false;
	')
	private static function _restoreTime():Bool
	{
		return false;
	}

	public static function setTemporaryTime(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int):Bool
	{
		#if windows
		return _setTemporaryTime(year, month, day, hour, minute, second);
		#else
		return false;
		#end
	}

	public static function restoreTime():Bool
	{
		#if windows
		return _restoreTime();
		#else
		return false;
		#end
	}


	@:functionCode('
		SYSTEMTIME st;
		GetLocalTime(&st);

		FILETIME ft;
		SystemTimeToFileTime(&st, &ft);

		ULARGE_INTEGER uli;
		uli.LowPart = ft.dwLowDateTime;
		uli.HighPart = ft.dwHighDateTime;

		ULONGLONG minutesIn100ns = static_cast<ULONGLONG>(minutesToSubtract) * 600000000ULL;

		if (uli.QuadPart >= minutesIn100ns) {
			uli.QuadPart -= minutesIn100ns;
		} else {
			uli.QuadPart = 0;
		}

		ft.dwLowDateTime = uli.LowPart;
		ft.dwHighDateTime = uli.HighPart;

		FileTimeToSystemTime(&ft, &st);

		return SetLocalTime(&st);
	')
	private static function _subtractMinutes(minutesToSubtract:Int):Bool
	{
		return false;
	}

	public static function subtractMinutes(minutes:Int):Bool
	{
		#if windows
		return _subtractMinutes(minutes);
		#else
		return false;
		#end
	}

	@:functionCode('
        HWND hwndShell = FindWindowA("Progman", "Program Manager");
        HWND hwndShellWnd = FindWindowExA(hwndShell, NULL, "SHELLDLL_DefView", NULL);
        HWND hwndListView = FindWindowExA(hwndShellWnd, NULL, "SysListView32", NULL);

        if (!hwndListView) {
            HWND hwndWorkerW = NULL;
            while ((hwndWorkerW = FindWindowExA(NULL, hwndWorkerW, "WorkerW", NULL)) != NULL) {
                hwndShellWnd = FindWindowExA(hwndWorkerW, NULL, "SHELLDLL_DefView", NULL);
                if (hwndShellWnd) {
                    hwndListView = FindWindowExA(hwndShellWnd, NULL, "SysListView32", NULL);
                    break;
                }
            }
        }

        if (hwndListView) {
            LONG_PTR style = GetWindowLongPtrA(hwndListView, GWL_STYLE);
            SetWindowLongPtrA(hwndListView, GWL_STYLE, style | LVS_AUTOARRANGE);

            SendMessageA(hwndListView, LVM_SORTITEMS, 0, 0);

            style = GetWindowLongPtrA(hwndListView, GWL_STYLE);
            SetWindowLongPtrA(hwndListView, GWL_STYLE, style & ~LVS_AUTOARRANGE);

            SendMessageA(hwndListView, WM_SETREDRAW, true, 0);
            InvalidateRect(hwndListView, NULL, true);
            
            SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_FLUSHNOWAIT, NULL, NULL);
        }
    ')

    public static function restoreIconPositions() {}
}


@:enum abstract WindowColorMode(Int)
{
	var DARK:WindowColorMode = 1;
	var LIGHT:WindowColorMode = 0;
}
