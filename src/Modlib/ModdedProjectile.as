package Modlib 
{
	import com.giab.common.utils.ColorToolbox;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Apparition;
	import com.giab.games.gcfw.entity.Beacon;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.entity.Guardian;
	import com.giab.games.gcfw.entity.JarOfWasps;
	import com.giab.games.gcfw.entity.ManaShard;
	import com.giab.games.gcfw.entity.Monster;
	import com.giab.games.gcfw.entity.MonsterNest;
	import com.giab.games.gcfw.entity.Shadow;
	import com.giab.games.gcfw.entity.ShadowProjectile;
	import com.giab.games.gcfw.entity.Specter;
	import com.giab.games.gcfw.entity.Tomb;
	import com.giab.games.gcfw.entity.WallBreaker;
	import com.giab.games.gcfw.entity.WatchTower;
	import com.giab.games.gcfw.entity.WizardHunter;
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
		private var provider: Object;
		
		public var mc: MovieClip;
		public var shotData: ShotData;
		public var target: Object;
		public var rgb: Array;
		public var ctr: ColorTransform;
		public var originGem: Gem;
		public var isTargetMarkableForDeath: Boolean;
		public var isKillingShot: Boolean;
		public var targetOffsetX: Number;
		public var targetOffsetY: Number;
		public var damage: Number;
		public var isRawDamage: Boolean;
		public var building: ModdedBuilding;
		
		public static function doEnterFrameAll(speedMultiplier: Number): void
		{
			var moddedProjectiles: Array = GV.ingameCore[Constants.MODDED_PROJECTILE_ARRAY_ID] as Array;
			for (var i: int = moddedProjectiles.length - 1; i >= 0; i--)
			{
				(moddedProjectiles[i] as ModdedProjectile).doEnterFrame(speedMultiplier);
			}
		}
		
		public function ModdedProjectile(providerClass: Class, building: ModdedBuilding, shotData: ShotData, target: Object, damage: Number, targetMarkableForDeath: Boolean, killingShot: Boolean, rawDamage: Boolean)
		{
			isKillingShot = killingShot;
			isTargetMarkableForDeath = targetMarkableForDeath;
			
			this.shotData = shotData;
			this.building = building;
			originGem = building.insertedGem;
			this.target = target;
			this.damage = damage;
			isRawDamage = rawDamage;
			targetOffsetX = 50;
			targetOffsetY = 8;
			
			rgb = building.shotColor;
			ctr = building.ctrShot;
			
			var isTargetAir: Boolean = target is Apparition || target is Wraith || target is Specter || target is Shadow || target is ShadowProjectile;
			if (isTargetAir)
			{
				targetOffsetX += Math.random() * 50 - 25;
				targetOffsetY += Math.random() * 50 - 25;
			}
			
			if (target is ManaShard)
			{
				targetOffsetX += Math.random() * [8, 30, 56][ManaShard(target).size] - [4, 15, 28][ManaShard(target).size];
				targetOffsetY += Math.random() * [8, 30, 56][ManaShard(target).size] - [4, 15, 28][ManaShard(target).size];
			}
			else if (target is Beacon)
			{
				targetOffsetX += Math.random() * 8 - 4;
				targetOffsetY += Math.random() * 8 - 4;
			}
			else if (target is Tomb || target is MonsterNest)
			{
				targetOffsetX += Math.random() * 56 - 28;
				targetOffsetY += Math.random() * 56 - 28;
			}
			else if (target is WatchTower)
			{
				targetOffsetX += Math.random() * 28 - 14;
				targetOffsetY += Math.random() * 28 - 14;
			}
			else if (target is JarOfWasps)
			{
				targetOffsetX += Math.random() * 8 - 4;
				targetOffsetY += Math.random() * 8 - 4;
			}
			
			provider = new providerClass(this);
			
			mc = provider.mc(this);
			if (mc != null && building.insertedGem.hasColor)
			{
				mc.filters = ColorToolbox.calculateColorMatrixFilter(ColorToolbox.rgbToHsb(rgb));
				GV.ingameController.cnt.cntShots.addChild(mc);
			}
		}
		
		public function doEnterFrame(speedMultiplier: Number): void
		{
			if (speedMultiplier > 0)
			{
				if (provider.update(this, speedMultiplier))
				{
					if (isRawDamage)
					{
						target.sufferRawDamage(damage, damage, false);
					}
					else
					{
						target.sufferShotDamage(shotData, originGem, false, damage, isKillingShot);
					}
					
					if (target is Monster || target is Apparition || target is Guardian || target is Shadow || target is Specter || target is Wraith || target is WizardHunter || target is WallBreaker)
					{
						var manaLeeched: Number = shotData.manaGainPerHit.g() * (target.isInWhiteout ? 1 + 0.01 * GV.ingameCore.spWhiteoutManaLeechBoostPct.g() : 1);
						GV.ingameStats.manaFromManaGainGems += GV.ingameCore.changeMana(manaLeeched, true, false);
						originGem.manaLeeched += manaLeeched;
						
						if (target.isBleeding)
						{
							GV.ingameStats.manaLeechedFromBleedingMonsters += manaLeeched;
						}
						
						if (target.isPoisoned)
						{
							GV.ingameStats.manaLeechedFromPoisonedMonsters += manaLeeched;
						}
						
						if (target.isInWhiteout)
						{
							GV.ingameStats.manaLeechedFromWhitedOutMonsters += manaLeeched;
						}
					}
					
					if (mc != null)
					{
						GV.ingameController.cnt.cntShots.removeChild(mc);
						mc = null;
					}
					
					var moddedProjectiles: Array = GV.ingameCore[Constants.MODDED_PROJECTILE_ARRAY_ID] as Array;
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
	}
}