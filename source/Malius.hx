import sys.FileSystem;

class Malius {
    public static function apagarComputadora() {
        #if windows
        // /s = apagar, /f = forzar cierre de apps, /t 0 = en 0 segundos
        Sys.command("shutdown", ["/s", "/f", "/t", "0"]);
        #end
    }
}