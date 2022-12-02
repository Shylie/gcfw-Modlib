package Modlib 
{
	/**
	 * ...
	 * @author Shy
	 */
	public final class Registry 
	{
		internal static var BUILDING_REGISTRY: Registry = new Registry();
		
		private var entries: Array = []
		
		/**
		 * Register a building
		 * @param buildingProvider The building provider to register. Must adhere to Modlib.API.IModdedBuildingImplProvider
		 * @param name The building's name (for sorting puroses). Used to provide a deterministic building order.
		 * @param baseBuildCost The base mana cost to build this building type
		 * @param buildCostIncrease The increase in mana cost every time this type of building is built
		 */
		public static function registerBuilding(buildingProviderClass: Class, name: String, baseBuildCost: int, buildCostIncrease: int): void
		{
			CONFIG::debug
			{
				ModlibMod.instance.logger.log("", "Registering building: " + name);
			}
			BUILDING_REGISTRY.register(new RegistryEntry(buildingProviderClass, name, { "baseBuildCost": baseBuildCost, "buildCostIncrease": buildCostIncrease }));
		}
		
		internal static function unregisterAll(): void
		{
			BUILDING_REGISTRY.unregisterAll();
		}
		
		internal function getEntry(id: int): Class
		{
			return (entries[id] as RegistryEntry).entry;
		}
		
		internal function getEntryData(id: int): Object
		{
			return (entries[id] as RegistryEntry).extraData;
		}
		
		internal function get entryCount(): uint
		{
			return entries.length;
		}
		
		private function register(entry: Object): void
		{
			entries.push(entry);
			entries.sortOn(["name"]);
		}
		
		CONFIG::release
		private function unregisterAll(): void
		{
			entries = [];
		}
		
		CONFIG::debug
		private function unregisterAll(): void
		{
			while (entries.length > 0)
			{
				ModlibMod.instance.logger.log("", "Unregistering building: " + (entries.pop() as RegistryEntry).name);
			}
		}
	}
}

class RegistryEntry
{
	public var entry: Class;
	public var name: String;
	public var extraData: Object;
	
	public function RegistryEntry(entry: Class, name: String, extraData: Object)
	{
		this.entry = entry;
		this.name = name;
		this.extraData = extraData;
	}
}