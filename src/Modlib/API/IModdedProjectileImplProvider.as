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
		 * Should the projectile should hit its target
		 */
		function get hit(): Boolean;
		
		/**
		 * Returns a new instance of the projectile's MovieClip
		 */
		function get mc(): MovieClip;
		
		/**
		 * Update the MovieClip of the projectile
		 * @param projectile
		 */
		function updateMC(projectile: ModdedProjectile): void
	}
}