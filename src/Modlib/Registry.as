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
		 */
		public static function registerBuilding(buildingProvider: Object, name: String): void
		{
			CONFIG::debug
			{
				ModlibMod.instance.logger.log("", "Registering building: " + name);
			}
			BUILDING_REGISTRY.register(new RegistryEntry(buildingProvider, name));
		}
		
		internal static function unregisterAll(): void
		{
			BUILDING_REGISTRY.unregisterAll();
		}
		
		internal function getEntry(id: int): Object
		{
			return RegistryEntry(entries[id]).entry;
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
	public var entry: Object;
	public var name: String;
	
	public function RegistryEntry(entry: Object, name: String)
	{
		this.entry = entry;
		this.name = name;
	}
}