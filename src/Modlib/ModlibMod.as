package Modlib 
{
	import Bezel.Bezel;
	import Bezel.BezelCoreMod;
	import Bezel.GCFW.Events.EventTypes;
	import Bezel.GCFW.Events.IngameKeyDownEvent;
	import Bezel.GCFW.Events.IngameNewSceneEvent;
	import Bezel.Lattice.Lattice;
	import Bezel.Logger;
	import Bezel.Utils.Keybind;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.SB;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author Shy
	 */
	public class ModlibMod extends MovieClip implements BezelCoreMod 
	{
		private var enforceModdedBuildingCompile: ModdedBuilding;
		
		public function get MOD_NAME(): String { return Constants.MOD_NAME; }
		public function get VERSION(): String { return "0.1.0"; }
		
		CONFIG::debug
		public function get COREMOD_VERSION(): String { return String(Math.random()); }
		CONFIG::release
		public function get COREMOD_VERSION(): String { return VERSION; }
		
		public function get BEZEL_VERSION(): String { return "2.0.6"; }
		
		public static var instance: ModlibMod;
		public var bezel: Bezel;
		public var logger: Logger;
		
		internal var buildingPageIndex: int = 0;
		
		public function ModlibMod() 
		{
			instance = this;
			
			logger = Logger.getLogger(MOD_NAME);
		}
		
		public function bind(modLoader: Bezel, gameObjects: Object): void 
		{
			bezel = modLoader;
			
			registerKeybinds();
			
			addEventListeners();
		}
		
		public function unload(): void 
		{
			removeEventListeners();
		}
		
		public function loadCoreMod(lattice: Lattice): void 
		{
			installIngameDestroyerCoremod(lattice);
			installIngameInputHandlerCoremod(lattice);
			installIngameInputHandler2Coremod(lattice);
			installIngameRenderer2Coremod(lattice);
			installIngameInitializer2Coremod(lattice);
			installIngameCoreCoremod(lattice);
		}
		
		private function addEventListeners(): void
		{
			bezel.addEventListener(EventTypes.INGAME_NEW_SCENE, ehIngameNewScene);
			bezel.addEventListener(EventTypes.INGAME_KEY_DOWN, ehIngameKeyDown);
		}
		
		private function removeEventListeners(): void
		{
			bezel.removeEventListener(EventTypes.INGAME_NEW_SCENE, ehIngameNewScene);
			bezel.removeEventListener(EventTypes.INGAME_KEY_DOWN, ehIngameKeyDown);
		}
		
		private function registerKeybinds(): void
		{
			bezel.keybindManager.registerHotkey(Constants.BUILDING_PAGE_DOWN_KEYBIND_ID, new Keybind("period"));
			bezel.keybindManager.registerHotkey(Constants.BUILDING_PAGE_UP_KEYBIND_ID, new Keybind("slash"));
		}
		
		private function ehIngameNewScene(event: IngameNewSceneEvent): void
		{
			buildingPageIndex = 0;
			
			ModdedBuilding.resetBuildCosts();
		}
		
		private function ehIngameKeyDown(event: IngameKeyDownEvent): void
		{
			if (bezel.keybindManager.getHotkeyValue(Constants.BUILDING_PAGE_UP_KEYBIND_ID).matches(event.eventArgs.event))
			{
				buildingPageIndex = Math.min(buildingPageIndex + 1, Math.ceil(Registry.BUILDING_REGISTRY.entryCount / 5.0));
				
				GV.vfxEngine.createFloatingText2(GV.main.mouseX, GV.main.mouseY, buildingPageIndex.toString(), 0xFF8000, 12, "center", 0, 0, 0, 0, 50, 0, 50);
				SB.playSound("sndalert");
			}
			else if (bezel.keybindManager.getHotkeyValue(Constants.BUILDING_PAGE_DOWN_KEYBIND_ID).matches(event.eventArgs.event))
			{
				buildingPageIndex = Math.max(buildingPageIndex - 1, 0);
				
				GV.vfxEngine.createFloatingText2(GV.main.mouseX, GV.main.mouseY, buildingPageIndex.toString(), 0xFF8000, 12, "center", 0, 0, 0, 0, 50, 0, 50);
				SB.playSound("sndalert");
			}
		}
		
		private function installIngameDestroyerCoremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameDestroyer.class.asasm";
			const CLASS_NAME: String = "IngameDestroyer";
			
			const SEARCH_DEMOLISH_OWN_BUILDING: RegExp = /trait method QName\(PackageNamespace\(""\), "demolishOwnBuilding"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_DEMOLISH_OWN_BUILDING);
			if (checkOffset(offset, CLASS_NAME, SEARCH_DEMOLISH_OWN_BUILDING))
			{
				return;
			}
			
			const SEARCH_GETLEX_TOWER: RegExp = /getlex QName\(PackageNamespace\("com.giab.games.gcfw.entity"\), "Tower"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_GETLEX_TOWER);
			if (checkOffset(offset, CLASS_NAME, SEARCH_GETLEX_TOWER))
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
				getlocal 7 \n \
				getlocal1 \n \
				getlocal2 \n \
				getlocal3 \n \
				getlocal 4 \n \
				callproperty QName(PackageNamespace(""), "destroy"), 5 \n \
				setlocal 11 \
				');
				
			successfulPatch(CLASS_NAME);
		}
		
		private function installIngameInputHandlerCoremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameInputHandler.class.asasm";
			const CLASS_NAME: String = "IngameInputHandler";
			const SEARCH_RETURNVOID: RegExp = /returnvoid/;
			
			const SEARCH_INITIATE_CAST_BUILD_TRAP: RegExp = /trait method QName\(PackageNamespace\(""\), "initiateCastBuildTrap"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_INITIATE_CAST_BUILD_TRAP);
			if (checkOffset(offset, CLASS_NAME, SEARCH_INITIATE_CAST_BUILD_TRAP))
			{
				return;
			}
			
			offset = lattice.findPattern(FILE_NAME, SEARCH_RETURNVOID, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_RETURNVOID))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0, 
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
				pushbyte 2 \n \
				callproperty QName(PackageNamespace(""), "initiateCastBuild"), 1 \n \
				iffalse cont \n \
				returnvoid \n \
				cont: \
				');
				
			const SEARCH_INITIATE_CAST_BUILD_TOWER: RegExp = /trait method QName\(PackageNamespace\(""\), "initiateCastBuildTower"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_INITIATE_CAST_BUILD_TOWER);
			if (checkOffset(offset, CLASS_NAME, SEARCH_INITIATE_CAST_BUILD_TOWER))
			{
				return;
			}
			
			offset = lattice.findPattern(FILE_NAME, SEARCH_RETURNVOID, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_RETURNVOID))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0,
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
				pushbyte 0 \n \
				callproperty QName(PackageNamespace(""), "initiateCastBuild"), 1 \n \
				iffalse cont \n \
				returnvoid \n \
				cont: \
				');
				
			const SEARCH_INITIATE_CAST_BUILD_LANTERN: RegExp = /trait method QName\(PackageNamespace\(""\), "initiateCastBuildLantern"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_INITIATE_CAST_BUILD_LANTERN);
			if (checkOffset(offset, CLASS_NAME, SEARCH_INITIATE_CAST_BUILD_LANTERN))
			{
				return;
			}
			
			offset = lattice.findPattern(FILE_NAME, SEARCH_RETURNVOID, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_RETURNVOID))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0,
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
				pushbyte 3 \n \
				callproperty QName(PackageNamespace(""), "initiateCastBuild"), 1 \n \
				iffalse cont \n \
				returnvoid \n \
				cont: \
				');
				
			const SEARCH_INITIATE_CAST_BUILD_PYLON: RegExp = /trait method QName\(PackageNamespace\(""\), "initiateCastBuildPylon"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_INITIATE_CAST_BUILD_PYLON);
			if (checkOffset(offset, FILE_NAME, SEARCH_INITIATE_CAST_BUILD_PYLON))
			{
				return;
			}
			
			offset = lattice.findPattern(FILE_NAME, SEARCH_RETURNVOID, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_RETURNVOID))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0,
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
				pushbyte 4 \n \
				callproperty QName(PackageNamespace(""), "initiateCastBuild"), 1 \n \
				iffalse cont \n \
				returnvoid \n \
				cont: \
				');
			
			const SEARCH_INITIATE_CAST_BUILD_AMPLIFIER: RegExp = /trait method QName\(PackageNamespace\(""\), "initiateCastBuildAmplifier"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_INITIATE_CAST_BUILD_AMPLIFIER);
			if (checkOffset(offset, CLASS_NAME, SEARCH_INITIATE_CAST_BUILD_AMPLIFIER))
			{
				return;
			}
			
			offset = lattice.findPattern(FILE_NAME, SEARCH_RETURNVOID, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_RETURNVOID))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0,
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
				pushbyte 1 \n \
				callproperty QName(PackageNamespace(""), "initiateCastBuild"), 1 \n \
				iffalse cont \n \
				returnvoid \n \
				cont: \
				');
				
			successfulPatch(CLASS_NAME);
		}
		
		private function installIngameInputHandler2Coremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameInputHandler2.class.asasm";
			const CLASS_NAME: String = "IngameInputHandler2";
			
			const SEARCH_CLICK_ON_SCENE: RegExp = /trait method QName\(PackageNamespace\(""\), "clickOnScene"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_CLICK_ON_SCENE);
			if (checkOffset(offset, CLASS_NAME, SEARCH_CLICK_ON_SCENE))
			{
				return;
			}
			
			const SEARCH_PLAYING: RegExp = /getproperty QName\(PackageNamespace\(""\), "PLAYING"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_PLAYING, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_PLAYING))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset + 1, 0,
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
				getlocal 4 \n \
				getlocal 5 \n \
				callpropvoid QName(PackageNamespace(""), "build"), 2 \
				');
				
			successfulPatch(CLASS_NAME);
		}
		
		private function installIngameRenderer2Coremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameRenderer2.class.asasm";
			const CLASS_NAME: String = "IngameRenderer2";
			
			const SEARCH_REDRAW_HIGH_BUILDINGS: RegExp = /trait method QName\(PackageNamespace\(""\), "redrawHighBuildings"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_REDRAW_HIGH_BUILDINGS);
			if (checkOffset(offset, CLASS_NAME, SEARCH_REDRAW_HIGH_BUILDINGS))
			{
				return;
			}
			
			const SEARCH_GETLEX_MONSTER_NEST: RegExp = /getlex QName\(PackageNamespace\("com.giab.games.gcfw.entity"\), "MonsterNest"\)/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_GETLEX_MONSTER_NEST, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_GETLEX_MONSTER_NEST))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset + 1, 1, 'iffalse moddedBuilding');
			
			const SEARCH_DRAW: RegExp = /callpropvoid QName\(PackageNamespace\(""\), "draw"\), 2/;
			offset = lattice.findPattern(FILE_NAME, SEARCH_DRAW, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_DRAW))
			{
				return;
			}
			offset = lattice.findPattern(FILE_NAME, SEARCH_DRAW, offset);
			if (checkOffset(offset, CLASS_NAME, SEARCH_DRAW))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset, 0,
				' \
				moddedBuilding: \n \
				getlex QName(PackageNamespace("com.giab.games.gcfw"), "GV") \n \
				getproperty QName(PackageNamespace(""), "main") \n \
				getproperty QName(PackageNamespace(""), "bezel") \n \
				pushstring "' + MOD_NAME + '" \n \
				callproperty QName(PackageNamespace(""), "getModByName"), 1 \n \
				getproperty QName(PackageNamespace(""), "loaderInfo") \n \
				getproperty QName(PackageNamespace(""), "applicationDomain") \n \
				pushstring "Modlib.ModdedBuilding" \n \
				callproperty QName(PackageNamespace(""), "getDefinition"), 1 \n \
				getlocal1 \n \
				getlocal2 \n \
				getlocal3 \n \
				callpropvoid QName(PackageNamespace(""), "render"), 3 \
				');
				
			successfulPatch(CLASS_NAME);
		}
		
		private function installIngameInitializer2Coremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameInitializer2.class.asasm";
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
				getproperty QName(PackageNamespace(""), "core") \n \
				newarray 0 \n \
				setproperty QName(PackageNamespace(""), "' + Constants.MODDED_PROJECTILE_ARRAY_ID + '") \n \
				getlocal0 \n \
				getproperty QName(PackageNamespace(""), "core") \n \
				newarray 0 \n \
				setproperty QName(PackageNamespace(""), "' + Constants.MODDED_BUILDING_ARRAY_ID + '") \
				');
				
			successfulPatch(CLASS_NAME);
		}
		
		private function installIngameCoreCoremod(lattice: Lattice): void
		{
			const FILE_NAME: String = "com/giab/games/gcfw/ingame/IngameCore.class.asasm";
			const CLASS_NAME: String = "IngameCore";
			
			const SEARCH_FREE_BUILDINGS_LEFT: RegExp = /trait slot QName\(PackageNamespace\(""\), "freeBuildingsLeft"\)/;
			var offset: int = lattice.findPattern(FILE_NAME, SEARCH_FREE_BUILDINGS_LEFT);
			if (checkOffset(offset, CLASS_NAME, SEARCH_FREE_BUILDINGS_LEFT))
			{
				return;
			}
			
			lattice.patchFile(FILE_NAME, offset - 1, 0,
				' \
				trait slot QName(PackageNamespace(""), "' + Constants.MODDED_PROJECTILE_ARRAY_ID + '") type QName(PackageNamespace(""), "Array") end \n \
				trait slot QName(PackageNamespace(""), "' + Constants.MODDED_BUILDING_COSTS_ID + '") type QName(PackageNamespace(""), "Array") end \n \
				trait slot QName(PackageNamespace(""), "' + Constants.MODDED_BUILDING_ARRAY_ID + '") type QName(PackageNamespace(""), "Array") end \
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
				callpropvoid QName(PackageNamespace(""), "doEnterFrameAll"), 1 \
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
				callpropvoid QName(PackageNamespace(""), "doEnterFrameAll"), 1 \
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