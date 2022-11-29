package Modlib.API 
{
	import Modlib.ModdedProjectile;
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Shy
	 */
	public interface IModdedProjectileImplProvider 
	{
		/**
		 * Returns a new instance of the projectile's MovieClip
		 */
		function get mc(): MovieClip;
		
		/**
		 * Should the projectile should hit its target
		 */
		function hit(projectile: ModdedProjectile): Boolean;
		
		/**
		 * Update the projectile
		 * @param projectile
		 */
		function update(projectile: ModdedProjectile): void
	}
}