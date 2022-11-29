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
		 * Register a building/projectile pair.
		 * @param buildingProvider The building provider to register. Must adhere to Modlib.API.IModdedBuildingImplProvider
		 */
		public static function registerBuilding(buildingProvider: Object, name: String): void
		{
			BUILDING_REGISTRY.push(new RegistryEntry(buildingProvider, name));
		}
		
		internal function getEntry(id: int): Object
		{
			return RegistryEntry(entries[id]).entry;
		}
		
		internal function get entryCount(): uint
		{
			return entries.length;
		}
		
		private function push(entry: Object): void
		{
			entries.push(entry);
			entries.sortOn(["name"]);
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