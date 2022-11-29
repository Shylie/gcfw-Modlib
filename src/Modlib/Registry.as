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
			BUILDING_REGISTRY.register(new RegistryEntry(buildingProvider, name));
		}
		
		public static function unregisterBuilding(name: String): void
		{
			BUILDING_REGISTRY.unregister(name);
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
		
		private function unregister(name: String): void
		{
			for (var i: int = 0; i < entries.length; i++)
			{
				if (name == (entries[i] as RegistryEntry).name)
				{
					if (i == entries.length - 1)
					{
						entries.pop();
					}
					else
					{
						entries[i] = entries.pop();
					}
				}
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