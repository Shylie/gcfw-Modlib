package Modlib 
{
	import com.giab.games.gcfw.GV;
	
	/**
	 * ...
	 * @author Shy
	 */
	public final class Constants 
	{
		public static const MOD_NAME: String = "Modlib";
		
		public static const BUILDING_PAGE_UP_KEYBIND_ID: String = "Building Page Up";
		public static const BUILDING_PAGE_DOWN_KEYBIND_ID: String = "Building Page Down";
		
		public static const MODDED_PROJECTILE_ARRAY_ID: String = "moddedProjectiles";
		public static const MODDED_BUILDING_ARRAY_ID: String = "moddedBuildings";
		public static const MODDED_BUILDING_COSTS_ID: String = "moddedBuildingCosts";
		
		public static const SELECTED_MODDED_BUILDING_ID: String = "selectedModdedBuilding";
		
		public static const GEM_IS_IN_MODDED_BUILDING_ID: String = "isInModdedBuilding";
		
		public static const BUILDING_REGISTRY_ACTION_STATUS_OFFSET: int = 1500;
		public static const ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_IDLE: int = 306;
		public static const ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_THROW: int = 406;
		public static const ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_COMBINE: int = 506;
		
		public function Constants() { }
		
		public static function isDraggingModded(): Boolean
		{
			return GV.ingameCore.actionStatus >= ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_IDLE && GV.ingameCore.actionStatus <= ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_COMBINE;
		}
		
		public static function isDraggingToThrowModded(): Boolean
		{
			return GV.ingameCore.actionStatus == ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_THROW;
		}
	}
}