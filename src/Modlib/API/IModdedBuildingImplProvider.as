package Modlib.API 
{
	/**
	 * ...
	 * @author Shy
	 */
	public interface IModdedBuildingImplProvider 
	{
		/**
		 * Get the damage multiplier for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Damage multiplier for enhancement
		 */
		function damageMultiplier(enhancement: int): Number; // [1, 1, 1, 1]
		
		/**
		 * Get the special multiplier for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Special multiplier for enhancement
		 */
		function specialMultiplier(enhancement: int): Number; // [1, 1, 1, 1]
		
		/**
		 * Get the range multiplier for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Range multiplier for enhancement
		 */
		function rangeMultiplier(enhancement: int): Number; // [1, 1.5, 1, 3.5]
		
		/**
		 * Get the attack speed multiplier for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Attack speed multiplier for enhancement
		 */
		function firingSpeedMultiplier(enhancement: int): Number; // [1, 1 / 3.0, 100, 1 / 5.0]
		
		/**
		 * Get the minimum range for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Minimum range for enhancement
		 */
		function minimumRange(enhancement: int): Number; // [0, 0, 0, 0]
		
		/**
		 * Get the maximum range for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Maximum range for enhancement
		 */
		function maximumRange(enhancement: int): Number; // [1e300, 1e300, 10, 1e300]
		
		/**
		 * Get the maximum number of targets for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Maximum number of targets for enhancement
		 */
		function maximumTargets(enhancement: int): Number; // [1, 1, 1, 1]
		
		/**
		 * Get the time in seconds between rechecking targets for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Time in seconds between rechecking targets
		 */
		function timeBetweenTargetChecks(enhancement: int): Number; // [3, 3, 1, 3]
		
		/**
		 * Get the killing shot delay for a given enhancement type
		 * @param enhancement Type of enhancement to get stats for
		 * @return Killing shot delay
		 */
		function killingShotDelay(enhancement: int): uint; // [75, 75, 0, 0]
		
		/**
		 * Get whether or not the damage is true damage for a given enhancement type
		 * 
		 * Note:
		 * Should most likely be false. Can cause issues on targets without a sufferRawDamage method.
		 * @param enhancement Type of enhancement to get stats for
		 * @return True if the shot is true damage
		 */
		function isRawDamage(enhancement: int): Boolean; // [false, false, false, false]
		
		/**
		 * Get whether or not the given enhancement type disables normal shots
		 * @param enhancement Type of enhancement to get stats for
		 * @return True if the enhancement type disables normal shots
		 */
		function doesEnhancementDisableNormal(enhancement: int): Boolean; // [false, false, false]
		
		/**
		 * Amount of ammo a given enhancement uses per shot
		 * @param enhancement Type of enhancement to get stats for
		 * @return Ammo consumption per shot
		 */
		function enhancementAmmoUsage(enhancement: int): Number;
		
		/**
		 * Get the projectile implementation for a given enhancement type
		 * @param enhancement Type of enhancement to get the projectile for
		 * @return Projectile implementation
		 */
		function projectile(enhancement: int): IModdedProjectileImplProvider;
	}
}