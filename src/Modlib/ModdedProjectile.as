package Modlib 
{
	import Modlib.API.IModdedProjectileImplProvider;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Apparition;
	import com.giab.games.gcfw.entity.Beacon;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.entity.JarOfWasps;
	import com.giab.games.gcfw.entity.ManaShard;
	import com.giab.games.gcfw.entity.MonsterNest;
	import com.giab.games.gcfw.entity.Shadow;
	import com.giab.games.gcfw.entity.ShadowProjectile;
	import com.giab.games.gcfw.entity.Specter;
	import com.giab.games.gcfw.entity.Tomb;
	import com.giab.games.gcfw.entity.WatchTower;
	import com.giab.games.gcfw.entity.Wraith;
	import com.giab.games.gcfw.struct.ShotData;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	/**
	 * ...
	 * @author Shy
	 */
	public class ModdedProjectile 
	{
		private var provider: IModdedProjectileImplProvider;
		
		public var mc: MovieClip;
		public var shotData: ShotData;
		public var target: Object;
		public var rgb: Array;
		public var originGem: Gem;
		public var isTargetMarkableForDeath: Boolean;
		public var isKillingShot: Boolean;
		public var targetOffsetX: Number;
		public var targetOffsetY: Number;
		public var damage: Number;
		public var isRawDamage: Boolean;
		
		public function ModdedProjectile(provider: IModdedProjectileImplProvider, building: ModdedBuilding, shotData: ShotData, target: Object, damage: Number, targetMarkableForDeath: Boolean, killingShot: Boolean, rawDamage: Boolean)
		{
			this.provider = provider;
			
			isKillingShot = killingShot;
			isTargetMarkableForDeath = targetMarkableForDeath;
			this.mc = provider.mc;
			this.shotData = shotData;
			originGem = building.insertedGem;
			this.target = target;
			this.damage = damage;
			isRawDamage = rawDamage;
			targetOffsetX = 0;
			targetOffsetY = 0;
			
			var isTargetAir: Boolean = target is Apparition || target is Wraith || target is Specter || target is Shadow || target is ShadowProjectile;
			if (isTargetAir)
			{
				targetOffsetX = Math.random() * 50 - 25;
				targetOffsetY = Math.random() * 50 - 25;
			}
			
			if (target is ManaShard)
			{
				targetOffsetX = 50 + Math.random() * [8, 30, 56][ManaShard(target).size] - [4, 15, 28][ManaShard(target).size];
				targetOffsetY = 8 + Math.random() * [8, 30, 56][ManaShard(target).size] - [4, 15, 28][ManaShard(target).size];
			}
			else if (target is Beacon)
			{
				targetOffsetX = 50 + Math.random() * 8 - 4;
				targetOffsetY = 8 + Math.random() * 8 - 4;
			}
			else if (target is Tomb || target is MonsterNest)
			{
				targetOffsetX = 50 + Math.random() * 56 - 28;
				targetOffsetY = 8 + Math.random() * 56 - 28;
			}
			else if (target is WatchTower)
			{
				targetOffsetX = 50 + Math.random() * 28 - 14;
				targetOffsetY = 8 + Math.random() * 28 - 14;
			}
			else if (target is JarOfWasps)
			{
				targetOffsetX = 50 + Math.random() * 8 - 4;
				targetOffsetY = 8 + Math.random() * 8 - 4;
			}
			
			if (mc != null)
			{
				GV.ingameController.cnt.cntShots.addChild(this.mc);
			}
		}
		
		public function doEnterFrame(speedMultiplier: Number): void
		{
			if (speedMultiplier > 0)
			{
				provider.update(this);
				if (provider.hit(this))
				{
					if (isRawDamage)
					{
						target.sufferRawDamage(damage, damage, false);
					}
					else
					{
						target.sufferShotDamage(shotData, originGem, false, damage, isKillingShot);
					}
					
					if (mc != null)
					{
						GV.ingameController.cnt.cntShots.removeChild(mc);
						mc = null;
					}
					
					var moddedProjectiles: Array = GV.ingameCore[ModibConstants.MODDED_PROJECTILE_ARRAY_ID] as Array;
					var indexOf: int = moddedProjectiles.indexOf(this);
					if (indexOf >= 0)
					{
						if (indexOf == moddedProjectiles.length - 1)
						{
							moddedProjectiles.pop();
						}
						else
						{
							moddedProjectiles[indexOf] = moddedProjectiles.pop();
						}
					}
				}
			}
		}
		
		public static function doEnterFrameAll(speedMultiplier: Number): void
		{
			var moddedProjectiles: Array = GV.ingameCore[ModibConstants.MODDED_PROJECTILE_ARRAY_ID] as Array;
			for (var i: int = moddedProjectiles.length - 1; i >= 0; i--)
			{
				ModdedProjectile(moddedProjectiles[i]).doEnterFrame(speedMultiplier);
			}
		}
	}
}