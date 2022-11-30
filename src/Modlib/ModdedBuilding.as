package Modlib 
{
	import Modlib.API.IModdedProjectileImplProvider;
	import com.giab.common.utils.ArrayToolbox;
	import com.giab.common.utils.ColorToolbox;
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.SB;
	import com.giab.games.gcfw.constants.ActionStatus;
	import com.giab.games.gcfw.constants.BuildingType;
	import com.giab.games.gcfw.constants.GemEnhancementId;
	import com.giab.games.gcfw.constants.IngameStatus;
	import com.giab.games.gcfw.constants.TargetPriorityId;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.entity.Monster;
	import com.giab.games.gcfw.entity.Orblet;
	import com.giab.games.gcfw.entity.Wall;
	import com.giab.games.gcfw.mcDyn.McChargeMeter;
	import com.giab.games.gcfw.struct.ShotData;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Shy
	 */
	public class ModdedBuilding
	{
		private var provider: Object;
		
		public var x: int;
		public var y: int;
		
		public var fieldX: int;
		public var fieldY: int;
		
		public var shotColor: Array;
		public var ctrShot: ColorTransform;
		public var mcChargeMeter: McChargeMeter;
		
		public var insertedGem: Gem;
		
		public var isCoolingDown: Boolean;
		public var cooldownTimer: Number;
		
		public var normalTargets: Array;
		public var normalCharge: Number;
		public var normalTimeUntilNextTargetCheck: Number;
		
		public var enhancedCharge: Number;
		public var enhancedTimeUntilNextTargetCheck: Number;
		public var enhancedTargets: Array;
		
		public var isDestroyed: Boolean;
		
		public static function hasGemInBuilding(building: Object): Boolean
		{
			var moddedBuilding: ModdedBuilding = building as ModdedBuilding;
			if (moddedBuilding != null)
			{
				return moddedBuilding.insertedGem != null;
			}
			else
			{
				return false;
			}
		}
		
		public static function getGemInBuilding(building: Object, setStatus: Boolean): Gem
		{
			var moddedBuilding: ModdedBuilding = building as ModdedBuilding;
			if (moddedBuilding != null && moddedBuilding.insertedGem != null)
			{
				if (setStatus)
				{
					GV.ingameCore.actionStatus = Constants.ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_THROW;
				}
				
				return moddedBuilding.insertedGem;
			}
			else
			{
				return null;
			}
		}
		
		public static function initiateCastBuild(offset: int): Boolean
		{
			
			if (ModlibMod.instance.buildingPageIndex == 0)
			{
				return false;
			}
			
			var provider: int = (ModlibMod.instance.buildingPageIndex - 1) * 5 + offset;
			
			if (provider >= 0 && provider < Registry.BUILDING_REGISTRY.entryCount)
			{
				if (GV.ingameCore.actionStatus - Constants.BUILDING_REGISTRY_ACTION_STATUS_OFFSET == provider)
				{
					GV.ingameController.deselectEverything(false, false);
					GV.ingameCore.initializer2.resetCastButtons();
					GV.ingameCore.actionStatus = ActionStatus.IDLE;
				}
				else 
				{
					GV.ingameController.deselectEverything(true, true);
					if (GV.ingameCore.getMana() < GV.ingameCore[Constants.MODDED_BUILDING_COSTS_ID][provider] as Number)
					{
						SB.playSound("sndalert");
						GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60 ? GV.main.mouseY + 30 : GV.main.mouseY - 20, "Not enough mana", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 10000);
					}
					
					GV.ingameCore.cnt.mcIngameFrame.buildButtons[offset + 1].frameSelected.visible = true;
					GV.ingameCore.cnt.mcIngameFrame.buildButtons[offset + 1].parent.addChild(GV.ingameCore.cnt.mcIngameFrame.buildButtons[offset + 1]);
					SB.playSound("sndspellinitiate");
					GV.ingameCore.cnt.cntRetinaHud.addChild(GV.ingameCore.cnt.bmpTowerPlaceAvailMap);
					GV.ingameCore.cnt.cntRetinaHud.addChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
					GV.ingameCore.actionStatus = provider + Constants.BUILDING_REGISTRY_ACTION_STATUS_OFFSET;
				}
			}
			
			return true;
		}
		
		public static function doEnterFrameAll(speedMultiplier: Number): void
		{
			var moddedBuildings: Array = GV.ingameCore[Constants.MODDED_BUILDING_ARRAY_ID] as Array;
			for (var i: int = moddedBuildings.length - 1; i >= 0; i--)
			{
				(moddedBuildings[i] as ModdedBuilding).doEnterFrame(speedMultiplier);
			}
		}
		
		public static function render(i: int, j: int, building: Object): void
		{
			var moddedBuilding: ModdedBuilding = building as ModdedBuilding;
			
			if (moddedBuilding != null)
			{
				var mtx: Matrix = new Matrix(1, 0, 0, 1, 28 * j, 28 * i);
				GV.ingameCore.cnt.bmpdBuildings.draw(moddedBuilding.provider.mcShadow, mtx);
				GV.ingameCore.cnt.bmpdBuildings.draw(moddedBuilding.provider.mc, mtx);
			}
		}
		
		public static function ehClickOnField(event: MouseEvent, x: int, y: int, fieldX: int, fieldY: int): void
		{
			var status: int = GV.ingameCore.actionStatus;
			if (checkProvider(status - Constants.BUILDING_REGISTRY_ACTION_STATUS_OFFSET))
			{
				build(status - Constants.BUILDING_REGISTRY_ACTION_STATUS_OFFSET, fieldX, fieldY);
			}
			else if (status == ActionStatus.IDLE || status == ActionStatus.UNIT_SELECTED || status == ActionStatus.BUILDING_SELECTED || status == ActionStatus.CAST_COMBINE_INITIATED)
			{
				if (!event.altKey && !event.ctrlKey)
				{
					var building: ModdedBuilding = GV.ingameCore.buildingAreaMatrix[y][x] as ModdedBuilding;
					if (building != null)
					{
						if (building.insertedGem != null)
						{
							building.select();
						}
						else
						{
							var invIndex: int = GV.ingameCalculator.findFirstFilledInvSlot();
							if (invIndex != -1)
							{
								SB.playSound("sndgemtower");
								building.insertGem(GV.ingameCore.inventorySlots[invIndex] as Gem);
								GV.ingameCore.inventorySlots[invIndex] = null;
								GV.ingameCore.cnt.cntRetinaHud.removeChild(GV.ingameCore.cnt.bmpSlotSelectGlare);
								GV.ingameCore.lastZoneXMax = NaN;
							}
						}
					}
				}
			}
		}
		
		public static function build(provider: int, x: int, y: int): void
		{
			var actualProvider: Object = Registry.BUILDING_REGISTRY.getEntry(provider);
			
			if (GV.ingameController.isBuildingBuildPointFree(x, y, BuildingType.TOWER))
			{
				if (GV.ingameCore.getMana() < GV.ingameCore[Constants.MODDED_BUILDING_COSTS_ID][provider] as Number)
				{
					SB.playSound("sndalert");
					GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60 ? GV.main.mouseY + 30 : GV.main.mouseY - 20, "Not enough mana", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 10000);
					GV.ingameController.deselectEverything(false, false);
				}
				else if (!GV.ingameCalculator.isNew2x2BuildingBlocking(x, y))
				{
					if (GV.ingameCore.freeBuildingsLeft.g() > 0.5)
					{
						GV.ingameCore.freeBuildingsLeft.s(GV.ingameCore.freeBuildingsLeft.g() - 1);
					}
					else
					{
						GV.ingameCore.changeMana(-Math.max(0, GV.ingameCore[Constants.MODDED_BUILDING_COSTS_ID][provider] as Number), false, true);
					}
					GV.ingameCore[Constants.MODDED_BUILDING_COSTS_ID][provider] += actualProvider.buildCostIncrease();
					
					GV.ingameCreator.dfBeaconPlacement = true;
					
					for (var dx: int = 0; dx < 2; dx++)
					{
						for (var dy: int = 0; dy < 2; dy++)
						{
							if (x + dx >= 60 || y + dy >= 38)
							{
								continue;
							}
							
							var wall: Wall = GV.ingameCore.buildingAreaMatrix[y + dy][x + dx] as Wall;
							if (wall != null)
							{
								var indexOf: int = GV.ingameCore.walls.indexOf(wall);
								if (indexOf == GV.ingameCore.walls.length - 1)
								{
									GV.ingameCore.walls.pop();
								}
								else
								{
									GV.ingameCore.walls[indexOf] = GV.ingameCore.walls.pop();
								}
							}
						}
					}
					
					var moddedBuilding: ModdedBuilding = new ModdedBuilding(provider, x, y);
					(GV.ingameCore[Constants.MODDED_BUILDING_ARRAY_ID] as Array).push(moddedBuilding);
					
					GV.ingameCore.buildingAreaMatrix[y][x] = moddedBuilding;
					GV.ingameCore.buildingAreaMatrix[y + 1][x] = moddedBuilding;
					GV.ingameCore.buildingAreaMatrix[y][x + 1] = moddedBuilding;
					GV.ingameCore.buildingAreaMatrix[y + 1][x + 1] = moddedBuilding;
					
					GV.ingameCore.buildingRegPtMatrix[y][x] = moddedBuilding;
					GV.ingameCore.buildingRegPtMatrix[y + 1][x] = null;
					GV.ingameCore.buildingRegPtMatrix[y][x + 1] = null;
					GV.ingameCore.buildingRegPtMatrix[y + 1][x + 1] = null;
					
					GV.vfxEngine.createTowerBuildSmoke(28 + 28 * x, 28 + 28 * y);
					SB.playSound("sndbuildtower");
					
					var rect: Rectangle = new Rectangle(x, y, 2, 2);
					GV.ingameCore.cnt.bmpdTowerPlaceAvailMap.fillRect(rect, 2952790016);
					GV.ingameCore.cnt.bmpdWallPlaceAvailMap.fillRect(rect, 2952790016);
					GV.ingameCore.cnt.bmpdTrapPlaceAvailMap.fillRect(rect, 2952790016);
					
					GV.ingameRenderer2.redrawHighBuildings();
					GV.ingameRenderer2.redrawWalls();
					
					if (GV.ingameCore.groundMatrix[y][x] == "#" || GV.ingameCore.groundMatrix[y + 1][x] == "#" || GV.ingameCore.groundMatrix[y][x + 1] == "#" || GV.ingameCore.groundMatrix[y + 1][x + 1] == "#")
					{
						GV.ingameCore.resetAllPNNMatrices();
					}
					
					for (var mi: int = GV.ingameCore.monstersOnScene.length - 1; mi >= 0; mi--)
					{
						var monster: Monster = GV.ingameCore.monstersOnScene[mi] as Monster;
						if (monster == null)
						{
							if (mi == GV.ingameCore.monstersOnScene.length - 1)
							{
								GV.ingameCore.monstersOnScene.pop();
							}
							else
							{
								GV.ingameCore.monstersOnScene[mi] = GV.ingameCore.monstersOnScene.pop();
							}
						}
						else
						{
							monster.getNextPatrolSector();
						}
					}
					
					for (var oi: int = 0; oi < GV.ingameCore.orblets.length; oi++)
					{
						var orblet: Orblet = GV.ingameCore.orblets[oi] as Orblet;
						if (orblet.status == Orblet.ST_DROPPED)
						{
							orblet.getNextPatrolSector();
						}
					}
					
					if (GV.ingameCore.getMana() < GV.ingameCore[Constants.MODDED_BUILDING_COSTS_ID][provider] as Number && GV.ingameCore.freeBuildingsLeft.g() < 0.5)
					{
						GV.ingameController.deselectEverything(false, false);
					}
				}
			}
			else
			{
				SB.playSound("sndalert");
				GV.vfxEngine.createFloatingText4(GV.main.mouseX, GV.main.mouseY < 60 ? GV.main.mouseY + 30 : GV.main.mouseY - 20, "Can't build", 16768392, 12, "center", Math.random() * 3 - 1.5, -4 - Math.random() * 3, 0, 0.55, 12, 0, 10000);
			}
		}
		
		public static function destroy(building: Object, x: int, y: int, isByPlayer: Boolean, isByEnemy: Boolean): Boolean
		{
			var moddedBuilding: ModdedBuilding = building as ModdedBuilding;
			
			if (moddedBuilding == null)
			{
				return false;
			}
			else
			{
				if (moddedBuilding.insertedGem == GV.ingameCore.draggedGem && !isByPlayer)
				{
					GV.ingameController.deselectEverything(true, true);
				}
				
				if (moddedBuilding.insertedGem == null || !isByPlayer)
				{
					if (moddedBuilding.insertedGem != null)
					{
						GV.ingameCore.cnt.cntDraggedGem.removeChild(moddedBuilding.insertedGem.mc);
						GV.ingameCore.cnt.cntGemsInInventory.removeChild(moddedBuilding.insertedGem.mc);
						GV.ingameCore.cnt.cntGemsInTowers.removeChild(moddedBuilding.insertedGem.mc);
						GV.ingameCore.cnt.cntGemInEnragingSlot.removeChild(moddedBuilding.insertedGem.mc);
						GV.ingameCore.cnt.cntRetinaHud.removeChild(moddedBuilding.insertedGem.mc);
						
						var indexOfG: int = GV.ingameCore.gems.indexOf(moddedBuilding.insertedGem);
						if (indexOfG != -1)
						{
							if (indexOfG == GV.ingameCore.gems.length - 1)
							{
								GV.ingameCore.gems.pop();
							}
							else
							{
								GV.ingameCore.gems[indexOfG] = GV.ingameCore.gems.pop();
							}
							
							if (isByEnemy)
							{
								GV.ingameStats.gemsLost++;
							}
							
							moddedBuilding.insertedGem.removeData();
						}
					}
					
					var moddedBuildings: Array = GV.ingameCore[Constants.MODDED_BUILDING_ARRAY_ID] as Array;
					var indexOfB: int = moddedBuildings.indexOf(moddedBuilding);
					if (indexOfB != -1)
					{
						if (indexOfB == moddedBuildings.length - 1)
						{
							
							moddedBuildings.pop();
						}
						else
						{
							moddedBuildings[indexOfB] = moddedBuildings.pop();
						}
					}
					
					GV.ingameDestroyer.clearAvailMaps2x2(moddedBuilding.fieldX, moddedBuilding.fieldY);
			
					return true;
				}
				
				return false;
			}
		}
		
		internal static function resetBuildCosts(): void
		{
			var tempCosts: Array = [];
			
			for (var i: int = 0; i < Registry.BUILDING_REGISTRY.entryCount; i++)
			{
				tempCosts.push(Registry.BUILDING_REGISTRY.getEntry(i).buildCostBase);
			}
			
			GV.ingameCore[Constants.MODDED_BUILDING_COSTS_ID] = tempCosts;
		}
		
		private static function checkProvider(provider: int): Boolean
		{
			return provider >= 0 && provider < Registry.BUILDING_REGISTRY.entryCount;
		}
		
		public function ModdedBuilding(provider: int, fieldX: int, fieldY: int)
		{
			this.provider = Registry.BUILDING_REGISTRY.getEntry(provider);
			
			this.fieldX = fieldX;
			this.fieldY = fieldY;
			x = fieldX * 28 + 28;
			y = fieldY * 28 + 28;
			
			insertedGem = null;
			
			mcChargeMeter = new McChargeMeter();
			mcChargeMeter.x = x - 28 + 50;
			mcChargeMeter.y = y - 28 + 8;
			
			mcChargeMeter.fullCharge.visible = false;
			
			isDestroyed = false;
		}
		
		public function select(): void
		{
			GV.ingameCore[Constants.SELECTED_MODDED_BUILDING_ID] = this;
			GV.ingameCore.cnt.mcBuildingSelectGlare.gotoAndStop(1);
			GV.ingameCore.cnt.mcBuildingSelectGlare.x = x + 20;
			GV.ingameCore.cnt.mcBuildingSelectGlare.y = y - 20;
			GV.ingameCore.cnt.cntRetinaHud.addChild(GV.ingameCore.cnt.mcBuildingSelectGlare);
			
			if (insertedGem != null)
			{
				if (GV.ingameCore.actionStatus == ActionStatus.CAST_COMBINE_INITIATED)
				{
					GV.ingameCore.actionStatus = Constants.ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_COMBINE;
				}
				else if (GV.ingameCore.actionStatus == ActionStatus.CAST_GEMBOMB_INITIATED)
				{
					GV.ingameCore.actionStatus = Constants.ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_TO_THROW;
				}
				else
				{
					GV.ingameCore.actionStatus = Constants.ACTIONSTATUS_DRAGGING_GEM_FROM_MODDEDBUILDING_IDLE;
				}
				
				GV.ingameCore.inputHandler.startGemDrag(insertedGem);
				SB.playSound("sndgeminbuilding");
			}
			else
			{
				SB.playSound("sndbuttonclick");
				GV.ingameController.deselectEverything(true, true);
			}
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
											normalTargets.forEach(attackTargetWrapper);
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
											enhancedTargets.forEach(enhancedAttackTargetWrapper);
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
		
		public function removeGem(): void
		{
			if (insertedGem != null)
			{
				GV.ingameCore.cnt.cntRetinaHud.removeChild(mcChargeMeter);
				insertedGem.containingBuilding = null;
				insertedGem.recalculateSds();
				insertedGem = null;
				GV.ingameStats.gemsOnTheField--;
			}
		}
		
		public function insertGem(gem: Gem, skipCooldown: Boolean = false): void
		{
			if (gem != null)
			{
				if (insertedGem != null)
				{
					removeGem();
				}
				
				insertedGem = gem;
				insertedGem.containingBuilding = this;
				insertedGem.showInTower();
				insertedGem.xInBuilding = x;
				insertedGem.yInBuilding = y;
				
				if (skipCooldown)
				{
					cooldownTimer = 0;
					isCoolingDown = false;
					GV.ingameCore.cnt.cntRetinaHud.removeChild(mcChargeMeter);
				}
				else
				{
					cooldownTimer = 100;
					isCoolingDown = true;
					GV.ingameCore.cnt.cntRetinaHud.addChild(mcChargeMeter);
					mcChargeMeter.gotoAndStop(1);
				}
				
				insertedGem.dropAnimFrame = 10;
				
				positionGem();
				
				GV.ingameController.cnt.cntGemsInTowers.addChild(insertedGem.mc);
				GV.ingameCalculator.amplifyGem(insertedGem, fieldX, fieldY, false);
				
				shotColor = ColorToolbox.hsbToRgb(insertedGem.hasColor ? [insertedGem.hueMain, 100, 100] : [0, 0, 100]);
				ctrShot = new ColorTransform(0, 0, 0, 1, shotColor[0], shotColor[1], shotColor[2], 0);
				
				normalCharge = 0;
				normalTimeUntilNextTargetCheck = 0;
				
				enhancedCharge = 0;
				enhancedTimeUntilNextTargetCheck = 0;
				
				insertedGem.recalculateSds();
				
				GV.ingameStats.gemsOnTheField++;
			}
		}
		
		private function attackTargetWrapper(target: ModdedBuildingTarget, index: int, array: Array): void
		{
			attackTarget(target.target, target.isMarkableForDeath);
		}
		
		private function enhancedAttackTargetWrapper(target: ModdedBuildingTarget, index: int, array: Array): void
		{
			enhancedAttackTarget(target.target, target.isMarkableForDeath);
		}
		
		private function createProjectile(enhancement: int, target: Object, rawDamage: Number, shotColor: Array, markableForDeath: Boolean, isKillingShot: Boolean): void
		{
			var projectileProvider: Object = provider.projectile(enhancement);
			var shotData: ShotData = (enhancement == GemEnhancementId.NONE ? insertedGem.sd4_IntensityMod : insertedGem.sd5_EnhancedOrTrapOrLantern);
			
			var projectile: ModdedProjectile = new ModdedProjectile(projectileProvider, this, shotColor, shotData, target, rawDamage, markableForDeath, isKillingShot, provider.isRawDamage(enhancement));
			
			(GV.ingameCore[Constants.MODDED_PROJECTILE_ARRAY_ID] as Array).push(projectile);
		}
		
		// TODO: return boolean and only retarget if one or more dies
		private function attackTarget(target: Object, isMarkableForDeath: Boolean): void
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
			
			if (isMarkableForDeath)
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
			
			createProjectile(insertedGem.enhancementType, target, actualDamageRaw, shotColor, isMarkableForDeath, isKillingShot);
		}
		
		private function enhancedAttackTarget(target: Object, isMarkableForDeath: Boolean): void
		{
			if (insertedGem.e_ammoLeft.g() >= 1)
			{
				insertedGem.e_ammoLeft.s(insertedGem.e_ammoLeft.g() - provider.enhancementAmmoUsage(insertedGem.enhancementType));
				attackTarget(target, isMarkableForDeath);
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
			
			return newTargets.map(function (target: Object, index: int, array: Array): ModdedBuildingTarget
			{
				return new ModdedBuildingTarget(target);
			});
		}
		
		private function positionGem(param: Boolean = false): void
		{
			insertedGem.mc.x = x - 2 + 50;
			insertedGem.mcDropAnimTargetY = insertedGem.mc.y = this.y - 2.5 + 8
			
			if (param)
			{
				insertedGem.dropAnimFrame = 10;
			}
		}
	}
}

import com.giab.games.gcfw.entity.Apparition;
import com.giab.games.gcfw.entity.GateKeeper;
import com.giab.games.gcfw.entity.GateKeeperFang;
import com.giab.games.gcfw.entity.Guardian;
import com.giab.games.gcfw.entity.Monster;
import com.giab.games.gcfw.entity.Shadow;
import com.giab.games.gcfw.entity.Specter;
import com.giab.games.gcfw.entity.Spire;
import com.giab.games.gcfw.entity.SwarmQueen;
import com.giab.games.gcfw.entity.WallBreaker;
import com.giab.games.gcfw.entity.WizardHunter;
import com.giab.games.gcfw.entity.Wraith;

class ModdedBuildingTarget
{
	public var target: Object;
	public var isMarkableForDeath: Boolean;
	
	public function ModdedBuildingTarget(target: Object)
	{
		this.target = target;
		
		isMarkableForDeath = target is Specter || target is WizardHunter || target is WallBreaker || target is Guardian ||
							 target is Shadow || target is Spire || target is Wraith || target is Apparition ||
							 target is SwarmQueen || target is GateKeeper || target is GateKeeperFang || target is Monster;
	}
}