//cambios en el escritorio

package;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class MaliusDestrok 
{
    private static var personalDesktopPath:String;
    private static var publicDesktopPath:String; // públic
    private static var backupPath:String;
    private static var HiddenApps:Array<{ogRute:String, newRute:String}> = []; 
    private static var createdTxtFiles:Array<String> = [];

    public static function inicializar() {
        var userProfile = Sys.environment()["USERPROFILE"];
        personalDesktopPath = Path.join([userProfile, "Desktop"]);
        
        var publicProfile = Sys.environment()["PUBLIC"];
        if (publicProfile != null) {
            publicDesktopPath = Path.join([publicProfile, "Desktop"]);
        } else {
            publicDesktopPath = "C:\\Users\\Public\\Desktop"; // Default route on failure
        }
        
        backupPath = Path.join([Sys.getCwd(), "respaldo_escritorio"]);
    }

    public static function activateEffect() {
        if (personalDesktopPath == null) inicializar();
        
        if (!FileSystem.exists(backupPath)) {
            FileSystem.createDirectory(backupPath);
        }

        try {
            var foldersToClean = [personalDesktopPath, publicDesktopPath];

            for (desk in foldersToClean) {
                if (FileSystem.exists(desk)) {
                    for (archive in FileSystem.readDirectory(desk)) {
                        var ogRute = Path.join([desk, archive]);
                        
                        if (!FileSystem.isDirectory(ogRute) && archive != "desktop.ini") {
                            var desName = (desk == publicDesktopPath ? "PUB_" : "PER_") + archive;
                            var newRute = Path.join([backupPath, desName]);
                            
                            File.copy(ogRute, newRute);
                            FileSystem.deleteFile(ogRute);
                            
                            HiddenApps.push({ogRute: ogRute, newRute: newRute});
                        }
                    }
                }
            }

            var scareMessages:Array<String> = [
                "AYÚDAME", "NO SIENTAS MAS DOLOR", "NO TE ENGAÑES A TI MISMO", "DEBES SER CASTIGADO", "ERROR DEL SISTEMA", "NO DEBES LEER ESTO", "VETE DE AQUI"
            ];

            for (i in 0...25) { 
                var randomName = "ERROR_" + Std.random(99999) + ".txt";
                var rutaTxt = Path.join([personalDesktopPath, randomName]);
                var contenido = scareMessages[Std.random(scareMessages.length)];
                
                File.saveContent(rutaTxt, contenido);
                createdTxtFiles.push(rutaTxt);
            }

            updateWindowsDesktop();

        } catch(e:Dynamic) {
            trace("Error ejecutando el efecto: " + e);
        }
    }

    public static function disableEffect() {
        try {
            for (rutaTxt in createdTxtFiles) {
                if (FileSystem.exists(rutaTxt)) FileSystem.deleteFile(rutaTxt);
            }
            createdTxtFiles = [];

            for (item in HiddenApps) {
                if (FileSystem.exists(item.newRute)) {
                    File.copy(item.newRute, item.ogRute);
                    FileSystem.deleteFile(item.newRute);
                }
            }
            HiddenApps = [];

            if (FileSystem.exists(backupPath)) {
                FileSystem.deleteDirectory(backupPath);
            }
            #if windows
            WindowsData.restoreIconPositions();
            #end
            updateWindowsDesktop();

        } catch(e:Dynamic) {
            trace("Error " + e);
        }
    }

    private static function updateWindowsDesktop() {
        #if windows
        WindowsData.refreshDesktop();
        #end
    }

    public static function glitcherPositions() {
        WindowsData.scatterIconsRandom();
    }
}