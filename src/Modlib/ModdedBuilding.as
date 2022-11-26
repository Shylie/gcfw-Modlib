package Modlib 
{
	import Modlib.API.IModdedBuildingImplProvider;
	import Modlib.API.IModdedProjectileImplProvider;
	import com.giab.common.utils.ArrayToolbox;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.constants.GameMode;
	import com.giab.games.gcfw.constants.GemEnhancementId;
	import com.giab.games.gcfw.constants.IngameStatus;
	import com.giab.games.gcfw.constants.TargetPriorityId;
	import com.giab.games.gcfw.entity.Barricade;
	import com.giab.games.gcfw.entity.Beacon;
	import com.giab.games.gcfw.entity.DropHolder;
	import com.giab.games.gcfw.entity.GateKeeperFang;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.entity.GemSeal;
	import com.giab.games.gcfw.entity.JarOfWasps;
	import com.giab.games.gcfw.entity.ManaShard;
	import com.giab.games.gcfw.entity.Monster;
	import com.giab.games.gcfw.entity.MonsterNest;
	import com.giab.games.gcfw.entity.PossessionObelisk;
	import com.giab.games.gcfw.entity.Pylon;
	import com.giab.games.gcfw.entity.SleepingHive;
	import com.giab.games.gcfw.entity.Tomb;
	import com.giab.games.gcfw.entity.WatchTower;
	import com.giab.games.gcfw.entity.WizLock;
	import com.giab.games.gcfw.entity.WizardStash;
	import com.giab.games.gcfw.mcDyn.McChargeMeter;
	import com.giab.games.gcfw.struct.ShotData;
	/**
	 * ...
	 * @author Shy
	 */
	public class ModdedBuilding
	{
		private var provider: IModdedBuildingImplProvider;
		
		public var x: int;
		public var y: int;
		
		public var fieldX: int;
		public var fieldY: int;
		
		public var shotColor: Array;
		public var mcChargeMeter: McChargeMeter;
		public var mossAlpha: Number;
		public var mossHue: Number;
		public var snowAlpha: Number;
		
		public var insertedGem: Gem;
		
		public var isCoolingDown: Boolean;
		public var cooldownTimer: Number;
		
		public var normalTargets: Array;
		public var normalCharge: Number;
		public var normalTimeUntilNextTargetCheck: Number;
		
		public var enhancedCharge: Number;
		public var enhancedTimeUntilNextTargetCheck: Number;
		public var enhancedTargets: Array;
		
		public function ModdedBuilding(provider: IModdedBuildingImplProvider, fieldX: int, fieldY: int, mossAlpha: Number = 0, mossHue: Number = 0, snowAlpha: Number = 0)
		{
			this.provider = provider;
			
			this.fieldX = fieldX;
			this.fieldY = fieldY;
			x = fieldX * 28 + 28;
			y = fieldY * 28 + 28;
			
			insertedGem = null;
			
			mcChargeMeter = new McChargeMeter();
			mcChargeMeter.x = x - 28 + 50;
			mcChargeMeter.y = y - 28 + 8;
			
			mcChargeMeter.fullCharge.visible = false;
			
			this.mossAlpha = mossAlpha;
			this.mossHue = mossHue;
			this.snowAlpha = snowAlpha;
		}
		
		public function doEnterFrame(speedMultiplier: Number): void
		{
			if (insertedGem != null)
			{
				if (isCoolingDown)
				{
					cooldownTimer -= speedMultiplier * (100 / 200);
					if (cooldownTimer < 1)
					{
						isCoolingDown = false;
						normalCharge = 0;
						enhancedCharge = 0;
						GV.ingameCore.cnt.cntRetinaHud.removeChild(mcChargeMeter);
					}
					else
					{
						mcChargeMeter.gotoAndStop(Math.floor(Math.max(1, (100 - cooldownTimer) * 64 / 100)));
					}
				}
				else
				{
					if (GV.ingameCore.ingameStatus == IngameStatus.PLAYING && GV.ingameCore.draggedGem != insertedGem)
					{
						// normal shots
						if (insertedGem.enhancementType == GemEnhancementId.NONE || !provider.doesEnhancementDisableNormal(insertedGem.enhancementType))
						{
							normalCharge += speedMultiplier * insertedGem.sd4_IntensityMod.reloadingSpeed.g()
							
							if (normalCharge >= 100)
							{
								if (normalTimeUntilNextTargetCheck <= 0)
								{
									var normalShotsLeftThisFrame: Number = speedMultiplier * 2;
									
									while (normalShotsLeftThisFrame > 0 && normalCharge >= 100 && normalTimeUntilNextTargetCheck <= 0)
									{
										normalShotsLeftThisFrame--;
										
										normalTargets = acquireNewCreatureTargets(false);
										if (normalTargets.length == 0)
										{
											normalTimeUntilNextTargetCheck = provider.timeBetweenTargetChecks(GemEnhancementId.NONE);
										}
										else
										{
											normalTargets.forEach(attackTarget);
										}
										
										normalCharge -= 100 - Math.random() * 3;
									}
								}
								else
								{
									normalTimeUntilNextTargetCheck -= speedMultiplier;
								}
							}
						}
						
						// enhanced shots
						if (insertedGem.enhancementType != GemEnhancementId.NONE)
						{
							enhancedCharge += speedMultiplier * insertedGem.sd5_EnhancedOrTrapOrLantern.reloadingSpeed.g()
							
							if (enhancedCharge >= 100)
							{
								if (enhancedTimeUntilNextTargetCheck <= 0)
								{
									var enhancedShotsLeftThisFrame: Number = speedMultiplier * 2;
									
									while (insertedGem.e_ammoLeft.g() >= 1 && enhancedShotsLeftThisFrame > 0 && enhancedCharge >= 100 && enhancedTimeUntilNextTargetCheck <= 0)
									{
										enhancedShotsLeftThisFrame--;
									
										enhancedTargets = acquireNewCreatureTargets(true);
										if (enhancedTargets.length == 0)
										{
											enhancedTimeUntilNextTargetCheck = provider.timeBetweenTargetChecks(GemEnhancementId.NONE)
										}
										else
										{
											enhancedTargets.forEach(enhancedAttackTarget);
										}
										
										enhancedCharge -= 100 - Math.random() * 3;
									}
									
									if (insertedGem.e_ammoLeft.g() < 1)
									{
										insertedGem.enhancementType = GemEnhancementId.NONE;
										insertedGem.showInTower();
										insertedGem.recalculateSds();
									}
								}
								else
								{
									enhancedTimeUntilNextTargetCheck -= speedMultiplier;
								}
							}
						}
					}
					
					if (insertedGem.hits.g() >= insertedGem.nextHitLevelAt.g())
					{
						GV.vfxEngine.createGemLevelUp(x, y, insertedGem.grade.g() + 1);
						insertedGem.recalculateSds();
					}
				}
			}
		}
		
		private function createProjectile(enhancement: int, target: Object, rawDamage: Number, shotColor: Array, markableForDeath: Boolean, isKillingShot: Boolean): ModdedProjectile
		{
			var projectileProvider: IModdedProjectileImplProvider = provider.projectile(enhancement);
			var shotData: ShotData = (enhancement == GemEnhancementId.NONE ? insertedGem.sd4_IntensityMod : insertedGem.sd5_EnhancedOrTrapOrLantern);
			
			return new ModdedProjectile(projectileProvider, this, shotData, target, rawDamage, markableForDeath, isKillingShot, provider.isRawDamage(enhancement));
		}
		
		// TODO: return boolean and only retarget if one or more dies
		private function attackTarget(target: Object): void
		{
			var monster: Monster = target as Monster;
			
			var isKillingShot: Boolean = false;
			var actualDamage: Number = Math.round(insertedGem.sd4_IntensityMod.damageMin.g() * Math.random() * (insertedGem.sd4_IntensityMod.damageMax.g() - insertedGem.sd4_IntensityMod.damageMin.g()));
			
			if (insertedGem.sd4_IntensityMod.calcCritChance.g() > Math.random())
			{
				if (target.isFrozen)
				{
					actualDamage *= 1 + insertedGem.sd4_IntensityMod.critHitMultiplier.g() + 0.01 * GV.ingameCore.spFreezeCritHitDmgBoostPct.g();
				}
				else
				{
					actualDamage *= 1 + insertedGem.sd4_IntensityMod.critHitMultiplier.g();
				}
			}
			
			var actualDamageRaw: Number = actualDamage;
			
			if (monster != null)
			{
				actualDamage = Math.max(1, actualDamage - monster.armorLevel.g() - monster.strInNum * GV.ingameCore.monstersOnScene.length);
				actualDamage *= GV.wraithDmgMult * monster.talismanDmgMult * Math.max(monster.dmgReductionMin, 1 - monster.hitsTaken * monster.dmgReductionPerHitsTaken);
				if (monster.dmgDiv > 1)
				{
					actualDamage = Math.min(actualDamage, monster.hpMax.g() / monster.dmgDiv);
				}
				actualDamage = Math.max(1, actualDamage);
			}
			
			if (target.isTargetMarkableForDeath)
			{
				if (target.shield > target.incomingShotsOnShield)
				{
					target.incomingShotsOnShield++;
				}
				else if (monster != null)
				{
					monster.incomingDamage += actualDamage;
				}
				else
				{
					target.incomingDamage += actualDamage - target.armorLevel.g();
				}
				
				if (target.hp.g() <= target.incomingDamage && target.shield <= target.incomingShotsOnShield)
				{
					target.isKillingShotOnTheWay = true;
					isKillingShot = true;
					if (monster != null)
					{
						monster.killingShotTimer = provider.killingShotDelay(insertedGem.enhancementType);
					}
				}
			}
			
			createProjectile(insertedGem.enhancementType, target, actualDamageRaw, shotColor, true, isKillingShot);
		}
		
		private function enhancedAttackTarget(target: Object): void
		{
			if (insertedGem.e_ammoLeft.g() >= 1)
			{
				insertedGem.e_ammoLeft.s(insertedGem.e_ammoLeft.g() - provider.enhancementAmmoUsage(insertedGem.enhancementType));
				attackTarget(target);
			}
		}
		
		private function acquireNewTargets(): void
		{
			if (insertedGem != null)
			{
				if (insertedGem.enhancementType != GemEnhancementId.NONE)
				{
					normalTargets = acquireNewCreatureTargets(true);
				}
				else
				{
					enhancedTargets = [];
				}
			}
		}
		
		private function acquireNewCreatureTargets(isEnhanced: Boolean): Array
		{
			var newTargets: Array = [];
			
			var enhancement: int = isEnhanced ? insertedGem.enhancementType : GemEnhancementId.NONE;
			
			var rangeMax: Number = isEnhanced ? Number(insertedGem.sd5_EnhancedOrTrapOrLantern.range.g()) : Number(insertedGem.sd4_IntensityMod.range.g());
			
			if (rangeMax > provider.maximumRange(enhancement))
			{
				rangeMax = provider.maximumRange(enhancement);
			}
			rangeMax *= rangeMax;
			
			var rangeMin: Number = provider.minimumRange(enhancement);
			rangeMin *= rangeMin;
			
			for (var i: int = 0; i < GV.ingameCore.monstersOnScene.length; i++)
			{
				var currentMonster: Monster = GV.ingameCore.monstersOnScene[i] as Monster;
				
				if (!currentMonster.isKillingShotOnTheWay)
				{
					var dx: Number = x - currentMonster.x;
					var dy: Number = y - currentMonster.y;
					
					dx *= dx;
					dy *= dy;
					
					if (dx + dy >= rangeMin && dx + dy <= rangeMax)
					{	
						newTargets.push(currentMonster);
					}
				}
			}
			
			if (newTargets.length > 0)
			{
				switch (insertedGem.targetPriority)
				{
					case TargetPriorityId.STRUCTURE:
						newTargets.sortOn(["numOfEffects"], Array.NUMERIC);
						break;
						
					case TargetPriorityId.NEAREST_TO_ORB:
						newTargets.sortOn(["distanceFromOrb"], Array.NUMERIC);
						break;
						
					case TargetPriorityId.HIGHEST_BANISHMENT_COST_SPECIAL:
						newTargets.sortOn(["specTargetValue"], Array.NUMERIC | Array.DESCENDING);
						break;
						
					case TargetPriorityId.LEAST_HIT_POINTS:
						newTargets.sortOn(["hpForSorting"], Array.NUMERIC | Array.DESCENDING);
						break;
						
					case TargetPriorityId.RANDOM:
						newTargets = ArrayToolbox.shuffle(newTargets);
						break;
						
					case TargetPriorityId.GIANTS:
						newTargets.sortOn(["isGiantForSorting", "distanceFromOrb"], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC]);
						break;
					
					case TargetPriorityId.SWARMLINGS:
						newTargets.sortOn(["isSwarmlingForSorting", "distanceFromOrb"], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC]);
						break;
						
					case TargetPriorityId.SHIELDED_HIGHEST_ARMOR:
						newTargets.sortOn(["shield", "armorLevelForSorting"], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC | Array.DESCENDING]);
						break;
				}
			}
			
			if (newTargets.length > provider.maximumTargets(enhancement))
			{
				newTargets.splice(provider.maximumTargets(enhancement));
			}
			
			return newTargets;
		}
		
		public static function doEnterFrameAll(speedMultiplier: Number): void
		{
			var moddedBuildings: Array = GV.ingameCore[ModibConstants.MODDED_BUILDING_ARRAY_ID] as Array;
			for (var i: int = moddedBuildings.length - 1; i >= 0; i--)
			{
				ModdedBuilding(moddedBuildings[i]).doEnterFrame(speedMultiplier);
			}
		}
	}
}