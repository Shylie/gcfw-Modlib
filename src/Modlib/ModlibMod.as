package Modlib 
{
	import Bezel.Bezel;
	import Bezel.BezelCoreMod;
	import Bezel.Lattice.Lattice;
	import Bezel.Logger;
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Shy
	 */
	public class ModlibMod extends MovieClip implements BezelCoreMod 
	{
		public function get MOD_NAME(): String { return ModlibConstants.MOD_NAME; }
		public function get VERSION(): String { return "0.1.0"; }
		
		CONFIG::debug
		public function get COREMOD_VERSION(): String { return String(Math.random()); }
		CONFIG::release
		public function get COREMOD_VERSION(): String { return VERSION; }
		
		public function get BEZEL_VERSION(): String { return "2.0.6"; }
		
		public static var instance: ModlibMod;
		public var bezel: Bezel;
		public var logger: Logger;
		
		public function ModlibMod() 
		{
			instance = this;
			
			logger = Logger.getLogger(MOD_NAME);
		}
		
		public function bind(modLoader: Bezel, gameObjects: Object): void 
		{
			bezel = modLoader;
		}
		
		public function unload():void 
		{
			
		}
		
		public function loadCoreMod(lattice: Lattice): void 
		{
			installIngameInitializer2Coremod(lattice);
			installIngameCoreCoremod(lattice);
		}
		
		private function installIngameInitializer2Coremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/entity/IngameInitializer2.class.asasm";
			const CLASS_NAME: String = "IngameInitializer2";
			
			const SEARCH_RESET_ARRAYS: RegExp = /trait method QName\(PackageNamespace\(""\), "resetArrays"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_RESET_ARRAYS);
			if (checkOffset(offset, CLASS_NAME, SEARCH_RESET_ARRAYS))
			{
				return;
			}
			
			const SEARCH_SET_MONSTERS_WAITING_IN_WAVE: RegExp = /setproperty QName\(PackageNamespace\(""\), "monstersWaitingInWave"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_SET_MONSTERS_WAITING_IN_WAVE, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_SET_MONSTERS_WAITING_IN_WAVE))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0,
				' \
				getlocal0 \n \
				newarray 0 \n \
				setproperty QName(PackageNamespace(""), "' + ModlibConstants.MODDED_PROJECTILE_ARRAY_ID + '") \n \
				getlocal0 \n \
				newarray0 \n \
				setproperty QName(PackageNamespace(""), "' + ModlibConstants.MODDED_BUILDING_ARRAY_ID + '") \
				');
				
			successfulPatch(CLASS_NAME);
		}
		
		private function installIngameCoreCoremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/entity/IngameCore.class.asasm";
			const CLASS_NAME: String = "IngameCore";
			
			const SEARCH_FREE_BUILDINGS_LEFT: RegExp = /trait slot QName\(PackageNamespace\(""\), "freeBuildingsLeft"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_FREE_BUILDINGS_LEFT);
			if (checkOffset(offset, CLASS_NAME, SEARCH_FREE_BUILDINGS_LEFT))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset - 1, 0,
				' \
				trait slot QName(PackageNamespace(""), "' + ModlibConstants.MODDED_PROJECTILE_ARRAY_ID + '") type QName(PackageNamespace(""), "Array") \n \
				trait slot QName(PackageNamespace(""), "' + ModlibConstants.MODDED_BUILDING_ARRAY_ID + '") type QName(PackageNamespace(""), "Array") \
				');
				
			const SEARCH_DO_ENTER_FRAME_GENERAL: RegExp = /trait method QName\(PrivateNamespace\("com.giab.games.gcfw.ingame:IngameCore"\), "doEnterFrameGeneral"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_DO_ENTER_FRAME_GENERAL);
			if (checkOffset(offset, CLASS_NAME, SEARCH_DO_ENTER_FRAME_GENERAL))
			{
				return;
			}
			
			const SEARCH_GETPROPERTY_WATCHTOWER_SHOTS: RegExp = /getproperty QName\(PackageNamespace\(""\), "watchTowerShots"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_GETPROPERTY_WATCHTOWER_SHOTS, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_GETPROPERTY_WATCHTOWER_SHOTS))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset - 2, 0,
				' \
				getlex QName(PackageNamespace("com.giab.games.gcfw"), "GV") \n \
				getproperty QName(PackageNamespace(""), "main") \n \
				getproperty QName(PackageNamespace(""), "bezel") \n \
				pushstring "' + MOD_NAME + '" \n \
				callproperty QName(PackageNamespace(""), "getModByName"), 1 \n \
				getproperty QName(PackageNamespace(""), "loaderInfo") \n \
				getproperty QName(PackageNamespace(""), "applicationDomain") \n \
				pushstring "Modlib.ModdedProjectile" \n \
				callproperty QName(PackageNamespace(""), "getDefinition"), 1 \n \
				getlocal0 \n \
				getproperty QName(PackageNamespace(""), "speedMultiplier") \n \
				callproperty QName(PackageNamespace(""), "doEnterFrameAll"), 1 \
				');
			
			const SEARCH_DO_ENTER_FRAME_PLAYING: RegExp = /trait method QName\(PrivateNamespace\("com.giab.games.gcfw.ingame:IngameCore"\), "doEnterFramePlaying"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_DO_ENTER_FRAME_PLAYING);
			if (checkOffset(offset, CLASS_NAME, SEARCH_DO_ENTER_FRAME_PLAYING))
			{
				return;
			}
			
			const SEARCH_GETPROPERTY_TRAPS: RegExp = /getproperty QName\(PackageNamespace\(""\), "traps"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_GETPROPERTY_TRAPS, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_GETPROPERTY_TRAPS))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset - 2, 0,
				' \
				getlex QName(PackageNamespace("com.giab.games.gcfw"), "GV") \n \
				getproperty QName(PackageNamespace(""), "main") \n \
				getproperty QName(PackageNamespace(""), "bezel") \n \
				pushstring "' + MOD_NAME + '" \n \
				callproperty QName(PackageNamespace(""), "getModByName"), 1 \n \
				getproperty QName(PackageNamespace(""), "loaderInfo") \n \
				getproperty QName(PackageNamespace(""), "applicationDomain") \n \
				pushstring "Modlib.ModdedBuilding" \n \
				callproperty QName(PackageNamespace(""), "getDefinition"), 1 \n \
				getlocal0 \n \
				getproperty QName(PackageNamespace(""), "speedMultiplier") \n \
				callproperty QName(PackageNamespace(""), "doEnterFrameAll"), 1 \
				');
			
			successfulPatch(CLASS_NAME);
		}
		
		private function checkOffset(offset: int, className: String, search: RegExp): Boolean
		{
			if (offset == -1)
			{
				logger.log("", "Unable to find a location for " + className + " Coremod at: /" + search.source + "/");
				return true;
			}
			else
			{
				return false;
			}
		}
		
		private function successfulPatch(className: String): void
		{
			logger.log("", "Successfully patched class " + className);
		}
	}
}