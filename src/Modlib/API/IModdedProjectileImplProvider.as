package Modlib.API 
{
	import Modlib.ModdedProjectile;
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author Shy
	 */
	public interface IModdedProjectileImplProvider 
	{
		/**
		 * Returns a new instance of the projectile's MovieClip
		 */
		function mc(projectile: ModdedProjectile): DisplayObject;
		
		/**
		 * Update the projectile
		 * @param projectile
		 */
		function update(projectile: ModdedProjectile, speedMultiplier: Number): Boolean
	}
}