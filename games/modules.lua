local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local vim = cloneref(game:GetService("VirtualInputManager"))
local starterGui = cloneref(game:GetService('StarterGui'))
local TeleportService = cloneref(game:GetService("TeleportService"))
local lightingService = cloneref(game:GetService('Lighting'))
local isnetworkowner = identifyexecutor and table.find({'Nihon','Volt', 'Seliware'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {}
}
local Reach = {}
local HitBoxes = {}
local InfiniteFly
local AntiFallPart
local Speed
local Fly
local Breaker
local Scaffold
local AutoTool
local TaxRemover
local bedwars, remotes, sides, oldinvrender, oldSwing = {}, {}, {}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('newvape/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end
local function GetBestItemToBreakBlock(Type: string)
    local Inventory = GetInventory()
    local Data = {
        Item = nil,
        Damage = 0
    }

    if Inventory and Inventory.items then
        for i,v in Inventory.items do
            local Meta = GameData.Utils.ItemMeta[v.itemType]
            if Meta and Meta.breakBlock then
                for i2: string, v2: number in Meta.breakBlock do
                    if Type:lower():find(i2:lower()) and v2 > Data.Damage then
                        Data = {
                            Item = v.tool,
                            Damage = v2
                        }
                    end
                end

            end
        end
    end

    return Data
end

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end

local function getBestArmor(slot)
	local closest, mag = nil, 0

	for _, item in store.inventory.inventory.items do
		local meta = item and bedwars.ItemMeta[item.itemType] or {}

		if meta.armor and meta.armor.slot == slot then
			local newmag = (meta.armor.damageReductionMultiplier or 0)

			if newmag > mag then
				closest, mag = item, newmag
			end
		end
	end

	return closest
end

local function getBow()
	local bestBow, bestBowSlot, bestBowDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local bowMeta = bedwars.ItemMeta[item.itemType].projectileSource
		if bowMeta and table.find(bowMeta.ammoItemTypes, 'arrow') then
			local bowDamage = bedwars.ProjectileMeta[bowMeta.projectileType('arrow')].combat.damage or 0
			if bowDamage > bestBowDamage then
				bestBow, bestBowSlot, bestBowDamage = item, slot, bowDamage
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getItem(itemName, inv)
	for slot, item in (inv or store.inventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end

local function getRoactRender(func)
	return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local swordMeta = bedwars.ItemMeta[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getTool(breakType)
	local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local toolMeta = bedwars.ItemMeta[item.itemType].breakBlock
		if toolMeta then
			local toolDamage = toolMeta[breakType] or 0
			if toolDamage > bestToolDamage then
				bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
			end
		end
	end
	return bestTool, bestToolSlot
end

local function getWool()
	for _, wool in (inv or store.inventory.inventory.items) do
		if wool.itemType:find('wool') then
			return wool and wool.itemType, wool and wool.amount
		end
	end
end

local function getStrength(plr)
	if not plr.Player then
		return 0
	end

	local strength = 0
	for _, v in (store.inventories[plr.Player] or {items = {}}).items do
		local itemmeta = bedwars.ItemMeta[v.itemType]
		if itemmeta and itemmeta.sword and itemmeta.sword.damage > strength then
			strength = itemmeta.sword.damage
		end
	end

	return strength
end

local function getPlacedBlock(pos)
	if not pos then
		return
	end
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local function getBlocksInPoints(s, e)
	local blocks, list = bedwars.BlockController:getStore(), {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					table.insert(list, vec * 3)
				end
			end
		end
	end
	return list
end

local function getNearGround(range)
	range = Vector3.new(3, 3, 3) * (range or 10)
	local localPosition, mag, closest = entitylib.character.RootPart.Position, 60
	local blocks = getBlocksInPoints(bedwars.BlockController:getBlockPosition(localPosition - range), bedwars.BlockController:getBlockPosition(localPosition + range))

	for _, v in blocks do
		if not getPlacedBlock(v + Vector3.new(0, 3, 0)) then
			local newmag = (localPosition - v).Magnitude
			if newmag < mag then
				mag, closest = newmag, v + Vector3.new(0, 3, 0)
			end
		end
	end

	table.clear(blocks)
	return closest
end

local function getShieldAttribute(char)
	local returned = 0
	for name, val in char:GetAttributes() do
		if name:find('Shield') and type(val) == 'number' and val > 0 then
			returned += val
		end
	end
	return returned
end

local function getSpeed()
	local multi, increase, modifiers = 0, true, bedwars.SprintController:getMovementStatusModifier():getModifiers()

	for v in modifiers do
		local val = v.constantSpeedMultiplier and v.constantSpeedMultiplier or 0
		if val and val > math.max(multi, 1) then
			increase = false
			multi = val - (0.06 * math.round(val))
		end
	end

	for v in modifiers do
		multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
	end

	if multi > 0 and increase then
		multi += 0.16 + (0.02 * math.round(multi))
	end

	return 20 * (multi + 1)
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do
		ind += 1
	end
	return ind
end

local function hotbarSwitch(slot)
	if slot and store.inventory.hotbarSlot ~= slot then
		bedwars.Store:dispatch({
			type = 'InventorySelectHotbarSlot',
			slot = slot
		})
		vapeEvents.InventoryChanged.Event:Wait()
		return true
	end
	return false
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...) return
	vape:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function roundPos(vec)
	return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
end

local function switchItem(tool, delayTime)
	delayTime = delayTime or 0.05
	local check = lplr.Character and lplr.Character:FindFirstChild('HandInvItem') or nil
	if check and check.Value ~= tool and tool.Parent ~= nil then
		task.spawn(function()
			bedwars.Client:Get(remotes.EquipItem):CallServerAsync({hand = tool})
		end)
		check.Value = tool
		if delayTime > 0 then
			task.wait(delayTime)
		end
		return true
	end
end

local function waitForChildOfType(obj, name, timeout, prop)
	local check, returned = tick() + timeout
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned and returned.Name ~= 'UpperTorso' or check < tick() then
			break
		end
		task.wait()
	until false
	return returned
end

local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(v)
	if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
		oldfrict[v] = v.CustomPhysicalProperties or 'none'
		v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end
		if newState then
			if entitylib.isAlive then
				for _, v in entitylib.character.Character:GetDescendants() do
					modifyVelocity(v)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for i, v in oldfrict do
				i.CustomPhysicalProperties = v ~= 'none' and v or nil
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

local kitorder = {
	hannah = 5,
	spirit_assassin = 4,
	dasher = 3,
	jade = 2,
	regent = 1
}

local sortmethods = {
	Damage = function(a, b)
		return a.Entity.Character:GetAttribute('LastDamageTakenTime') < b.Entity.Character:GetAttribute('LastDamageTakenTime')
	end,
	Threat = function(a, b)
		return getStrength(a.Entity) > getStrength(b.Entity)
	end,
	Kit = function(a, b)
		return (a.Entity.Player and kitorder[a.Entity.Player:GetAttribute('PlayingAsKit')] or 0) > (b.Entity.Player and kitorder[b.Entity.Player:GetAttribute('PlayingAsKit')] or 0)
	end,
	Health = function(a, b)
		return a.Entity.Health < b.Entity.Health
	end,
	Angle = function(a, b)
		local selfrootpos = entitylib.character.RootPart.Position
		local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		local angle = math.acos(localfacing:Dot(((a.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		local angle2 = math.acos(localfacing:Dot(((b.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		return angle < angle2
	end
}

run(function()
	local oldstart = entitylib.start
	local function customEntity(ent)
		if ent:HasTag('inventory-entity') and not ent:HasTag('Monster') then
			return
		end

		entitylib.addEntity(ent, nil, ent:HasTag('Drone') and function(self)
			local droneplr = playersService:GetPlayerByUserId(self.Character:GetAttribute('PlayerUserId'))
			return not droneplr or lplr:GetAttribute('Team') ~= droneplr:GetAttribute('Team')
		end or function(self)
			return lplr:GetAttribute('Team') ~= self.Character:GetAttribute('Team')
		end)
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('entity') do
				customEntity(ent)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('entity'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('entity'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
		end
	end

	entitylib.addPlayer = function(plr)
		if plr.Character then
			entitylib.refreshEntity(plr.Character, plr)
		end
		entitylib.PlayerConnections[plr] = {
			plr.CharacterAdded:Connect(function(char)
				entitylib.refreshEntity(char, plr)
			end),
			plr.CharacterRemoving:Connect(function(char)
				entitylib.removeEntity(char, plr == lplr)
			end),
			plr:GetAttributeChangedSignal('Team'):Connect(function()
				for _, v in entitylib.List do
					if v.Targetable ~= entitylib.targetCheck(v) then
						entitylib.refreshEntity(v.Character, v.Player)
					end
				end

				if plr == lplr then
					entitylib.start()
				else
					entitylib.refreshEntity(plr.Character, plr)
				end
			end)
		}
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum, humrootpart, head
			if plr then
				hum = waitForChildOfType(char, 'Humanoid', 10)
				humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
				head = char:WaitForChild('Head', 10) or humrootpart
			else
				hum = {HipHeight = 0.5}
				humrootpart = waitForChildOfType(char, 'PrimaryPart', 10, true)
				head = humrootpart
			end
			local updateobjects = plr and plr ~= lplr and {
				char:WaitForChild('ArmorInvItem_0', 5),
				char:WaitForChild('ArmorInvItem_1', 5),
				char:WaitForChild('ArmorInvItem_2', 5),
				char:WaitForChild('HandInvItem', 5)
			} or {}

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char),
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					Jumps = 0,
					JumpTick = tick(),
					Jumping = false,
					LandTick = tick(),
					MaxHealth = char:GetAttribute('MaxHealth') or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entity.AirTime = tick()
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
					table.insert(entitylib.Connections, char.AttributeChanged:Connect(function(attr)
						vapeEvents.AttributeChanged:Fire(attr)
					end))
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entity.Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char)
							entity.MaxHealth = char:GetAttribute('MaxHealth') or 100
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					for _, v in updateobjects do
						table.insert(entity.Connections, v:GetPropertyChangedSignal('Value'):Connect(function()
							task.delay(0.1, function()
								if bedwars.getInventory then
									store.inventories[plr] = bedwars.getInventory(plr)
									entitylib.Events.EntityUpdated:Fire(entity)
								end
							end)
						end))
					end

					if plr then
						local anim = char:FindFirstChild('Animate')
						if anim then
							pcall(function()
								anim = anim.jump:FindFirstChildWhichIsA('Animation').AnimationId
								table.insert(entity.Connections, hum.Animator.AnimationPlayed:Connect(function(playedanim)
									if playedanim.Animation.AnimationId == anim then
										entity.JumpTick = tick()
										entity.Jumps += 1
										entity.LandTick = tick() + 1
										entity.Jumping = entity.Jumps > 1
									end
								end))
							end)
						end

						task.delay(0.1, function()
							if bedwars.getInventory then
								store.inventories[plr] = bedwars.getInventory(plr)
							end
						end)
					end
					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end

				table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
					if part == humrootpart or part == hum or part == head then
						if part == humrootpart and hum.RootPart then
							humrootpart = hum.RootPart
							entity.RootPart = hum.RootPart
							entity.HumanoidRootPart = hum.RootPart
							return
						end
						entitylib.removeEntity(char, plr == lplr)
					end
				end))
			end
			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.getUpdateConnections = function(ent)
		local char = ent.Character
		local tab = {
			char:GetAttributeChangedSignal('Health'),
			char:GetAttributeChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}

		if ent.Player then
			table.insert(tab, ent.Player:GetAttributeChangedSignal('PlayingAsKit'))
		end

		for name, val in char:GetAttributes() do
			if name:find('Shield') and type(val) == 'number' then
				table.insert(tab, char:GetAttributeChangedSignal(name))
			end
		end

		return tab
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		return lplr:GetAttribute('Team') ~= ent.Player:GetAttribute('Team')
	end
	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
end)
entitylib.start()
local function safeGetProto(func, index)
    if not func then return nil end
    local success, proto = pcall(safeGetProto, func, index)
    if success then
        return proto
    else
        --warn("function:", func, "index:", index,", WM - proto") 
        return nil
    end
end
run(function()
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit then break end
		task.wait()
	until KnitInit

	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local OldGet, OldBreak = Client.Get

	bedwars = setmetatable({
		SharedConstants = require(replicatedStorage.TS['shared-constants']),		
		AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine,
		BlockEngine = require(lplr.PlayerScripts.TS.lib['block-engine']['client-block-engine']).ClientBlockEngine,
		BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
		BowConstantsTable = debug.getupvalue(Knit.Controllers.ProjectileController.enableBeam, 8),
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		ClientDamageBlock = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.shared.remotes).BlockEngineRemotes.Client,
		CombatConstant = require(replicatedStorage.TS.combat['combat-constant']).CombatConstant,
		DamageIndicator = Knit.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.global.locker['kill-effect'].effects['default-kill-effect']),
		EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
		GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemMeta[item.itemType]
			return itemmeta and showinv and itemmeta.image or ''
		end,
		getInventory = function(plr)
			local suc, res = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return suc and res or {
				items = {},
				armor = {}
			}
		end,
		HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
		ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
		KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
		KillFeedController = Flamework.resolveDependency('client/controllers/game/kill-feed/kill-feed-controller@KillFeedController'),
		Knit = Knit,
		BlockSelector = require(replicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.select["block-selector"]).BlockSelector,
		KnockbackUtilInstance = replicatedStorage.TS.damage['knockback-util'],
		BedwarsKitSkin = require(replicatedStorage.TS.games.bedwars['kit-skin']['bedwars-kit-skin-meta']).BedwarsKitSkinMeta,
		KitController = Knit.Controllers.KitController,
		FishermanUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.fisherman['fisherman-util']).FishermanUtil,
		FishMeta = require(replicatedStorage.TS.games.bedwars.kit.kits.fisherman['fish-meta']),
		MatchHistroyApp = require(lplr.PlayerScripts.TS.controllers.global["match-history"].ui["match-history-moderation-app"]).MatchHistoryModerationApp,
		MatchHistroyController = Knit.Controllers.MatchHistoryController,
		BlockSelectorMode = require(replicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.select["block-selector"]).BlockSelectorMode,
		EntityUtil = require(replicatedStorage.TS.entity["entity-util"]).EntityUtil,
		GamePlayer = require(replicatedStorage.TS.player['game-player']),
		OfflinePlayerUtil = require(replicatedStorage.TS.player['offline-player-util']),
		PlayerUtil = require(replicatedStorage.TS.player['player-util']),
		KKKnitController = require(lplr.PlayerScripts.TS.lib.knit['knit-controller']),
		NotificationController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/notification-controller@NotificationController'),
		PlayerProfileUIController = require(lplr.PlayerScripts.TS.controllers.global['player-profile']['player-profile-ui-controller']),
		KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
		NametagController = Knit.Controllers.NametagController,
		PartyController = Flamework.resolveDependency('@easy-games/lobby:client/controllers/party-controller@PartyController'),
		ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
		QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
		RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
		SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
		SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).SoundManager,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		TeamUpgradeMeta = debug.getupvalue(require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta']).getTeamUpgradeMetaForQueue, 6),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
		WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
		WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
		ZapNetworking = require(lplr.PlayerScripts.TS.lib.network)
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})
	local oldDispatch = bedwars.Store.dispatch
bedwars.Store.dispatch = function(...)
    local arg = select(2, ...)
    if arg and typeof(arg) == 'table' and arg.type == 'IncrementTaxState' and TaxRemover.Enabled then
        return
    end     
    return oldDispatch(...)
end

	

	local remoteNames = {
		AfkStatus = safeGetProto(Knit.Controllers.AfkController.KnitStart, 1),
		AttackEntity = Knit.Controllers.SwordController.sendServerRequest,
		BeePickup = Knit.Controllers.BeeNetController.trigger,
		CannonAim = safeGetProto(Knit.Controllers.CannonController.startAiming, 5),
		CannonLaunch = Knit.Controllers.CannonHandController.launchSelf,
		ConsumeBattery = safeGetProto(Knit.Controllers.BatteryController.onKitLocalActivated, 1),
		ConsumeItem = safeGetProto(Knit.Controllers.ConsumeController.onEnable, 1),
		ConsumeSoul = Knit.Controllers.GrimReaperController.consumeSoul,
		ConsumeTreeOrb = safeGetProto(Knit.Controllers.EldertreeController.createTreeOrbInteraction, 1),
		DepositPinata = safeGetProto(safeGetProto(Knit.Controllers.PiggyBankController.KnitStart, 2), 5),
		DragonBreath = safeGetProto(Knit.Controllers.VoidDragonController.onKitLocalActivated, 5),
		DragonEndFly = safeGetProto(Knit.Controllers.VoidDragonController.flapWings, 1),
		DragonFly = Knit.Controllers.VoidDragonController.flapWings,
		DropItem = Knit.Controllers.ItemDropController.dropItemInHand,
		EquipItem = safeGetProto(require(replicatedStorage.TS.entity.entities['inventory-entity']).InventoryEntity.equipItem, 3),
		FireProjectile = debug.getupvalue(Knit.Controllers.ProjectileController.launchProjectileWithValues, 2),
		GroundHit = Knit.Controllers.FallDamageController.KnitStart,
		GuitarHeal = Knit.Controllers.GuitarController.performHeal,
		HannahKill = safeGetProto(Knit.Controllers.HannahController.registerExecuteInteractions, 1),
		HarvestCrop = safeGetProto(safeGetProto(Knit.Controllers.CropController.KnitStart, 4), 1),
		KaliyahPunch = safeGetProto(Knit.Controllers.DragonSlayerController.onKitLocalActivated, 1),
		MageSelect = safeGetProto(Knit.Controllers.MageController.registerTomeInteraction, 1),
		MinerDig = safeGetProto(Knit.Controllers.MinerController.setupMinerPrompts, 1),
		PickupItem = Knit.Controllers.ItemDropController.checkForPickup,
		PickupMetal = safeGetProto(Knit.Controllers.HiddenMetalController.onKitLocalActivated, 4),
		ReportPlayer = require(lplr.PlayerScripts.TS.controllers.global.report['report-controller']).default.reportPlayer,
		ResetCharacter = safeGetProto(Knit.Controllers.ResetController.createBindable, 1),
		SpawnRaven = safeGetProto(Knit.Controllers.RavenController.KnitStart, 1),
		SummonerClawAttack = Knit.Controllers.SummonerClawHandController.attack,
		WarlockTarget = safeGetProto(Knit.Controllers.WarlockStaffController.KnitStart, 2)
	}

	local function dumpRemote(tab)
		local ind
		for i, v in tab do
			if v == 'Client' then
				ind = i
				break
			end
		end
		return ind and tab[ind + 1] or ''
	end

	for i, v in remoteNames do
		local remote = dumpRemote(debug.getconstants(v))
		if remote == '' then
			notif('Vape', 'Failed to grab remote ('..i..')', 10, 'alert')
		end
		remotes[i] = remote
	end

	OldBreak = bedwars.BlockController.isBlockBreakable

	Client.Get = function(self, remoteName)
		local call = OldGet(self, remoteName)

		if remoteName == remotes.AttackEntity then
			return {
				instance = call.instance,
				SendToServer = function(_, attackTable, ...)
					local suc, plr = pcall(function()
						return playersService:GetPlayerFromCharacter(attackTable.entityInstance)
					end)

					local selfpos = attackTable.validate.selfPosition.value
					local targetpos = attackTable.validate.targetPosition.value
					store.attackReach = ((selfpos - targetpos).Magnitude * 100) // 1 / 100
					store.attackReachUpdate = tick() + 1

					if Reach.Enabled or HitBoxes.Enabled then
						attackTable.validate.raycast = attackTable.validate.raycast or {}
						attackTable.validate.selfPosition.value += CFrame.lookAt(selfpos, targetpos).LookVector * math.max((selfpos - targetpos).Magnitude - 14.399, 0)
					end

					if suc and plr then
						if not select(2, whitelist:get(plr)) then return end
					end

					return call:SendToServer(attackTable, ...)
				end
			}
		elseif remoteName == 'StepOnSnapTrap' and TrapDisabler.Enabled then
			return {SendToServer = function() end}
		end

		return call
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)

		if obj and obj.Name == 'bed' then
			for _, plr in playersService:GetPlayers() do
				if obj:GetAttribute('Team'..(plr:GetAttribute('Team') or 0)..'NoBreak') and not select(2, whitelist:get(plr)) then
					return false
				end
			end
		end

		return OldBreak(self, breakTable, plr)
	end

	local cache, blockhealthbar = {}, {blockHealth = -1, breakingBlockPosition = Vector3.zero}
	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, 'wool_white')

	local function getBlockHealth(block, blockpos)
		local blockdata = bedwars.BlockController:getStore():getBlockData(blockpos)
		return (blockdata and (blockdata:GetAttribute('1') or blockdata:GetAttribute('Health')) or block:GetAttribute('Health'))
	end

	local function getBlockHits(block, blockpos)
		if not block then return 0 end
		local breaktype = bedwars.ItemMeta[block.Name].block.breakType
		local tool = store.tools[breaktype]
		tool = tool and bedwars.ItemMeta[tool.itemType].breakBlock[breaktype] or 2
		return getBlockHealth(block, bedwars.BlockController:getBlockPosition(blockpos)) / tool
	end

	--[[
		Pathfinding using a luau version of dijkstra's algorithm
		Source: https://stackoverflow.com/questions/39355587/speeding-up-dijkstras-algorithm-to-solve-a-3d-maze
	]]
	local function calculatePath(target, blockpos)
		if cache[blockpos] then
			return unpack(cache[blockpos])
		end
		local visited, unvisited, distances, air, path = {}, {{0, blockpos}}, {[blockpos] = 0}, {}, {}

		for _ = 1, 10000 do
			local _, node = next(unvisited)
			if not node then break end
			table.remove(unvisited, 1)
			visited[node[2]] = true

			for _, side in sides do
				side = node[2] + side
				if visited[side] then continue end

				local block = getPlacedBlock(side)
				if not block or block:GetAttribute('NoBreak') or block == target then
					if not block then
						air[node[2]] = true
					end
					continue
				end

				local curdist = getBlockHits(block, side) + node[1]
				if curdist < (distances[side] or math.huge) then
					table.insert(unvisited, {curdist, side})
					distances[side] = curdist
					path[side] = node[2]
				end
			end
		end

		local pos, cost = nil, math.huge
		for node in air do
			if distances[node] < cost then
				pos, cost = node, distances[node]
			end
		end

		if pos then
			cache[blockpos] = {
				pos,
				cost,
				path
			}
			return pos, cost, path
		end
	end

	bedwars.placeBlock = function(pos, item)
		if getItem(item) then
			store.blockPlacer.blockType = item
			return store.blockPlacer:placeBlock(bedwars.BlockController:getBlockPosition(pos))
		end
	end

	bedwars.breakBlock = function(block, effects, anim, customHealthbar)
		if lplr:GetAttribute('DenyBlockBreak') or not entitylib.isAlive or InfiniteFly.Enabled then return end
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
		local cost, pos, target, path = math.huge

		for _, v in (handler and handler:getContainedPositions(block) or {block.Position / 3}) do
			local dpos, dcost, dpath = calculatePath(block, v * 3)
			if dpos and dcost < cost then
				cost, pos, target, path = dcost, dpos, v * 3, dpath
			end
		end

		if pos then
			if (entitylib.character.RootPart.Position - pos).Magnitude > 30 then return end
			local dblock, dpos = getPlacedBlock(pos)
			if not dblock then return end

			if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.4 then
				local breaktype = bedwars.ItemMeta[dblock.Name].block.breakType
				local tool = store.tools[breaktype]
				if tool then
					switchItem(tool.tool)
				end
			end

			if blockhealthbar.blockHealth == -1 or dpos ~= blockhealthbar.breakingBlockPosition then
				blockhealthbar.blockHealth = getBlockHealth(dblock, dpos)
				blockhealthbar.breakingBlockPosition = dpos
			end

			bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync({
				blockRef = {blockPosition = dpos},
				hitPosition = pos,
				hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
			}):andThen(function(result)
				if result then
					if result == 'cancelled' then
						store.damageBlockFail = tick() + 1
						return
					end

					if effects then
						local blockdmg = (blockhealthbar.blockHealth - (result == 'destroyed' and 0 or getBlockHealth(dblock, dpos)))
						customHealthbar = customHealthbar or bedwars.BlockBreaker.updateHealthbar
						customHealthbar(bedwars.BlockBreaker, {blockPosition = dpos}, blockhealthbar.blockHealth, dblock:GetAttribute('MaxHealth'), blockdmg, dblock)
						blockhealthbar.blockHealth = math.max(blockhealthbar.blockHealth - blockdmg, 0)

						if blockhealthbar.blockHealth <= 0 then
							bedwars.BlockBreaker.breakEffect:playBreak(dblock.Name, dpos, lplr)
							bedwars.BlockBreaker.healthbarMaid:DoCleaning()
							blockhealthbar.breakingBlockPosition = Vector3.zero
						else
							bedwars.BlockBreaker.breakEffect:playHit(dblock.Name, dpos, lplr)
						end
					end

					if anim then
						local animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
						bedwars.ViewmodelController:playAnimation(15)
						task.wait(0.3)
						animation:Stop()
						animation:Destroy()
					end
				end
			end)

			if effects then
				return pos, path, target
			end
		end
	end

	for _, v in Enum.NormalId:GetEnumItems() do
		table.insert(sides, Vector3.FromNormalId(v) * 3)
	end

	local function updateStore(new, old)
		if new.Bedwars ~= old.Bedwars then
			store.equippedKit = new.Bedwars.kit ~= 'none' and new.Bedwars.kit or ''
		end

		if new.Game ~= old.Game then
			store.matchState = new.Game.matchState
			store.queueType = new.Game.queueType or 'bedwars_test'
		end

		if new.Inventory ~= old.Inventory then
			local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
			local oldinv = (old.Inventory and old.Inventory.observedInventory or {inventory = {}})
			store.inventory = newinv

			if newinv ~= oldinv then
				vapeEvents.InventoryChanged:Fire()
			end

			if newinv.inventory.items ~= oldinv.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
				store.tools.sword = getSword()
				for _, v in {'stone', 'wood', 'wool'} do
					store.tools[v] = getTool(v)
				end
			end

			if newinv.inventory.hand ~= oldinv.inventory.hand then
				local currentHand, toolType = new.Inventory.observedInventory.inventory.hand, ''
				if currentHand then
					local handData = bedwars.ItemMeta[currentHand.itemType]
					toolType = handData.sword and 'sword' or handData.block and 'block' or currentHand.itemType:find('bow') and 'bow'
				end

				store.hand = {
					tool = currentHand and currentHand.tool,
					amount = currentHand and currentHand.amount or 0,
					toolType = toolType
				}
			end
		end
	end

	local storeChanged = bedwars.Store.changed:connect(updateStore)
	updateStore(bedwars.Store:getState(), {})

	for _, event in {'MatchEndEvent', 'EntityDeathEvent', 'BedwarsBedBreak', 'BalloonPopped', 'AngelProgress', 'GrapplingHookFunctions'} do
		if not vape.Connections then return end
		bedwars.Client:WaitFor(event):andThen(function(connection)
			vape:Clean(connection:Connect(function(...)
				vapeEvents[event]:Fire(...)
			end))
		end)
	end

	vape:Clean(bedwars.ZapNetworking.EntityDamageEventZap.On(function(...)
		vapeEvents.EntityDamageEvent:Fire({
			entityInstance = ...,
			damage = select(2, ...),
			damageType = select(3, ...),
			fromPosition = select(4, ...),
			fromEntity = select(5, ...),
			knockbackMultiplier = select(6, ...),
			knockbackId = select(7, ...),
			disableDamageHighlight = select(13, ...)
		})
	end))

	for _, event in {'PlaceBlockEvent', 'BreakBlockEvent'} do
		vape:Clean(bedwars.ZapNetworking[event..'Zap'].On(function(...)
			local data = {
				blockRef = {
					blockPosition = ...,
				},
				player = select(5, ...)
			}
			for i, v in cache do
				if ((data.blockRef.blockPosition * 3) - v[1]).Magnitude <= 30 then
					table.clear(v[3])
					table.clear(v)
					cache[i] = nil
				end
			end
			vapeEvents[event]:Fire(data)
		end))
	end

	store.blocks = collection('block', gui)
	store.shop = collection({'BedwarsItemShop', 'TeamUpgradeShopkeeper'}, gui, function(tab, obj)
		table.insert(tab, {
			Id = obj.Name,
			RootPart = obj,
			Shop = obj:HasTag('BedwarsItemShop'),
			Upgrades = obj:HasTag('TeamUpgradeShopkeeper')
		})
	end)
	store.enchant = collection({'enchant-table', 'broken-enchant-table'}, gui, nil, function(tab, obj, tag)
		if obj:HasTag('enchant-table') and tag == 'broken-enchant-table' then return end
		obj = table.find(tab, obj)
		if obj then
			table.remove(tab, obj)
		end
	end)

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	task.delay(1, function()
		games:Increment()
	end)

	task.spawn(function()
		pcall(function()
			repeat task.wait() until store.matchState ~= 0 or vape.Loaded == nil
			if vape.Loaded == nil then return end
			mapname = workspace:WaitForChild('Map', 5):WaitForChild('Worlds', 5):GetChildren()[1].Name
			mapname = string.gsub(string.split(mapname, '_')[2] or mapname, '-', '') or 'Blank'
		end)
	end)

	vape:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
		if bedTable.player and bedTable.player.UserId == lplr.UserId then
			beds:Increment()
		end
	end))

	vape:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winTable)
		if (bedwars.Store:getState().Game.myTeam or {}).id == winTable.winningTeamId or lplr.Neutral then
			wins:Increment()
		end
	end))

	vape:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
		local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
		local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
		if not killed or not killer then return end

		if killed ~= lplr and killer == lplr then
			kills:Increment()
		end
	end))

	task.spawn(function()
		repeat
			if entitylib.isAlive then
				entitylib.character.AirTime = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entitylib.character.AirTime
			end

			for _, v in entitylib.List do
				v.LandTick = math.abs(v.RootPart.Velocity.Y) < 0.1 and v.LandTick or tick()
				if (tick() - v.LandTick) > 0.2 and v.Jumps ~= 0 then
					v.Jumps = 0
					v.Jumping = false
				end
			end
			task.wait()
		until vape.Loaded == nil
	end)

	pcall(function()
		if getthreadidentity and setthreadidentity then
			local old = getthreadidentity()
			setthreadidentity(2)

			bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
			bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
			bedwars.Shop.getShopItem('iron_sword', lplr)

			setthreadidentity(old)
			store.shopLoaded = true
		else
			task.spawn(function()
				repeat
					task.wait(0.1)
				until vape.Loaded == nil or bedwars.AppController:isAppOpen('BedwarsItemShopApp')

				bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
				bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
				store.shopLoaded = true
			end)
		end
	end)

	vape:Clean(function()
		Client.Get = OldGet
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
		for _, v in vapeEvents do
			v:Destroy()
		end
		for _, v in cache do
			table.clear(v[3])
			table.clear(v)
		end
		table.clear(store.blockPlacer)
		table.clear(vapeEvents)
		table.clear(bedwars)
		table.clear(store)
		table.clear(cache)
		table.clear(sides)
		table.clear(remotes)
		storeChanged:disconnect()
		storeChanged = nil
	end)
end)

run(function()
		local MHA
		MHA = vape.Categories.Legit:CreateModule({
			Name = "MatchHistoryViewer",
			Function = function(callback)
				if callback then
					bedwars.MatchHistroyController:requestMatchHistory(lplr.Name):andThen(function(Data)
						if Data then
							bedwars.AppController:openApp({app = bedwars.MatchHistroyApp,appId = "MatchHistoryApp",},Data)
						end
					end)
					MHA:Toggle(false)
				else
					return
				end
			end,
			Tooltip = "allows you to see peoples history without being in the same game with you"
		})																								
end)

run(function()
	local TaxRemover
	local old = {
		getAddedTax = nil,
		getTaxedItems = nil,
		isTaxed = nil
	}
	TaxRemover = vape.Categories.Blatant:CreateModule({
		Name = "TaxRemover",
		Function = function(callback)
			if callback then
				old.getAddedTax = bedwars.ShopTaxController.getAddedTax
				bedwars.ShopTaxController.getAddedTax = function(...)
					return 0
				end
				old.getTaxedItems = bedwars.ShopTaxController.getTaxedItems
				bedwars.ShopTaxController.getTaxedItems = function(...)
					return {}
				end
				old.isTaxed = bedwars.ShopTaxController.isTaxed
				bedwars.ShopTaxController.isTaxed = function(...)
					return false
				end
			else
				bedwars.ShopTaxController.getAddedTax = old.getAddedTax 
				bedwars.ShopTaxController.getTaxedItems = old.getTaxedItems 
				bedwars.ShopTaxController.isTaxed = old.isTaxed
				old.isTaxed = nil
				old.getAddedTax = nil
				old.getTaxedItems = nil
			end
		end
	})
end)
run(function()
    local KitRender
    local PlayerGui = lplr:WaitForChild("PlayerGui")

    local ids = {
        ['none'] = "rbxassetid://16493320215",
        ["random"] = "rbxassetid://79773209697352",
        ["cowgirl"] = "rbxassetid://9155462968",
        ["davey"] = "rbxassetid://9155464612",
        ["warlock"] = "rbxassetid://15186338366",
        ["ember"] = "rbxassetid://9630017904",
        ["black_market_trader"] = "rbxassetid://9630017904",
        ["yeti"] = "rbxassetid://9166205917",
        ["scarab"] = "rbxassetid://137137517627492",
        ["defender"] = "rbxassetid://131690429591874",
        ["cactus"] = "rbxassetid://104436517801089",
        ["oasis"] = "rbxassetid://120283205213823",
        ["berserker"] = "rbxassetid://90258047545241",
        ["sword_shield"] = "rbxassetid://131690429591874",
        ["airbender"] = "rbxassetid://74712750354593",
        ["gun_blade"] = "rbxassetid://138231219644853",
        ["frost_hammer_kit"] = "rbxassetid://11838567073",
        ["spider_queen"] = "rbxassetid://95237509752482",
        ["archer"] = "rbxassetid://9224796984",
        ["axolotl"] = "rbxassetid://9155466713",
        ["baker"] = "rbxassetid://9155463919",
        ["barbarian"] = "rbxassetid://9166207628",
        ["builder"] = "rbxassetid://9155463708",
        ["necromancer"] = "rbxassetid://11343458097",
        ["cyber"] = "rbxassetid://9507126891",
        ["sorcerer"] = "rbxassetid://97940108361528",
        ["bigman"] = "rbxassetid://9155467211",
        ["spirit_assassin"] = "rbxassetid://10406002412",
        ["farmer_cletus"] = "rbxassetid://9155466936",
        ["ice_queen"] = "rbxassetid://9155466204",
        ["grim_reaper"] = "rbxassetid://9155467410",
        ["spirit_gardener"] = "rbxassetid://132108376114488",
        ["hannah"] = "rbxassetid://10726577232",
        ["shielder"] = "rbxassetid://9155464114",
        ["summoner"] = "rbxassetid://18922378956",
        ["glacial_skater"] = "rbxassetid://84628060516931",
        ["dragon_sword"] = "rbxassetid://16215630104",
        ["lumen"] = "rbxassetid://9630018371",
        ["flower_bee"] = "rbxassetid://101569742252812",
        ["jellyfish"] = "rbxassetid://18129974852",
        ["melody"] = "rbxassetid://9155464915",
        ["mimic"] = "rbxassetid://14783283296",
        ["miner"] = "rbxassetid://9166208461",
        ["nazar"] = "rbxassetid://18926951849",
        ["seahorse"] = "rbxassetid://11902552560",
        ["elk_master"] = "rbxassetid://15714972287",
        ["rebellion_leader"] = "rbxassetid://18926409564",
        ["void_hunter"] = "rbxassetid://122370766273698",
        ["taliyah"] = "rbxassetid://13989437601",
        ["angel"] = "rbxassetid://9166208240",
        ["harpoon"] = "rbxassetid://18250634847",
        ["void_walker"] = "rbxassetid://78915127961078",
        ["spirit_summoner"] = "rbxassetid://95760990786863",
        ["triple_shot"] = "rbxassetid://9166208149",
        ["void_knight"] = "rbxassetid://73636326782144",
        ["regent"] = "rbxassetid://9166208904",
        ["vulcan"] = "rbxassetid://9155465543",
        ["owl"] = "rbxassetid://12509401147",
        ["dasher"] = "rbxassetid://9155467645",
        ["disruptor"] = "rbxassetid://11596993583",
        ["wizard"] = "rbxassetid://13353923546",
        ["aery"] = "rbxassetid://9155463221",
        ["agni"] = "rbxassetid://17024640133",
        ["alchemist"] = "rbxassetid://9155462512",
        ["spearman"] = "rbxassetid://9166207341",
        ["beekeeper"] = "rbxassetid://9312831285",
        ["falconer"] = "rbxassetid://17022941869",
        ["bounty_hunter"] = "rbxassetid://9166208649",
        ["blood_assassin"] = "rbxassetid://12520290159",
        ["battery"] = "rbxassetid://10159166528",
        ["steam_engineer"] = "rbxassetid://15380413567",
        ["vesta"] = "rbxassetid://9568930198",
        ["beast"] = "rbxassetid://9155465124",
        ["dino_tamer"] = "rbxassetid://9872357009",
        ["drill"] = "rbxassetid://12955100280",
        ["elektra"] = "rbxassetid://13841413050",
        ["fisherman"] = "rbxassetid://9166208359",
        ["queen_bee"] = "rbxassetid://12671498918",
        ["card"] = "rbxassetid://13841410580",
        ["frosty"] = "rbxassetid://9166208762",
        ["gingerbread_man"] = "rbxassetid://9155464364",
        ["ghost_catcher"] = "rbxassetid://9224802656",
        ["tinker"] = "rbxassetid://17025762404",
        ["ignis"] = "rbxassetid://13835258938",
        ["oil_man"] = "rbxassetid://9166206259",
        ["jade"] = "rbxassetid://9166306816",
        ["dragon_slayer"] = "rbxassetid://10982192175",
        ["paladin"] = "rbxassetid://11202785737",
        ["pinata"] = "rbxassetid://10011261147",
        ["merchant"] = "rbxassetid://9872356790",
        ["metal_detector"] = "rbxassetid://9378298061",
        ["slime_tamer"] = "rbxassetid://15379766168",
        ["nyoka"] = "rbxassetid://17022941410",
        ["midnight"] = "rbxassetid://9155462763",
        ["pyro"] = "rbxassetid://9155464770",
        ["raven"] = "rbxassetid://9166206554",
        ["santa"] = "rbxassetid://9166206101",
        ["sheep_herder"] = "rbxassetid://9155465730",
        ["smoke"] = "rbxassetid://9155462247",
        ["spirit_catcher"] = "rbxassetid://9166207943",
        ["star_collector"] = "rbxassetid://9872356516",
        ["styx"] = "rbxassetid://17014536631",
        ["block_kicker"] = "rbxassetid://15382536098",
        ["trapper"] = "rbxassetid://9166206875",
        ["hatter"] = "rbxassetid://12509388633",
        ["ninja"] = "rbxassetid://15517037848",
        ["jailor"] = "rbxassetid://11664116980",
        ["warrior"] = "rbxassetid://9166207008",
        ["mage"] = "rbxassetid://10982191792",
        ["void_dragon"] = "rbxassetid://10982192753",
        ["cat"] = "rbxassetid://15350740470",
        ["wind_walker"] = "rbxassetid://9872355499",
		['skeleton'] = "rbxassetid://120123419412119",
		['winter_lady'] = "rbxassetid://83274578564074",
    }

    local function createkitrender(plr)
        local icon = Instance.new("ImageLabel")
        icon.Name = "ReVapeKitRender"
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(1.05, 0, 0.5, 0)
        icon.Size = UDim2.new(1.5, 0, 1.5, 0)
        icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
        icon.ImageTransparency = 0.4
        icon.ScaleType = Enum.ScaleType.Crop
        local uar = Instance.new("UIAspectRatioConstraint")
        uar.AspectRatio = 1
        uar.AspectType = Enum.AspectType.FitWithinMaxSize
        uar.DominantAxis = Enum.DominantAxis.Width
        uar.Parent = icon
        icon.Image = ids[plr:GetAttribute("PlayingAsKits")] or ids["none"]
        return icon
    end

    local function removeallkitrenders()
        for _, v in ipairs(PlayerGui:GetDescendants()) do
            if v:IsA("ImageLabel") and v.Name == "ReVapeKitRender" then
                v:Destroy()
            end
        end
    end

    local function refreshicon(icon, plr)
        icon.Image = ids[plr:GetAttribute("PlayingAsKits")] or ids["none"]
    end

    local function findPlayer(label, container)
        local render = container:FindFirstChild("PlayerRender", true)
        if render and render:IsA("ImageLabel") and render.Image then
            local userId = string.match(render.Image, "id=(%d+)")
            if userId then
                local plr = playersService:GetPlayerByUserId(tonumber(userId))
                if plr then return plr end
            end
        end
        local text = label.Text
        for _, plr in ipairs(playersService:GetPlayers()) do
            if plr.Name == text or plr.DisplayName == text or plr:GetAttribute("DisguiseDisplayName") == text then
                return plr
            end
        end
    end

    local function handleLabel(label)
        if not (label:IsA("TextLabel") and label.Name == "PlayerName") then return end
        task.spawn(function()
            local container = label.Parent
            for _ = 1, 3 do
                if container and container.Parent then
                    container = container.Parent
                end
            end
            if not container or not container:IsA("Frame") then return end
            local playerFound = findPlayer(label, container)
            if not playerFound then
                task.wait(0.5)
                playerFound = findPlayer(label, container)
            end
            if not playerFound then return end
            container.Name = playerFound.Name
            local card = container:FindFirstChild("1") and container["1"]:FindFirstChild("MatchDraftPlayerCard")
            if not card then return end
            local icon = card:FindFirstChild("ReVapeKitRender")
            if not icon then
                icon = createkitrender(playerFound)
                icon.Parent = card
            end
            task.spawn(function()
                while container and container.Parent do
                    local updatedPlayer = findPlayer(label, container)
                    if updatedPlayer and updatedPlayer ~= playerFound then
                        playerFound = updatedPlayer
                    end
                    if playerFound and icon then
                        refreshicon(icon, playerFound)
                    end
                    task.wait(1)
                end
            end)
        end)
    end

    KitRender = vape.Categories.Render:CreateModule({
        Name = "KitRender",
        Tooltip = "Allows you to see everyone's kit during kit phase (5v5, Ranked)",
        Function = function(callback)     
            if callback then
                task.spawn(function()
                    local team2 = PlayerGui:WaitForChild("MatchDraftApp"):WaitForChild("DraftAppBackground"):WaitForChild("BodyContainer"):WaitForChild("Team2Column")
                    for _, child in ipairs(team2:GetDescendants()) do
                        if KitRender.Enabled then handleLabel(child) end
                    end
                    KitRender:Clean(team2.DescendantAdded:Connect(function(child)
                        if KitRender.Enabled then handleLabel(child) end
                    end))
                end)
            else
                removeallkitrenders()
            end
        end
    })
end)
run(function()
    local aim = 0.158
    local tnt = 0.0045
    local aunchself = 0.395

    local defaultaim = 0.4
    local defaulttnt = 0.2
    local defaultself = 0.4

	local A
	local T
	local L
	local C
	local AJ
    local function getWorldFolder()
        local Map = workspace:WaitForChild("Map", math.huge)
        local Worlds = Map:WaitForChild("Worlds", math.huge)
        if not Worlds then return nil end

        return Worlds:GetChildren()[1] 
    end

    local function setCannonSpeeds(blocksFolder, aimDur, tntDur, selfDur)
        for _, v in ipairs(blocksFolder:GetChildren()) do 
            if v:IsA("BasePart") and v.Name == "cannon" then
                local AimPrompt = v:FindFirstChild("AimPrompt")
                local FirePrompt = v:FindFirstChild("FirePrompt")
                local LaunchSelfPrompt = v:FindFirstChild("LaunchSelfPrompt")
                if AimPrompt and FirePrompt and LaunchSelfPrompt then
                    AimPrompt.HoldDuration = aimDur
                    FirePrompt.HoldDuration = tntDur
                    LaunchSelfPrompt.HoldDuration = selfDur
                end
            end
        end
    end

    BetterDavey = vape.Categories.Legit:CreateModule({
        Name = "BetterDavey",
        Tooltip = "Makes davey easier depending on your settings",
        Function = function(callback) 
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")

            if callback then
                setCannonSpeeds(blocks, aim, tnt, aunchself)

               BetterDavey:Clean( blocks.ChildAdded:Connect(function(child)
                    if child:IsA("BasePart") and child.Name == "cannon" and BetterDavey.Enabled then
                        local AimPrompt = child:WaitForChild("AimPrompt")
                        local FirePrompt = child:WaitForChild("FirePrompt")
                        local LaunchSelfPrompt = child:WaitForChild("LaunchSelfPrompt")

                        AimPrompt.HoldDuration = aim
                        FirePrompt.HoldDuration = tnt
                        LaunchSelfPrompt.HoldDuration = aunchself
					BetterDavey:Clean(LaunchSelfPrompt.Triggered:Connect(function(p)
						local humanoid = entitylib.character.Humanoid
					
						if not humanoid then return end
					
						if Speed.Enabled and Fly.Enabled then
							Fly:Toggle(false)
							task.wait(0.025)
							Speed:Toggle(false)
						elseif Speed.Enabled then
							Speed:Toggle(false)
						elseif Fly.Enabled then
							Fly:Toggle(false)
						end

						bedwars.breakBlock(child)

						if AJ.Enabled then
							if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
								humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						end
					end))
                    end
                end))
            else
                setCannonSpeeds(blocks, defaultaim, defaulttnt, defaultself)
            end
        end
    })
	AJ = BetterDavey:CreateToggle({
		Name = "Auto-Jump",
		Default = true																																																						
	})																																																					
	A = BetterDavey:CreateSlider({
		Name = "Aim",
		Visible = false,
		Min = 0,
		Max = 1,
		Default = aim,
		Decimal = 10,
		Function = function(v)
			aim = v
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
            setCannonSpeeds(blocks, aim, tnt, aunchself)
		end
	})

	T = BetterDavey:CreateSlider({
		Name = "Tnt",
		Visible = false,
		Min = 0,
		Max = 1,
		Default = tnt,
		Decimal = 10,
		Function = function(v)
			tnt = v
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
            setCannonSpeeds(blocks, aim, tnt, aunchself)
		end
	})

	L = BetterDavey:CreateSlider({
		Name = "Launch Self",
		Visible = false,
		Min = 0,
		Max = 1,
		Default = aunchself,
		Decimal = 10,
		Function = function(v)
			aunchself = v
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")
            setCannonSpeeds(blocks, aim, tnt, aunchself)
		end
	})

	C = BetterDavey:CreateToggle({
		Name = "Customize",
		Default = false,
		Function = function(v)
			A.Object.Visible = v
			T.Object.Visible = v
			L.Object.Visible = v
			if not v then
				aim = 0.158
				tnt = 0.0045
				aunchself = 0.395
			end
		end
	})
end)
run(function()
    local HitFix
	local PingBased
	local Options
    HitFix = vape.Categories.Blatant:CreateModule({
        Name = 'HitFix',
        Function = function(callback)
            local function getPing()
                local stats = game:GetService("Stats")
                local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
                return tonumber(ping:match("%d+")) or 50
            end

            local function getDelay()
                local ping = getPing()

                if PingBased.Enabled then
                    if Options.Value == "Blatant" then
                        return math.clamp(0.08 + (ping / 1000), 0.08, 0.14)
                    else
                        return math.clamp(0.11 + (ping / 1200), 0.11, 0.15)
                    end
                end

                return Options.Value == "Blatant" and 0.1 or 0.13
            end

            if callback then
                pcall(function()
                    if bedwars.SwordController and bedwars.SwordController.swingSwordAtMouse then
                        local func = bedwars.SwordController.swingSwordAtMouse

                        if Options.Value == "Blatant" then
                            debug.setconstant(func, 23, "raycast")
                            debug.setupvalue(func, 4, bedwars.QueryUtil)
                        end

                        for i, v in ipairs(debug.getconstants(func)) do
                            if typeof(v) == "number" and (v == 0.15 or v == 0.1) then
                                debug.setconstant(func, i, getDelay())
                            end
                        end
                    end
                end)
            else
                pcall(function()
                    if bedwars.SwordController and bedwars.SwordController.swingSwordAtMouse then
                        local func = bedwars.SwordController.swingSwordAtMouse

                        debug.setconstant(func, 23, "Raycast")
                        debug.setupvalue(func, 4, workspace)

                        for i, v in ipairs(debug.getconstants(func)) do
                            if typeof(v) == "number" then
                                if v < 0.15 then
                                    debug.setconstant(func, i, 0.15)
                                end
                            end
                        end
                    end
                end)
            end
        end,
        Tooltip = 'Improves hit registration and decreases the chances of a ghost hit'
    })

    Options = HitFix:CreateDropdown({
        Name = "Mode",
        List = {"Blatant", "Legit"},
    })

    PingBased = HitFix:CreateToggle({
        Name = "Ping Based",
        Default = false,
    })
end)
run(function()
	local BCR
	local Value
	local old
	local inf = math.huge or 9e9
	BCR = vape.Categories.Blatant:CreateModule({
		Name = "BlockCPSRemover",
		Function = function(callback)
			if callback then
				old = bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS']
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = Value.Value == 0 and inf or Value.Value
			else
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = old
				old = nil
			end
		end,
	})
	Value = BCR:CreateSlider({
		Name = "CPS",
		Suffix = "s",
		Tooltip = "Changes the limit to the CPS cap(0 = remove)",
		Default = 0,
		Min = 0,
		Max = 100,
		Function = function()
			if BCR.Enabled then
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = Value.Value == 0 and inf or Value.Value
			else
				if old == nil then old = 12 end
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = old
				old = nil
			end
		end,
		
	})
end)
run(function()
	local Shaders
	local Lighting = lightingService
	local old = {
		Technology = nil,
		GlobalShadows = nil,
		SS = nil, -- HITLER,
		Bright = nil,
		EC = nil,
		EDS =  nil,
		CT = nil,
		ODA = nil,
		ESS = nil,
	}
	Shaders = vape.Legit:CreateModule({
		Name = "Shaders",
		Function = function(callback)
			if callback then
				pcall(function()
					local RS = replicatedStorage
					local folder = Instance.new("Folder")
					folder.Name = "LightingStuffThingys"
					folder.Parent = RS

					for _, v in ipairs(Lighting:GetChildren()) do
						v.Parent = folder
					end
				end)
				pcall(function()
					old.Technology = Lighting.Technology
					old.GlobalShadows = Lighting.GlobalShadows
					old.SS = Lighting.ShadowSoftness
					old.Bright = Lighting.Brightness
					old.EC = Lighting.ExposureCompensation
					old.EDS = Lighting.EnvironmentDiffuseScale
					old.ESS = Lighting.EnvironmentSpecularScale
					old.CT = Lighting.ClockTime
					old.ODA = Lighting.OutdoorAmbient
					Lighting.GlobalShadows = true
					Lighting.ShadowSoftness = 0.7
					Lighting.Brightness = 1.5
					Lighting.ExposureCompensation = -0.15
					Lighting.EnvironmentDiffuseScale = 0.6
					Lighting.EnvironmentSpecularScale = 0.4
					Lighting.ClockTime = 14
					Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
					Lighting.Technology = Enum.Technology.Future
				end)

				local Bloom = Instance.new("BloomEffect")
				Bloom.Intensity = 0.45
				Bloom.Size = 32
				Bloom.Threshold = 0.9
				Bloom.Parent = Lighting

				local Color = Instance.new("ColorCorrectionEffect")
				Color.Brightness = 0.05
				Color.Contrast = -0.05
				Color.Saturation = 0.12
				Color.TintColor = Color3.fromRGB(255, 242, 230)
				Color.Parent = Lighting

				local DoF = Instance.new("DepthOfFieldEffect")
				DoF.FarIntensity = 0.15
				DoF.NearIntensity = 0
				DoF.FocusDistance = 60
				DoF.InFocusRadius = 50
				DoF.Parent = Lighting

				local Blur = Instance.new("BlurEffect")
				Blur.Size = 2
				Blur.Parent = Lighting

				local Atmosphere = Instance.new("Atmosphere")
				Atmosphere.Density = 0.35
				Atmosphere.Offset = 0.25
				Atmosphere.Glare = 0
				Atmosphere.Haze = 1.2
				Atmosphere.Color = Color3.fromRGB(245, 235, 225)
				Atmosphere.Parent = Lighting
			else
				pcall(function()
					for _, v in ipairs(lightingService:GetChildren()) do
						if v then
							v:Destroy()
						end
					end
					task.wait(0.025)
					local RS = replicatedStorage
					local folder = RS:FindFirstChild("LightingStuffThingys")
					if not folder then return end
					local children = folder:GetChildren()

					for _, v in ipairs(children) do
						v.Parent = Lighting
					end

					folder:Destroy()
				end)
				pcall(function()
					Lighting.Technology = old.Technology
					Lighting.GlobalShadows = old.GlobalShadows
					Lighting.ShadowSoftness = old.SS
					Lighting.Brightness = old.Bright
					Lighting.ExposureCompensation = old.EC
					Lighting.EnvironmentDiffuseScale = old.EDS
					Lighting.EnvironmentSpecularScale = old.ESS
					Lighting.ClockTime = old.CT
					Lighting.OutdoorAmbient = old.ODA
					task.wait(.025)
					old.Technology = nil
					old.GlobalShadows = nil
					old.SS = nil
					old.Bright = nil
					old.EC = nil
					old.EDS = nil
					old.ESS = nil
					old.CT = nil
					old.ODA = nil
				end)
			end
		end
	})
end)
run(function()
	local MouseTP
	local mode
	local pos
	local function getNearestPlayer()
		local character = lplr.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local nearestPlayer = nil
		local shortestDistance = math.huge or (2^1024-1)
		local myPos = hrp.Position

		for _, player in ipairs(playersService:GetPlayers()) do
			if player ~= lplr then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				if root and hum and hum.Health > 0 then
					local dist = (root.Position - myPos).Magnitude
					if dist < shortestDistance then
						nearestPlayer = player
					end
				end
			end
		end

		return nearestPlayer
	end
	local function Elektra(type)
		if type == "Mouse" then
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			local ray = cloneref(lplr:GetMouse()).UnitRay
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
			if not position then
				notif('MouseTP', 'No position found.', 5)
				MouseTP:Toggle(false)
				return
			end
			
			if bedwars.AbilityController:canUseAbility('ELECTRIC_DASH') then
				local info = TweenInfo.new(0.72,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
				local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)})
				tween:Play()
				task.wait(0.69)
				bedwars.AbilityController:useAbility('ELECTRIC_DASH')
				MouseTP:Toggle(false)
			end
		else
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				if not position then
					notif('MouseTP', 'No position found.', 5)
					MouseTP:Toggle(false)
					return
				end
				
				if bedwars.AbilityController:canUseAbility('ELECTRIC_DASH') then
					local info = TweenInfo.new(0.72,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
					local tween = tweenService:Create(entitylib.character.RootPart,info,{CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)})
					tween:Play()
					task.wait(0.69)
					bedwars.AbilityController:useAbility('ELECTRIC_DASH')
					MouseTP:Toggle(false)
				end
			end
		end
	end
	
	local function Davey(type)
		if type == "Mouse" then
			local Cannon = getItem("cannon")
			local ray = cloneref(lplr:GetMouse()).UnitRay
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)

			if not position then
				notif('MouseTP', 'No position found.', 5,"warning")
				MouseTP:Toggle(false)
				return
			end

				
			if not Cannon then
				notif('MouseTP', 'No cannon found.', 5,"warning")
				MouseTP:Toggle(false)
				return
			end

			if not entitylib.isAlive then
				notif('MouseTP', 'Cannot locate where i am at?', 5,"warning")
				MouseTP:Toggle(false)
				return
			end
			local pos = entitylib.character.RootPart.Position
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			bedwars.placeBlock(rounded, 'cannon', false)
			local block, blockpos = getPlacedBlock(rounded)
			if block then
				if block.Name == "cannon" then
					if (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
						bedwars.Client:Get(remotes.CannonAim):SendToServer({
							cannonBlockPos = blockpos,
							lookVector = position
						})
						local broken = 0.1
						if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
							broken = 0.4
							bedwars.breakBlock(block, true, true)
						end
			
						task.delay(broken, function()
							for _ = 1, 3 do
								local call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos})
								if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
								if call then
									bedwars.breakBlock(block, true, true)
									break
								end
								task.wait(0.1)
							end
						end)
						MouseTP:Toggle(false)
					end
				end
			end
		else
			local Cannon = getItem("cannon")
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				local old = nil
				if not position then
					notif('MouseTP', 'No position found.', 5)
					MouseTP:Toggle(false)
					return
				end
				if not Cannon then
					notif('MouseTP', 'No cannon found.', 5,"warning")
					MouseTP:Toggle(false)
					return
				end

				if not entitylib.isAlive then
					notif('MouseTP', 'Cannot locate where i am at?', 5,"warning")
					MouseTP:Toggle(false)
					return
				end
				local pos = entitylib.character.RootPart.Position
				pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
				local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
				bedwars.placeBlock(rounded, 'cannon', false)
				local block, blockpos = getPlacedBlock(rounded)
				if block then
					if block.Name == "cannon" then
						if (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
							bedwars.Client:Get(remotes.CannonAim):SendToServer({
								cannonBlockPos = blockpos,
								lookVector = position
							})
							local broken = 0.1
							if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
								broken = 0.4
								bedwars.breakBlock(block, true, true)
							end
				
							task.delay(broken, function()
								for _ = 1, 3 do
									local call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos})
									if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
										humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
									end
									if call then
										bedwars.breakBlock(block, true, true)
										break
									end
									task.wait(0.1)
								end
							end)
							MouseTP:Toggle(false)
						end
					end
				end
			end
		end
	end

	local function Yuzi(type)
		if type == "Mouse" then
			local old = nil
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			local ray = cloneref(lplr:GetMouse()).UnitRay
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
			if not position then
				notif('MouseTP', 'No position found.', 5)
				MouseTP:Toggle(false)
				return
			end
			
			if bedwars.AbilityController:canUseAbility('dash') then
				old = bedwars.YuziController.dashForward
				bedwars.YuziController.dashForward = function(v1,v2)
					local arg = nil
					if v1 then
						arg = v1
					else
						arg = v2
					end
					if entitylib.isAlive then
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position,entitylib.character.RootPart.Position + arg * Vector3.new(1, 0, 1))
						entitylib.character.Humanoid.JumpHeight = 0.5
						entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						entitylib.character.RootPart:ApplyImpulse(CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector))
						bedwars.JumpHeightController:setJumpHeight(cloneref(game:GetService("StarterPlayer")).CharacterJumpHeight)
						bedwars.SoundManager:playSound(bedwars.SoundList.DAO_SLASH)
						local any_playAnimation_result1 = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.DAO_DASH)
						if any_playAnimation_result1 ~= nil then
							any_playAnimation_result1:AdjustSpeed(2.5)
						end
					end
				end
				bedwars.AbilityController:useAbility('dash',nil,{
					direction = gameCamera.CFrame.LookVector,
					origin = entitylib.character.RootPart.Position,
					weapon = store.hand.tool.Name.itemType,
				})
				task.wait(0.15)
				bedwars.YuziController.dashForward = old
				old = nil
				MouseTP:Toggle(false)
			end
		else
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				local old = nil
				if not position then
					notif('MouseTP', 'No position found.', 5)
					MouseTP:Toggle(false)
					return
				end
				
				if bedwars.AbilityController:canUseAbility('dash') then
					old = bedwars.YuziController.dashForward
					bedwars.YuziController.dashForward = function(v1,v2)
						local arg = nil
						if v1 then
							arg = v1
						else
							arg = v2
						end
						if entitylib.isAlive then
							entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position,entitylib.character.RootPart.Position + arg * Vector3.new(1, 0, 1))
							entitylib.character.Humanoid.JumpHeight = 0.5
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							entitylib.character.RootPart:ApplyImpulse(CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector))
							bedwars.JumpHeightController:setJumpHeight(cloneref(game:GetService("StarterPlayer")).CharacterJumpHeight)
							bedwars.SoundManager:playSound(bedwars.SoundList.DAO_SLASH)
							local any_playAnimation_result1 = bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.DAO_DASH)
							if any_playAnimation_result1 ~= nil then
								any_playAnimation_result1:AdjustSpeed(2.5)
							end
						end
					end
					bedwars.AbilityController:useAbility('dash',nil,{
						direction = gameCamera.CFrame.LookVector,
						origin = entitylib.character.RootPart.Position,
						weapon = store.hand.tool.Name.itemType,
					})
					task.wait(0.15)
					bedwars.YuziController.dashForward = old
					old = nil
					MouseTP:Toggle(false)
				end
			end
		end
	end

	local function Zar(type)
		notif('MouseTP', 'Comming soon!', 8,'warning')
		MouseTP:Toggle(false)
		return
	end

	local function Mouse(type)
		if type == "Mouse" then
			local position
			local rayCheck = RaycastParams.new()
			rayCheck.RespectCanCollide = true
			local ray = cloneref(lplr:GetMouse()).UnitRay
			rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			ray = workspace:Raycast(ray.Origin, ray.Direction * 10000, rayCheck)
			position = ray and ray.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
			entitylib.character.RootPart.CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)
		
			if not position then
				notif('MouseTP', 'No position found.', 5)
				MouseTP:Toggle(false)
				return
			end
		else
			local FoundedPLR = getNearestPlayer()
			if FoundedPLR then
				local position = FoundedPLR.Character.HumanoidRootPart.Position + Vector3.new(0, entitylib.character.HipHeight or 2, 0)
				entitylib.character.RootPart.CFrame = CFrame.lookAlong(position, entitylib.character.RootPart.CFrame.LookVector)
				if not position then
					notif('MouseTP', 'No player found.', 5)
					MouseTP:Toggle(false)
					return
				end
			end
		end
		MouseTP:Toggle(false)
	end

	MouseTP = vape.Categories.Utility:CreateModule({
		Name = 'MouseTP',
		Function = function(callback)
			if not callback then return end
			if callback then
				if mode.Value == "Mouse" then
					Mouse(pos.Value)
				elseif mode.Value == "Kits" then
					if store.equippedKit == "elektra" then
						Elektra(pos.Value)
					elseif store.equippedKit == "davey" then
						Davey(pos.Value)
					elseif store.equippedKit == "dasher" then
						Yuzi(pos.Value)
					elseif store.equippedKit == "gun_blade" then
						Zar(pos.Value)
					else
						vape:CreateNotification("MouseTP", "Current kit is not supported for MouseTP", 4.5, "warning")
						MouseTP:Toggle(false)
						return
					end
				else
					Mouse()
				end
			end
		end,
	})
	mode = MouseTP:CreateDropdown({
		Name = "Mode",
		List = {'Mouse','Kits'}
	})
	pos =  MouseTP:CreateDropdown({
		Name = "Position",
		List = {'Cloeset Player', 'Mouse'}
	})
end)
run(function() 
	local AutoBan
	local Mode
	local Delay

	local function AltFarmBAN(cb,delay)
		while cb do
			local kits = {"berserker", "hatter", "flower_bee", "glacial_skater",'void_dragon','card','cat'}
			for _, kit in ipairs(kits) do
				for i = 0, 1 do
					local args = {kit, i}
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BanKit"):InvokeServer(unpack(args))		
				end
			end
			for i = 0, 1 do
				local args = {"none", i}
				game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("SelectKit"):InvokeServer(unpack(args))		
			end
			task.wait(delay)
		end
	end

	local function SmartBAN(cb,delay)
		local kits = {'metal_detector','berserker','regent','cowgirl','wizard','summoner','pinata','davey','fisherman','gingerbread_man','airbender','ninja','star_collector','winter_lady','blood_assassin','owl','elk_master','seahorse','shielder','bigman','archer','black_market_trader'}
		while cb do
			for _, kit in ipairs(kits) do
				for i = 0, 1 do
					local args = {kit, i}
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BanKit"):InvokeServer(unpack(args))		
				end
			end
			task.wait(delay)
		end
	end


	local function NormalBAN(cb,delay)
		local kits = {'metal_detector','cowgirl','wizard','summoner','airbender','ninja','star_collector','blood_assassin','seahorse','agni','dasher','elektra','davey','black_market_trader'}
		while cb do
			for _, kit in ipairs(kits) do
				for i = 0, 1 do
					local args = {kit, i}
					game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("BanKit"):InvokeServer(unpack(args))		
				end
			end
			task.wait(delay)
		end
	end

	local function MainBranch(callback,type,delay)
		if type == "Alt Farm" then
			AltFarmBAN(callback,0.1)
		elseif type == "Smart" then
			SmartBAN(callback,delay)
		elseif type == "Normal" then
			NormalBAN(callback,delay)
		else
			AltFarmBAN(callback,0.1)
		end
	end

	AutoBan = vape.Categories.Legit:CreateModule({
		Name = "AutoBan",
		Tooltip = 'Automatically bans a kit for you(5v5, ranked only)',
		Function = function(callback) 
			MainBranch(callback, Mode.Value,(Delay.Value / 1000))
		end,
	})
	Mode = AutoBan:CreateDropdown({
		Name = "Mode",
		Tooltip = "Alt Farm=AutoBans And Auto Selects ur kit used for alt farming insta bans and selection\nSmart=Selects a good/op kit depending on the match\nNormal=Selects basic/good kits for the match",
		List = {"Alt Farm","Smart","Normal"},
		Function = function()
			if Mode.Value == "Smart" or Mode.Value == "Normal" then
				Delay.Object.Visible = true
			else
				Delay.Object.Visible = false
			end
		end
	})
	Delay = AutoBan:CreateSlider({
		Name = "Delay",
		Visible = false,
		Min = 1,
		Max = 1000,
		Suffix = "ms",
	})
end)
run(function()
	local AutoQueue
	local Bypass
	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
			if callback then
				if Bypass.Enabled then
					bedwars.Client:Get('AfkInfo'):SendToServer({afk = false})
					task.wait(0.025)
					AutoQueue:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
							bedwars.Client:Get('AfkInfo'):SendToServer({afk = false})
							joinQueue()
						end
					end))
					AutoQueue:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(...)
						bedwars.Client:Get('AfkInfo'):SendToServer({afk = false})
						joinQueue()
					end))
				else
					AutoQueue:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
							joinQueue()
						end
					end))
					AutoQueue:Clean(vapeEvents.MatchEndEvent.Event:Connect(joinQueue))
				end
			end
		end,
		Tooltip = 'Automatically queues for the next match'
	})
	Bypass = AutoQueue:CreateToggle({
		Name = "Bypass",
		Default = true
	})
end)
run(function()
	local SetFPS
	local FPS
	
	SetFPS = vape.Categories.Utility:CreateModule({
		Name = "FPS",
		Function = function(callback)
			if callback then
				setfpscap(FPS.Value)
			else
				setfpscap(240)
			end
		end,
		Tooltip = "Removes or customizes the Frame-Per-Second limit",
	})
	
	FPS = SetFPS:CreateSlider({
		Name = "Frames Per Second",
		Min = 0,
		Max = 420,
		Default = 240,
		Function = function(value)
			setfpscap(value)
		end
	})
end)
run(function()
	local LP 
	 LP = vape.Categories.Exploits:CreateModule({
		Name = "LeaveParty",
		Function = function(callback)																									
			if callback then
				LP:Toggle(false)
				bedwars.PartyController:leaveParty()
			end
		end,
		Tooltip = "Makes u leave ur current party",
	})
end)
run(function()
	local Desync
	local New
	Desync = vape.Categories.World:CreateModule({
		Name = 'Desync',
		Function = function(callback)
			local function cb1()

				if not setfflag then vape:CreateNotification("ZEN", "Your current executor '"..identifyexecutor().."' does not support setfflag", 6, "warning"); return end     
				if New.Enabled then
					repeat
						setfflag('DFIntDebugDefaultTargetWorldStepsPerFrame', '-2147483648')
						setfflag('DFIntMaxMissedWorldStepsRemembered', '-2147483648')
						setfflag('DFIntWorldStepsOffsetAdjustRate', '2147483648')
						setfflag('DFIntDebugSendDistInSteps', '-2147483648')
						setfflag('DFIntWorldStepMax', '-2147483648')
						setfflag('DFIntWarpFactor', '2147483648')
						task.wait()
					until not Desync.Enabled
				else
					if callback then
						setfflag('NextGenReplicatorEnabledWrite4', 'true')
					else
						setfflag('NextGenReplicatorEnabledWrite4', 'false')
					end
				end

			end
			local function cb2()
				vape:CreateNotification("Desync","Disabled...",8,'warning')
			end
			vape:CreatePoll("Desync","Are you sure you want to use this?",8,"warning",cb1,cb2)
		end,
		Tooltip = 'Desync will ban you for client modifications.'
	})
	New = Desync:CreateToggle({Name="New",Tooltip='this uses the new method(u can hit people)',Default=false})
end)

run(function()
    local Antihit = {Enabled = false}
    local Range, TimeUp, Down = 16, 0.2,0.05

    Antihit = vape.Categories.Blatant:CreateModule({
        Name = "AntiHit",
        Function = function(call)
            if call then
                task.spawn(function()
                    while Antihit.Enabled do
                        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local orgPos = root.Position
                            local foundEnemy = false

                            for _, v in next, playersService:GetPlayers() do
                                if v ~= lplr and v.Team ~= lplr.Team then
                                    local enemyChar = v.Character
                                    local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
                                    local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
                                    if enemyRoot and enemyHum and enemyHum.Health > 0 then
                                        local dist = (root.Position - enemyRoot.Position).Magnitude
                                        if dist <= Range.Value then
                                            foundEnemy = true
                                            break
                                        end
                                    end
                                end
                            end

                            if foundEnemy then
                                root.CFrame = CFrame.new(orgPos + Vector3.new(0, -230, 0))
                                task.wait(TimeUp.Value)
                                if Antihit.Enabled and lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") then
                                    lplr.Character.HumanoidRootPart.CFrame = CFrame.new(orgPos)
                                end
                            end
                        end
                        task.wait(Down.Value)
                    end
                end)
            end
        end,
        Tooltip = "Prevents you from dying"
    })

    Range = Antihit:CreateSlider({
        Name = "Range",
        Min = 0,
        Max = 50,
        Default = 15,
        Function = function(val) Range.Value = val end
    })

    TimeUp = Antihit:CreateSlider({
        Name = "Time Up",
        Min = 0,
        Max = 1,
        Default = 0.2,
        Function = function(val) TimeUp.Value = val end
    })

    Down = Antihit:CreateSlider({
        Name = "Time Down",
        Min = 0,
        Max = 1,
        Default = 0.05,
        Function = function(val) Down.Value = val end
    })
end)

run(function()
    local BlockIn
    local PD
    local UseBlacklisted_Blocks
    local blacklisted
	local SlientAim
	local LimitedToItem

    local function getBlocks()
        local blocks = {}

        for _, item in store.inventory.inventory.items do
            local block = bedwars.ItemMeta[item.itemType].block
			print(block)
            if block then
                table.insert(blocks, { item.itemType, block.health })
            end
        end

        table.sort(blocks, function(a, b)
            return a[2] < b[2]
        end)

        return blocks
    end

    local function getPyramid(size, grid)
        return {
            Vector3.new(3, 0, 0),
            Vector3.new(0, 0, 3),
            Vector3.new(-3, 0, 0),
            Vector3.new(0, 0, -3),
            Vector3.new(3, 3, 0),
            Vector3.new(0, 3, 3),
            Vector3.new(-3, 3, 0),
            Vector3.new(0, 3, -3),
            Vector3.new(0, 6, 0),
            Vector3.new(0, -2.8, 0),
        }
    end

    BlockIn = vape.Categories.Blatant:CreateModule({
        Name = "BlockIn",
        Tooltip = "Automatically places strong blocks around the me.",
        Function = function(callback)
			local number = 0
            if not callback then 
                return 
            end

            local me = entitylib.isAlive and entitylib.character.RootPart.Position or nil
            if not me then
                notif("BlockIn", "Unable to locate me", 5, "warning")
                BlockIn:Toggle(false)
                return
            end

            local item = getBlocks()
            if not item or #item == 0 then
                notif("BlockIn", "No blocks found in inventory!", 5, "warning")
                BlockIn:Toggle(false)
                return
            end
			for i, block in ipairs(item) do
			    for _, pos in ipairs(getPyramid(i, 3)) do
			        if not BlockIn.Enabled then 
			            break 
			        end
			
			        local targetPos = me + pos
			        if getPlacedBlock(targetPos) then 
			            continue 
			        end
					task.spawn(function()
						for i=0,8 do
					    	number = i
							task.wait(PD.Value / 100)																													
						end
					end)
					local woolitem,amount = getWool()
					switchItem(woolitem)
					repeat
    					task.spawn(bedwars.placeBlock, targetPos, block[1])
   						task.wait(PD.Value / 100)
    				until number == 8
			    end
			end
			
			if BlockIn.Enabled then
			    BlockIn:Toggle(false)
			end
        end
    })

	LimitedToItem = BlockIn:CreateToggle({
		Name = "Limited To Item",
		Default = false
	})

	SlientAim = BlockIn:CreateToggle({
		Name = "SlientAim",
		Default = false
	})

    PD = BlockIn:CreateSlider({
        Name = "Place Delay",
        Min = 0,
        Max = 5,
        Default = 3,
        Suffix = "ms"
    })

	UseBlacklisted_Blocks = BlockIn:CreateToggle({
		Name = "Use Blacklisted Blocks",
		Default = false
	})

	blacklisted = BlockIn:CreateTextList({
		Name = "Blacklisted Blocks",
		Placeholder = "tnt"
	})
end)

run(function()
    local DamageAffect = {Enabled = false}
    local connection
	local Fonts
	local customMSG
	local DamageMessages = {
		'Pow!',
		'Pop!',
		'Hit!',
		'Smack!',
		'Bang!',
		'Boom!',
		'Whoop!',
		'Damage!',
		'-9e9!',
		'Whack!',
		'Crash!',
		'Slam!',
		'Zap!',
		'Snap!',
		'Thump!',
		'Ouch!',
		'Crack!',
		'Bam!',
		'Clap!',
		'Blitz!',
		'Crunch!',
		'Shatter!',
		'Blast!',
		'Womp!',
		'Thunk!',
		'Zing!',
		'Rip!',
		'Rattle!',
		'Kaboom!',
		'Wack!',
		'Boomer!',
		'Slammer!',
		'Powee!',
		'Zappp!',
		'Thunker!',
		'Rippler!',
		'Bap!',
		'Bomp!',
		'Sock!',
		'Chop!',
		'Sting!',
		'Slice!',
		'Swipe!',
		'Punch!',
		'Tonk!',
		'Bonk!',
		'Jolt!',
		'Spike!',
		'Pierce!',
		'Crush!',
		'Bruise!',
		'Ding!',
	    'Clang!',
		'Crashhh!',
		'Kablam!',
		'Zapshot!',
		'Zen On top!'
	}
	
	local RGBColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(255, 127, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(75, 0, 130),
		Color3.fromRGB(148, 0, 211)
	}
	
	local function randomizer(tbl)
	    if not typeof(tbl) == "table" then return end
	    local index = math.random(1,#tbl)
	    local value = tbl[index]
	    return value,index
	end
	local font  = 'Arial'
    DamageAffect = vape.Categories.Render:CreateModule({
        Name = "DamageAffects",
        Function = function(call)
			if call then
				DamageAffect:Clean(workspace.DescendantAdded:Connect(function(part)
				    if part.Name == "DamageIndicatorPart" and part:IsA("BasePart") then
				        for i, v in part:GetDescendants() do
				            if v:IsA("TextLabel") then
				                local txt = randomizer(DamageMessages)
				                local clr = randomizer(RGBColors)
								if customMSG.Enabled then
				                	v.Text = txt
								end
				                v.TextColor3 = clr
								v.FontFace = font
				            end
				        end
				    end
				end))
			else

			end
        end,
        Tooltip = "Customizes Damage Affects (CLIENT ONLY)"
    })
	customMSG = DamageAffect:CreateToggle({
		Name = "Custom Messages",
		Default = true
	})
	Fonts = DamageAffect:CreateFont({
		Name = 'Font',
		Function = function(val)
			font = val
		end
	})
end)

run(function()
    local AutoChargeBow = {Enabled = false}
    local old
    
    AutoChargeBow = vape.Categories.Blatant:CreateModule({
        Name = 'AutoChargeBow',
        Function = function(callback)
            if callback then
                old = bedwars.ProjectileController.calculateImportantLaunchValues
                bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
                    local self, projmeta, worldmeta, origin, shootpos = ...
                    
                    if projmeta.projectile:find('arrow') then
                        local pos = shootpos or self:getLaunchPosition(origin)
                        if not pos then
                            return old(...)
                        end
                        
                        local meta = projmeta:getProjectileMeta()
                        local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
                        local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
                        local projSpeed = (meta.launchVelocity or 100)
                        local offsetpos = pos + (projmeta.projectile == 'owl_projectile' and Vector3.zero or projmeta.fromPositionOffset)
                        
                        local camera = workspace.CurrentCamera
                        local mouse = lplr:GetMouse()
                        local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
                        
                        local targetPoint = unitRay.Origin + (unitRay.Direction * 1000)
                        local aimDirection = (targetPoint - offsetpos).Unit
                        
                        local newlook = CFrame.new(offsetpos, targetPoint) * CFrame.new(projmeta.projectile == 'owl_projectile' and Vector3.zero or Vector3.new(bedwars.BowConstantsTable.RelX, bedwars.BowConstantsTable.RelY, bedwars.BowConstantsTable.RelZ))
                        local finalDirection = (targetPoint - newlook.Position).Unit
                        
                        return {
                            initialVelocity = finalDirection * projSpeed,
                            positionFrom = offsetpos,
                            deltaT = lifetime,
                            gravitationalAcceleration = gravity,
                            drawDurationSeconds = 5
                        }
                    end
                    
                    return old(...)
                end
            else
                bedwars.ProjectileController.calculateImportantLaunchValues = old
				old = nil
            end
        end,
        Tooltip = 'Automatically charges your bow to full power'
    })
end)

run(function()
	local FlyY 
	local Fly
	local Heal
	local HealthHP
	local isWhispering
	local BetterWhisper
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

    BetterWhisper = vape.Categories.Legit:CreateModule({
        Name = 'AutoWhisper',
        Function = function(callback)
            if callback then
			if store.equippedKit ~= "owl" then
				vape:CreateNotification("BetterWhisper","Kit required only!",8,"warning")
				return
			end
				BetterWhisper:Clean(bedwars.Client:Get("OwlSummoned"):Connect(function(data)
					if data.user == lplr then
						local target = data.target
						local chr = target.Character
						local hum = chr:FindFirstChild('Humanoid')
						local root = chr:FindFirstChild('HumanoidRootPart')
						isWhispering = true
						repeat
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiVoidPart}
							rayCheck.CollisionGroup = root.CollisionGroup

							if Fly.Enabled and root.Velocity.Y <= FlyY.Value and not workspace:Raycast(root.Position, Vector3.new(0, -100, 0), rayCheck) then
								WhisperController:request("Fly")
							end
							if Heal.Enabled and (hum.MaxHealth - hum.Health) >= HealthHP.Value then
								WhisperController:request("Heal")
							end
							task.wait(0.05)
						until not isWhispering or not BetterWhisper.Enabled
					end
				end))
				BetterWhisper:Clean(bedwars.Client:Get("OwlDeattached"):Connect(function(data)
					if data.user == lplr then
						isWhispering = false
					end
				end))
			else
				isWhispering = false
			end
        end,
        Tooltip = "Better whisper skills and u look like u play like therac!"
    })
	FlyY = BetterWhisper:CreateSlider({
		Name = 'Y-Level fly',																																																																							
		Min = -50,
		Max = -100,
		Default = -90,
	})	
	HealthHP = BetterWhisper:CreateSlider({
		Name = 'Heal HP',																																																																							
		Min = 1,
		Max = 99,
		Default = 80,
	})	
	Fly = BetterWhisper:CreateToggle({
		Name = 'Fly',
		Default = true,
	})
	Heal = BetterWhisper:CreateToggle({
		Name = 'Heal',
		Default = true,
	})
end)

run(function()
		local char = lplr.Character or lplr.CharacterAdded:Wait()
		local teamID = char:GetAttribute("Team")
		local Distance = 15
		local db = true
		local ABDU
		local Upgrade
		local REMOTE = ""
		local tbllist = {
		    ["bed alarm"] = "bed_alarm",
		    ["bedalarm"] = "bed_alarm",
		    ["alarm"] = "bed_alarm",
		
		    ["bed shield"] = "bed_shield",
		    ["bedshield"] = "bed_shield",
		    ["shield"] = "bed_shield",
	
		    ["team"] = "TEAM_GENERATOR",
		    ["gen"] = "TEAM_GENERATOR",
		    ["team generator"] = "TEAM_GENERATOR",
		    ["team gen"] = "TEAM_GENERATOR",
		    ["teamgenerator"] = "TEAM_GENERATOR",
		    ["teamgen"] = "TEAM_GENERATOR",
		
		    ["diamond"] = "DIAMOND_GENERATOR",
		    ["diamond generator"] = "DIAMOND_GENERATOR",
		    ["diamond gen"] = "DIAMOND_GENERATOR",
		    ["diamondgen"] = "DIAMOND_GENERATOR",
		    ["diamondgenerator"] = "DIAMOND_GENERATOR",
		
		    ["dim"] = "DIAMOND_GENERATOR",
		    ["dim generator"] = "DIAMOND_GENERATOR",
		    ["dim gen"] = "DIAMOND_GENERATOR",
		    ["dimgenerator"] = "DIAMOND_GENERATOR",
		    ["dimgen"] = "DIAMOND_GENERATOR",
		
		    ["armor"] = "ARMOR",
		    ["arm"] = "ARMOR",
		
		    ["damage"] = "DAMAGE",
		    ["dmg"] = "DAMAGE",
	}
	local upgradePrices = {
	    bed_alarm = 2,
	    bed_shield = 5,
	
	    TEAM_GENERATOR = {4, 8, 16},
	    DIAMOND_GENERATOR = {4, 8, 12},
	
	    ARMOR = {4, 8, 18},
	    DAMAGE = {5, 10, 20},
	}

	local function getPrice(upgradeName, currentTier)
	    local prices = upgradePrices[upgradeName]
	    if not prices then return nil end
	
	    return prices[currentTier]  
	end
	local function purchase(upgrade)
	    local grade = string.lower(upgrade)
	    local mapped = tbllist[grade]
	
	    if not mapped then
	        getgenv().BEN("Invalid upgrade:", upgrade)
	        return
	    end
	
	    local function buyBed(price)
	        local item, amount = getItem("diamond")
	        if not (item and amount) then return end
	
	        if amount >= price then
	            game:GetService("ReplicatedStorage")
	                .rbxts_include.node_modules["@rbxts"].net.out._NetManaged
	                .RequestPurchaseBedTeamUpgrade:InvokeServer(mapped)
	            ABDU:Toggle(false)
	        else
	            getgenv().BEN("You do not have enough to autopurchase")
	        end
	    end
	
	    if mapped == "bed_alarm" then
	        buyBed(2)
	        return
	    end
	    if mapped == "bed_shield" then
	        buyBed(5)
	        return
	    end
	
	    local tier = 1
	
	    while true do
	        local price = getPrice(mapped, tier)
	        if not price then break end 
	
	        local item, amount = getItem("diamond")
	        if not (item and amount) then break end
	
	        if amount < price then
	            getgenv().BEN("Stopped: not enough for tier or max tier: "..tier)
	            break
	        end
	
	        game:GetService("ReplicatedStorage")
	            .rbxts_include.node_modules["@rbxts"].net.out._NetManaged
	            .RequestPurchaseTeamUpgrade:InvokeServer(mapped)
		
	        tier += 1
	    end
	end


	    ABDU = vape.Categories.Inventory:CreateModule({
	        Name = "AutoBuyUpgrades",
	        Function = function(callback)																																																																										
	            if callback then
	    			db = true

					while task.wait(0.5) do
					    for i, v in workspace:GetChildren() do
					        if v:IsA("BasePart") then
					            if v.Name == "1_upgrade_shop" then
					                if v:GetAttribute("GeneratorTeam") == teamID then
					                    local NewDis = (v.florist.PrimaryPart.Position - char.HumanoidRootPart.Position).Magnitude
					                    if NewDis <= Distance then
						                	purchase(Upgrade.Value)
					                    else
					                        
					                    end
					                else
					                    getgenv().BEN("Cannot locate where ur upgrade shop is at")
										db = false
										ABDU:Toggle(false)
					                end
					            end
					        end
					    end

						if not db then break end
					end
				else
					db = false
	            end
	        end,
	        Tooltip = "Automatically buys upgrades when you go near the upgrade shop",
	    })
		Upgrade = ABDU:CreateTextBox({
			Name = 'Upgrade',
			Placeholder = 'Generator/Damage/Armor/BedShield/BedAlarm/Etc',
			Darker = true,
		})																																									
end)

run(function()
	local FlySpeed
	local VerticalSpeed
	local SafeMode
	local rayCheck = RaycastParams.new()
	local oldroot
	local clone
	local FlyLandTick = tick()
	local performanceStats = game:GetService('Stats'):FindFirstChild('PerformanceStats')
	local hip = 2.6

	local function createClone()
		if entitylib.isAlive and entitylib.character.Humanoid.Health > 0 and (not oldroot or not oldroot.Parent) then
			hip = entitylib.character.Humanoid.HipHeight
			oldroot = entitylib.character.HumanoidRootPart
			if not lplr.Character.Parent then return false end
			lplr.Character.Parent = game
			clone = oldroot:Clone()
			clone.Parent = lplr.Character
			--oldroot.CanCollide = false
			oldroot.Transparency = 0
			Instance.new('Highlight', oldroot)
			oldroot.Parent = gameCamera
			store.rootpart = clone
			bedwars.QueryUtil:setQueryIgnored(oldroot, true)
			lplr.Character.PrimaryPart = clone
			lplr.Character.Parent = workspace
			for _, v in lplr.Character:GetDescendants() do
				if v:IsA('Weld') or v:IsA('Motor6D') then
					if v.Part0 == oldroot then v.Part0 = clone end
					if v.Part1 == oldroot then v.Part1 = clone end
				end
			end
			return true
		end
		return false
	end
	local function destroyClone()
		if not oldroot or not oldroot.Parent or not entitylib.isAlive then return false end
		lplr.Character.Parent = game
		oldroot.Parent = lplr.Character
		lplr.Character.PrimaryPart = oldroot
		lplr.Character.Parent = workspace
		for _, v in lplr.Character:GetDescendants() do
			if v:IsA('Weld') or v:IsA('Motor6D') then
				if v.Part0 == clone then v.Part0 = oldroot end
				if v.Part1 == clone then v.Part1 = oldroot end
			end
		end
		oldroot.CanCollide = true
		if clone then
			clone:Destroy()
			clone = nil
		end
		entitylib.character.Humanoid.HipHeight = hip or 2.6
		oldroot.Transparency = 1
		oldroot = nil
		store.rootpart = nil
		FlyLandTick = tick() + 0.01
	end
	local up = 0
	local down = 0
	local startTick = tick()
	InfiniteFly = vape.Categories.Blatant:CreateModule({
		Name = 'InfiniteFly',
		Tooltip = 'Makes you go zoom.',
		Function = function(callback)
			if callback then
				task.wait()
				startTick = tick()
				if not entitylib.isAlive or FlyLandTick > tick() or not isnetworkowner(entitylib.character.RootPart) then
					return InfiniteFly:Toggle(false)
				end
				local a, b = pcall(createClone)
				if not a then
					return InfiniteFly:Toggle(false)
				end
				rayCheck.FilterDescendantsInstances = {lplr.Character, oldroot, clone, gameCamera}
				InfiniteFly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				InfiniteFly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				local lastY = entitylib.character.RootPart.Position.Y
				local lastVelo = 0
				local cancelThread = false
				InfiniteFly:Clean(runService.PreSimulation:Connect(function(delta)
					if not entitylib.isAlive or not clone or not clone.Parent or not isnetworkowner(oldroot) or (workspace:GetServerTimeNow() - lplr:GetAttribute('LastTeleported')) < 2 then
						if not isnetworkowner(oldroot) then
							notif('InfiniteFly', 'Flag detected, Landing', 1.1, 'alert')
						end
						return InfiniteFly:Toggle(false)
					end
					FlyLandTick = tick() + 0.1
					local mass = 1.3 + ((up + down) * VerticalSpeed.Value)
					local moveDir = entitylib.character.Humanoid.MoveDirection
					local velo = getSpeed()
					local destination = (moveDir * math.max(FlySpeed.Value - velo, 0) * delta)
					clone.CFrame = clone.CFrame + destination
					clone.AssemblyLinearVelocity = (moveDir * velo) + Vector3.new(0, mass, 0)
					rayCheck.FilterDescendantsInstances = {lplr.Character, oldroot, clone, gameCamera}
					local raycast = workspace:Blockcast(oldroot.CFrame + Vector3.new(0, 250, 0), Vector3.new(3, 3, 3), Vector3.new(0, -500, 0), rayCheck)
					local groundcast = workspace:Blockcast(clone.CFrame, Vector3.new(3, 3, 3), Vector3.new(0, -3, 0), rayCheck)
					local upperRay = not workspace:Blockcast(oldroot.CFrame + (oldroot.CFrame.LookVector * 17), Vector3.new(3, 3, 3), Vector3.new(0, -150, 0), rayCheck) and workspace:Blockcast(oldroot.CFrame + (oldroot.CFrame.LookVector * 17), Vector3.new(3, 3, 3), Vector3.new(0, 150, 0), rayCheck)
					local changeYLevel = 300
					local yLevel = 0
					if lastVelo - oldroot.AssemblyLinearVelocity.Y > 1200 then
						oldroot.CFrame = oldroot.CFrame + Vector3.new(0, 200, 0)
					end
					for i,v in {50, 1000, 2000, 3000, 4000, 5000, 6000, 7000} do
						if oldroot.AssemblyLinearVelocity.Y < -v then
							changeYLevel = changeYLevel + 100
							yLevel = yLevel - 15
						end
					end
					lastVelo = oldroot.AssemblyLinearVelocity.Y
					if raycast then
						oldroot.AssemblyLinearVelocity = Vector3.zero
						oldroot.CFrame = groundcast and clone.CFrame or CFrame.lookAlong(Vector3.new(clone.Position.X, raycast.Position.Y + hip, clone.Position.Z), clone.CFrame.LookVector)
					elseif (oldroot.Position.Y < (lastY - (200 + yLevel))) and not cancelThread and (oldroot.AssemblyLinearVelocity.Y < -200 or not upperRay) then
						if upperRay then
							oldroot.CFrame = CFrame.lookAlong(Vector3.new(oldroot.CFrame.X, upperRay.Position.Y, oldroot.CFrame.Z), clone.CFrame.LookVector)
						else
							oldroot.CFrame = oldroot.CFrame + Vector3.new(0, changeYLevel, 0)
						end
						if oldroot.AssemblyLinearVelocity.Y < -800 then
							oldroot.AssemblyLinearVelocity = oldroot.AssemblyLinearVelocity + Vector3.new(0, 1, 0)
						end
					end
					oldroot.CFrame = CFrame.lookAlong(Vector3.new(clone.Position.X, oldroot.Position.Y, clone.Position.Z), clone.CFrame.LookVector)
				end))
			else
				notif('InfiniteFly', tostring(tick() - startTick):sub(1, 4).. 's', 4, 'alert')
				if (SafeMode.Enabled and (tick() - startTick) > 3) or performanceStats.Ping:GetValue() > 180 then
					oldroot.CFrame = CFrame.new(-9e9, 0, -9e9)
					clone.CFrame = CFrame.new(-9e9, 0, -9e9)
				end
				destroyClone()
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end
	})
	FlySpeed = InfiniteFly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23
	})
	VerticalSpeed = InfiniteFly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 70
	})
	SafeMode = InfiniteFly:CreateToggle({
		Name = 'Safe Mode'
	})
end)

run(function()
	local InfiniteJump
	local Mode
	local jumps = 0
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	InfiniteJump = vape.Categories.Blatant:CreateModule({
		Name = "InfiniteJump",
		Tooltip = "Allows you to jump infinitely.",
		Function = function(callback)
			if callback then
				local tpTick, tpToggle, oldy = tick(), true
				jumps = 0														
				InfiniteFly:Clean(inputService.JumpRequest:Connect(function()
					jumps += 1
					if jumps > 1 and Mode.Value == "Velocity" then
						local power = math.sqrt(2 * workspace.Gravity * entitylib.character.Humanoid.JumpHeight)
						entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, power, entitylib.character.RootPart.Velocity.Z)
						if tpToggle then
							local airleft = (tick() - entitylib.character.AirTime)
							if airleft > 2 then
								if not oldy then
									local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
									if ray and TP.Enabled then
										tpToggle = false
										oldy = root.Position.Y
										tpTick = tick() + 0.11
										root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
									end
								end
							end
						else
							if oldy then
								if tpTick < tick() then
									local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
									root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
									tpToggle = true
									oldy = nil
								else
									mass = 0
								end
							end
						end
					elseif Mode.Value == "Jump" then
						
						entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						if tpToggle then
							local airleft = (tick() - entitylib.character.AirTime)
							if airleft > 2 then
								if not oldy then
									local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
									if ray and TP.Enabled then
										tpToggle = false
										oldy = root.Position.Y
										tpTick = tick() + 0.11
										root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
									end
								end
							end
						else
							if oldy then
								if tpTick < tick() then
									local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
									root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
									tpToggle = true
									oldy = nil
								else
									mass = 0
								end
							end
						end
					end
				end))
			end
		end,
		ExtraText = function() return Mode.Value or "HeatSeeker" end
	})
	Mode = InfiniteFly:CreateDropdown({
		Name = "Mode",
		List = {"Jump", "Velocity"}
	})
	TP = InfiniteFly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
end)

run(function()
	local TargetPart
	local Targets
	local FOV
	local OtherProjectiles
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}
	local old
	
	local ProjectileAimbot = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAimbot',
		Function = function(callback)
			if callback then
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
					local self, projmeta, worldmeta, origin, shootpos = ...
					local plr = entitylib.EntityMouse({
						Part = 'RootPart',
						Range = FOV.Value,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled,
						Origin = entitylib.isAlive and (shootpos or entitylib.character.RootPart.Position) or Vector3.zero
					})
	
					if plr then
						local pos = shootpos or self:getLaunchPosition(origin)
						if not pos then
							return old(...)
						end
	
						if (not OtherProjectiles.Enabled) and not projmeta.projectile:find('arrow') then
							return old(...)
						end
	
						local meta = projmeta:getProjectileMeta()
						local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
						local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
						local projSpeed = (meta.launchVelocity or 100)
						local offsetpos = pos + (projmeta.projectile == 'owl_projectile' and Vector3.zero or projmeta.fromPositionOffset)
						local balloons = plr.Character:GetAttribute('InflatedBalloons')
						local playerGravity = workspace.Gravity
	
						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end
	
						if plr.Character.PrimaryPart:FindFirstChild('rbxassetid://8200754399') then
							playerGravity = 6
						end
	
						if plr.Player:GetAttribute('IsOwlTarget') then
							for _, owl in collectionService:GetTagged('Owl') do
								if owl:GetAttribute('Target') == plr.Player.UserId and owl:GetAttribute('Status') == 2 then
									playerGravity = 0
								end
							end
						end
	
						local newlook = CFrame.new(offsetpos, plr[TargetPart.Value].Position) * CFrame.new(projmeta.projectile == 'owl_projectile' and Vector3.zero or Vector3.new(bedwars.BowConstantsTable.RelX, bedwars.BowConstantsTable.RelY, bedwars.BowConstantsTable.RelZ))
						local calc = prediction.SolveTrajectory(newlook.p, projSpeed, gravity, plr[TargetPart.Value].Position, projmeta.projectile == 'telepearl' and Vector3.zero or plr[TargetPart.Value].Velocity, playerGravity, plr.HipHeight, plr.Jumping and 42.6 or nil, rayCheck)
						if calc then
							targetinfo.Targets[plr] = tick() + 1
							return {
								initialVelocity = CFrame.new(newlook.Position, calc).LookVector * projSpeed,
								positionFrom = offsetpos,
								deltaT = lifetime,
								gravitationalAcceleration = gravity,
								drawDurationSeconds = 5
							}
						end
					end
	
					return old(...)
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = old
			end
		end,
		Tooltip = 'Silently adjusts your aim towards the enemy'
	})
	Targets = ProjectileAimbot:CreateTargets({
		Players = true,
		Walls = true
	})
	TargetPart = ProjectileAimbot:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'}
	})
	FOV = ProjectileAimbot:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	OtherProjectiles = ProjectileAimbot:CreateToggle({
		Name = 'Other Projectiles',
		Default = true
	})
end)

run(function()
	local BackTrackIncoming = {}
	local KPS
	local BackTrack = vape.Categories.World:CreateModule({
		Name = "BackTrack", 
		Function = function(callback)
			if callback then
				game:GetService("NetworkClient"):SetOutgoingKBPSLimit(KPS.Value)
				if BackTrackIncoming.Enabled then 
					settings():GetService("NetworkSettings").IncomingReplicationLag = KPS.Value * 3
				end
			else
				game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
				if BackTrackIncoming.Enabled then 
					settings():GetService("NetworkSettings").IncomingReplicationLag = 0
				end
			end
		end, 
		Tooltip = "Allows you to manipulate your network settings(Ping spoofer)"
	})
	BackTrackIncoming = BackTrack:CreateToggle({
		Name = "Incoming",
		Function = function(callback)
			if callback then
				if BackTrack.Enabled then 
					settings():GetService("NetworkSettings").IncomingReplicationLag = 99999999
				end
			else
				if BackTrack.Enabled then 
					settings():GetService("NetworkSettings").IncomingReplicationLag = 0
				end
			end
		end
	})
	KPS = BackTrack:CreateSlider({
		Name = "KPS Limit",
		Max = 250,
		Min = 1,
		Default = 25,
		Function = function()
			if BackTrack.Enabled then
				if KPS.Value <= 0 then KPS.Value = 1 end
				game:GetService("NetworkClient"):SetOutgoingKBPSLimit(KPS.Value)
				if BackTrackIncoming.Enabled then 
					settings():GetService("NetworkSettings").IncomingReplicationLag = KPS.Value * 4
				end
			else
				game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
				if BackTrackIncoming.Enabled then 
					settings():GetService("NetworkSettings").IncomingReplicationLag = 0
				end
			end
		end
	})
end)

run(function()
	local ZoomUncapper
	local ZoomAmount = {Value = 500}
	local oldMaxZoom
	
	ZoomUncapper = vape.Categories.Legit:CreateModule({
		Name = 'ZoomUncapper',
		Function = function(callback)
			if callback then
				oldMaxZoom = lplr.CameraMaxZoomDistance
				lplr.CameraMaxZoomDistance = ZoomAmount.Value
			else
				if oldMaxZoom then
					lplr.CameraMaxZoomDistance = oldMaxZoom
				end
			end
		end,
		Tooltip = 'Uncaps camera zoom distance'
	})
	
	ZoomAmount = ZoomUncapper:CreateSlider({
		Name = 'Zoom Distance',
		Min = 20,
		Max = 600,
		Default = 100,
		Function = function(val)
			if ZoomUncapper.Enabled then
				lplr.CameraMaxZoomDistance = val
			end
		end
	})
end)

run(function()
    local FakeLag
    local Mode
    local Delay
    local TransmissionOffset
    local DynamicIntensity
    local originalRemotes = {}
    local queuedCalls = {}
    local isProcessing = false
    local callInterception = {}
    
    local function backupRemoteMethods()
        if not bedwars or not bedwars.Client then return end
        
        local oldGet = bedwars.Client.Get
        callInterception.oldGet = oldGet
        
        for name, path in pairs(remotes) do
            local remote = oldGet(bedwars.Client, path)
            if remote and remote.SendToServer then
                originalRemotes[path] = remote.SendToServer
            end
        end
    end
    
    local function processDelayedCalls()
        if isProcessing then return end
        isProcessing = true
        
        task.spawn(function()
            while FakeLag.Enabled and #queuedCalls > 0 do
                local currentTime = tick()
                local toExecute = {}
                
                for i = #queuedCalls, 1, -1 do
                    local call = queuedCalls[i]
                    if currentTime >= call.executeTime then
                        table.insert(toExecute, 1, call)
                        table.remove(queuedCalls, i)
                    end
                end
                
                for _, call in ipairs(toExecute) do
                    pcall(function()
                        if call.remote and call.method == "FireServer" then
                            call.remote:FireServer(unpack(call.args))
                        elseif call.remote and call.method == "InvokeServer" then
                            call.remote:InvokeServer(unpack(call.args))
                        elseif call.originalFunc then
                            call.originalFunc(call.remote, unpack(call.args))
                        end
                    end)
                end
                
                task.wait(0.001)
            end
            isProcessing = false
        end)
    end
    
    local function queueRemoteCall(remote, method, originalFunc, ...)
        local currentDelay = Delay.Value
        
        if Mode.Value == "Dynamic" then
            if entitylib.isAlive then
                local intensity = DynamicIntensity.Value / 100
                
                local velocity = entitylib.character.HumanoidRootPart.Velocity.Magnitude
                if velocity > 20 then
                    currentDelay = currentDelay * (1 + intensity * 0.5)
                end
                
                local lastDamage = entitylib.character.Character:GetAttribute('LastDamageTakenTime') or 0
                if tick() - lastDamage < 2 then
                    currentDelay = currentDelay * (1 + intensity * 0.7)
                end
            end
        elseif Mode.Value == "Track" then
            if entitylib.isAlive then
                local nearestDist = math.huge
                for _, entity in ipairs(entitylib.List) do
                    if entity.Targetable and entity.Player and entity.Player ~= lplr then
                        local dist = (entity.RootPart.Position - entitylib.character.RootPart.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                        end
                    end
                end
                
                if nearestDist < 15 then
                    local TrackFactor = (15 - nearestDist) / 15
                    currentDelay = currentDelay * (1 + (TrackFactor * 2))
                end
            end
        end
        
        table.insert(queuedCalls, {
            remote = remote,
            method = method,
            originalFunc = originalFunc,
            args = {...},
            executeTime = tick() + (currentDelay / 1000)
        })
        
        processDelayedCalls()
    end
    
    local function interceptRemotes()
        if not bedwars or not bedwars.Client then return end
        
        local oldGet = callInterception.oldGet
        bedwars.Client.Get = function(self, remotePath)
            local remote = oldGet(self, remotePath)
            
            if remote and remote.SendToServer then
                local originalSend = remote.SendToServer
                remote.SendToServer = function(self, ...)
                    if FakeLag.Enabled and Delay.Value > 0 then
                        queueRemoteCall(self, "SendToServer", originalSend, ...)
                        return
                    end
                    return originalSend(self, ...)
                end
            end
            
            return remote
        end
        
        local function interceptSpecificRemote(path)
            local remote = oldGet(bedwars.Client, path)
            if remote and remote.FireServer then
                local originalFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    if FakeLag.Enabled and Delay.Value > 0 then
                        queueRemoteCall(self, "FireServer", originalFire, ...)
                        return
                    end
                    return originalFire(self, ...)
                end
            end
        end
        
        if remotes.AttackEntity then interceptSpecificRemote(remotes.AttackEntity) end
        if remotes.PlaceBlockEvent then interceptSpecificRemote(remotes.PlaceBlockEvent) end
        if remotes.BreakBlockEvent then interceptSpecificRemote(remotes.BreakBlockEvent) end
    end
    
    FakeLag = vape.Categories.World:CreateModule({
        Name = 'FakeLag',
        Function = function(callback)
            if callback then
                backupRemoteMethods()
                interceptRemotes()
            else
                if callInterception.oldGet then
                    bedwars.Client.Get = callInterception.oldGet
                end
                
                for _, call in ipairs(queuedCalls) do
                    pcall(function()
                        if call.originalFunc then
                            call.originalFunc(call.remote, unpack(call.args))
                        end
                    end)
                end
                table.clear(queuedCalls)
            end
        end,
        Tooltip = 'Delays your character\'s network updates to simulate high ping'
    })
    
    Mode = FakeLag:CreateDropdown({
        Name = 'Mode',
        List = {'Latency', 'Dynamic', 'Track'},
        Function = function(v)
			if v == "Dynamic" then
				DynamicIntensity.Object.Visible = true
			else
				DynamicIntensity.Object.Visible = false
			end
		end
    })
    
    Delay = FakeLag:CreateSlider({
        Name = 'Delay',
        Min = 0,
        Max = 500,
        Default = 150,
        Suffix = 'ms'
    })
    
    DynamicIntensity = FakeLag:CreateSlider({
        Name = 'Intensity',
        Min = 0,
        Max = 100,
        Default = 50,
        Suffix = '%'
    })
end)

run(function()
	local Deflect
	local DeflectTm
	local Range
	local LimitToItem
	local old
	Deflect = vape.Categories.Utility:CreateModule({
		Name = 'Deflect',
		Function = function(callback)
			if callback then
				local function getWorldFolder()
					local Map = workspace:WaitForChild("Map", math.huge)
					local Worlds = Map:WaitForChild("Worlds", math.huge)
					if not Worlds then return nil end

					return Worlds:GetChildren()[1] 
				end
				local blocks = getWorldFolder()
				local function GetPlayerFromUserID(id)
					return playersService:GetPlayerByUserId(id)
				end
				local bows = getBows()
				local originalSlot = store.inventory.hotbarSlot
				Deflect:Clean(blocks.ChildAdded:Connect(function(child)
                	if child:IsA("BasePart") and child.Name == "tnt" or child.Name == "siege_tnt" and Deflect.Enabled then
						if child:GetAttribute("PlacedByUserId") == lplr.UserId then return end
						local Distance = (child.Position - entitylib.character.RootPart.Position).Magnitude
						local nlplr = GetPlayerFromUserID(child:GetAttribute("PlacedByUserId"))
						if Distance <= Range.Value or 20 then
							if nlplr.Team == lplr.Team then
								if DeflectTm.Enabled then
									old = bedwars.ProjectileController.createLocalProjectile
									bedwars.ProjectileController.createLocalProjectile = function(...)
										local source, data, proj = ...
											for _, bowSlot in bows do
											if hotbarSwitch(bowSlot) then
												mouse1click()
												task.wait(0.135)
												hotbarSwitch(originalSlot)		
											end
										end
										return old(...)
									end
								else
									return
								end
							end
							old = bedwars.ProjectileController.createLocalProjectile
							bedwars.ProjectileController.createLocalProjectile = function(...)
								local source, data, proj = ...
									for _, bowSlot in bows do
									if hotbarSwitch(bowSlot) then
										mouse1click()
										task.wait(0.135)
										hotbarSwitch(originalSlot)		
									end
								end
								return old(...)
							end
						else
							return
						end
					end
				end))
				for i, child in blocks:GetDescendants() do
                	if child:IsA("BasePart") and child.Name == "tnt" or child.Name == "siege_tnt" and Deflect.Enabled then
						if child:GetAttribute("PlacedByUserId") == lplr.UserId then return end
						local Distance = (child.Position - entitylib.character.RootPart.Position).Magnitude
						local nlplr = GetPlayerFromUserID(child:GetAttribute("PlacedByUserId"))
						if Distance <= Range.Value or 20 then
							if nlplr.Team == lplr.Team then
								if DeflectTm.Enabled then
									old = bedwars.ProjectileController.createLocalProjectile
									bedwars.ProjectileController.createLocalProjectile = function(...)
										local source, data, proj = ...
											for _, bowSlot in bows do
											if hotbarSwitch(bowSlot) then
												mouse1click()
												task.wait(0.135)
												hotbarSwitch(originalSlot)		
											end
										end
										return old(...)
									end
								else
									return
								end
							end
							old = bedwars.ProjectileController.createLocalProjectile
							bedwars.ProjectileController.createLocalProjectile = function(...)
								local source, data, proj = ...
									for _, bowSlot in bows do
									if hotbarSwitch(bowSlot) then
										mouse1click()
										task.wait(0.135)
										hotbarSwitch(originalSlot)		
									end
								end
								return old(...)
							end
						else
							return
						end
					end
				end
			else
				bedwars.ProjectileController.createLocalProjectile = old
				old = nil
			end
		end,
		Tooltip = 'Deflects tnt in range'
	})
	DeflectTm = Deflect:CreateToggle({
		Name = "Teammate",
		Default = false,
		Tooltip = "Deflects your teammates tnt near you"
	})
	LimitToItem = Deflect:CreateToggle({
		Name = "Limit To Item",
		Default = false,
	})
	Range = Deflect:CreateSlider({
		Name = "Range",
		Default = 10,
		Min = 1,
		Max = 25,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
    local AutoDodge
    local Distance = 15
    local D

    AutoDodge = vape.Categories.Blatant:CreateModule({
        Name = 'AutoDodge',
        Tooltip = 'Automatically dodges arrows for you -- close range only',
        Function = function(callback)
            if not callback then return end
            AutoDodge:Clean(workspace.DescendantAdded:Connect(function(arrow)
                    if not AutoDodge.Enabled then return end
                    if not entitylib.isAlive then return end

                    if (arrow.Name == "crossbow_arrow" or arrow.Name == "arrow" or arrow.Name == "headhunter_arrow")and arrow:IsA("Model") then

                        if arrow:GetAttribute("ProjectileShooter") == lplr.UserId then return end

                        local root = arrow:FindFirstChildWhichIsA("BasePart")
                        if not root then return end

                        while AutoDodge.Enabled and root and root.Parent and entitylib.isAlive do
                            local char = lplr.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if not hrp or not hum then break end

                            local dist = (hrp.Position - root.Position).Magnitude
                            if dist <= (Distance + 5) then
                                local dodgePos = hrp.Position + Vector3.new(8, 0, 0)
								if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								end
                                hum:MoveTo(dodgePos)
                                break
                            end

                            task.wait(0.05)
                        end
                    end
                end)
            )
        end
    })

    D = AutoDodge:CreateSlider({
        Name = "Distance",
        Min = 1,
        Max = 30,
        Default = 15,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Distance = val
        end
    })
end)

run(function()
    local BetterKaida
	local UpdateRate
    local CastDistance
    local AttackRange
    local Angle
    local Targets
	local CastChecks
	local MaxTargets
	local Sorts
    BetterKaida = vape.Categories.Blatant:CreateModule({
        Name = "KaidaAura",
        Tooltip = "Killaura-style Kaida",
        Function = function(callback)
			if store.equippedKit ~= "summoner" then
				vape:CreateNotification("BetterKaida","Kit required only!",8,"warning")
				return
			end
			if callback then
				repeat
		            local plrs = entitylib.AllPosition({
		                Range = AttackRange.Value,
		                Wallcheck = Targets.Walls.Enabled,
		                Part = "RootPart",
		                Players = Targets.Players.Enabled,
		                NPCs = Targets.NPCs.Enabled,
		                Limit = MaxTargets.Value,
		                Sort = sortmethods[Sorts.Value]
		            })
					local castplrs = nil

					if CastChecks.Enabled then
						castplrs = entitylib.AllPosition({
							Range = CastDistance.Value,
							Wallcheck = Targets.Walls.Enabled,
							Part = "RootPart",
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sorts.Value]
		            	})
					end
		
		            local char = entitylib.character
		            local root = char.RootPart
		
		            if plrs then
		                local ent = plrs[1]
		                if ent and ent.RootPart then
		                    local delta = ent.RootPart.Position - root.Position
		                    local localFacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		                    local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		                    if angle > (math.rad(Angle.Value) / 2) then continue end
		                        local localPosition = root.Position
		                        local shootDir = CFrame.lookAt(localPosition, ent.RootPart.Position).LookVector
		                        localPosition = localPosition + shootDir * math.max((localPosition - ent.RootPart.Position).Magnitude - 16, 0)
		
		                        pcall(function()
		                            bedwars.AnimationUtil:playAnimation(lplr, bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.SUMMONER_CHARACTER_SWIPE),{looped = false})
		                        end)
		
		                        task.spawn(function()
		                            pcall(function()
		                                local clawModel = replicatedStorage.Assets.Misc.Kaida.Summoner_DragonClaw:Clone()
		                                clawModel.Parent = workspace
		
		                                if gameCamera.CFrame.Position and (gameCamera.CFrame.Position - root.Position).Magnitude < 1 then
		                                    for _, part in clawModel:GetDescendants() do
		                                        if part:IsA("MeshPart") then
		                                            part.Transparency = 0.6
		                                        end
		                                    end
		                                end
		
		                                local unitDir = Vector3.new(shootDir.X, 0, shootDir.Z).Unit
		                                local startPos = root.Position + unitDir:Cross(Vector3.new(0, 1, 0)).Unit * -5 + unitDir * 6
		                                local direction = (startPos + shootDir * 13 - startPos).Unit
		                                clawModel:PivotTo(CFrame.new(startPos, startPos + direction))
		                                clawModel.PrimaryPart.Anchored = true
		
		                                if clawModel:FindFirstChild("AnimationController") then
		                                    local animator = clawModel.AnimationController:FindFirstChildOfClass("Animator")
		                                    if animator then
		                                        bedwars.AnimationUtil:playAnimation(animator,bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.SUMMONER_CLAW_ATTACK),{looped = false, speed = 1})
		                                    end
		                                end
										KaidaController:requestBetter(localPosition,shootDir)

		                                pcall(function()
		                                    local sounds = {
		                                        bedwars.SoundList.SUMMONER_CLAW_ATTACK_1,
		                                        bedwars.SoundList.SUMMONER_CLAW_ATTACK_2,
		                                        bedwars.SoundList.SUMMONER_CLAW_ATTACK_3,
		                                        bedwars.SoundList.SUMMONER_CLAW_ATTACK_4
		                                    }
		                                    bedwars.SoundManager:playSound(sounds[math.random(1, #sounds)], { position = root.Position })
		                                end)
		
		                                task.wait(0.75)
		                                clawModel:Destroy()
		                            end)
		                        end)
		                    end
		            end
					if castplrs then
		                local ent = castplrs[1]
		                if ent and ent.RootPart then
							if CastChecks.Enabled then
								if bedwars.AbilityController:canUseAbility('summoner_start_charging') then
									bedwars.AbilityController:useAbility('summoner_start_charging')
									task.wait(1)
									if bedwars.AbilityController:canUseAbility('summoner_finish_charging') then
										bedwars.AbilityController:useAbility('summoner_finish_charging')
									else
										task.wait(0.95)
										bedwars.AbilityController:useAbility('summoner_finish_charging')
									end
								end
							end
						end
					end
					task.wait(1 /UpdateRate.Value)
				until not BetterKaida.Enabled
			end
        end
    })
    Targets = BetterKaida:CreateTargets({
        Players = true,
        NPCs = true,
        Walls = true
    })
	Sorts = BetterKaida:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
	MaxTargets = BetterKaida:CreateSlider({
		Name = "Max Targets",
		Min = 1,
		Max = 5,
		Default = 2
	})
    CastDistance = BetterKaida:CreateSlider({
        Name = "Cast Distance",
        Min = 1,
        Max = 10,
        Default = 5,
		Visible = false
    })
	CastChecks = BetterKaida:CreateToggle({
		Name = "Cast Checks",
		Tooltip = 'this allows you to use the cast ability',
		Default = false,
		Function = function(v)
			CastDistance.Object.Visible = v
		end
	})
    Angle = BetterKaida:CreateSlider({
        Name = "Angle",
        Min = 0,
        Max = 360,
        Default = 180
    })
    AttackRange = BetterKaida:CreateSlider({
        Name = "Attack Range",
        Min = 1,
        Max = 18,
        Default = 18,
        Suffix = function(val) return val == 1 and "stud" or "studs" end
    })
	UpdateRate = BetterKaida:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 360,
		Default = 60,
		Suffix = 'hz'
	})
end)

run(function()
	local NoNameTag
	NoNameTag = vape.Categories.Utility:CreateModule({
		Name = 'NNameTag',
        Tooltip = 'Removes your NameTag (Useful for streaming)',
		Function = function(callback)
			if callback then
				NoNameTag:Clean(runService.RenderStepped:Connect(function()
					pcall(function()
						lplr.Character.Head.Nametag:Destroy()
					end)
				end))
			end
		end,
	})
end)

run(function()
	local CustomTags
	local Color
	local TAG
	local old, old2
	local tagConnections = {}
	local tagRenderConn
	local tagGuiConn


	local function Color3ToHex(r, g, b)
		return string.lower(string.format("#%02X%02X%02X", r, g, b))
	end

	local function CompleteTagEffect()
		if not lplr:FindFirstChild("Tags") then return end
		local tagObj = lplr.Tags:FindFirstChild("0")
		if not tagObj then return end

		if not old then
			old = tagObj.Value
			old2 = tagObj:GetAttribute("Text")
		end

		local color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		local R = math.floor(color.R * 255)
		local G = math.floor(color.G * 255)
		local B = math.floor(color.B * 255)

		tagObj.Value = string.format("<font color='rgb(%d,%d,%d)'>[%s]</font>",R, G, B, TAG.Value)
		tagObj:SetAttribute("Text", TAG.Value)
		lplr:SetAttribute("ClanTag", TAG.Value)

		if tagRenderConn then
			tagRenderConn:Disconnect()
			tagRenderConn = nil
		end
		if tagGuiConn then
			tagGuiConn:Disconnect()
			tagGuiConn = nil
		end

		tagGuiConn = lplr.PlayerGui.ChildAdded:Connect(function(child)
			if child.Name ~= "TabListScreenGui" or not child:IsA("ScreenGui") then return end
			tagRenderConn = runService.RenderStepped:Connect(function()
				local nameToFind = (lplr.DisplayName == "" or lplr.DisplayName == lplr.Name) and lplr.Name or lplr.DisplayName
				for _, v in ipairs(child:GetDescendants()) do
					if v:IsA("TextLabel") and string.find(string.lower(v.Text), string.lower(nameToFind)) then
						v.Text = string.format('<font transparency="0.3" color="%s">[%s]</font> %s',Color3ToHex(R, G, B),TAG.Value,nameToFind)
					end
				end
			end)
		end)
	end
	
	local function RemoveTagEffect()
		if tagRenderConn then
			tagRenderConn:Disconnect()
			tagRenderConn = nil
		end

		if tagGuiConn then
			tagGuiConn:Disconnect()
			tagGuiConn = nil
		end

		if lplr:FindFirstChild("Tags") then
			local tagObj = lplr.Tags:FindFirstChild("0")
			if tagObj then
				if old then
					tagObj.Value = old
				end
				if old2 then
					tagObj:SetAttribute("Text", old2)
				end
			end
		end

		if lplr:GetAttribute("ClanTag") then
			lplr:SetAttribute("ClanTag", old)
		end

		old = nil
		old2 = nil
	end

	CustomTags = vape.Categories.Render:CreateModule({
		Name = "CustomTags",
		Tooltip = "Client-Sided visual custom clan tag on-chat",
		Function = function(callback)
			if callback then
				CompleteTagEffect()
			else
 				RemoveTagEffect()
			end
		end
	})

	Color = CustomTags:CreateColorSlider({
		Name = 'Color',
		Function = function()
			if CustomTags.Enabled then
				CompleteTagEffect()
			end
		end
	})

	TAG = CustomTags:CreateTextBox({
		Name = 'Tag',
		Default = "KKK",
		Function = function()
			if CustomTags.Enabled then
				CompleteTagEffect()
			end
		end
	})
end)

run(function()
	local MLG 
	local Pearls
	local Fireball
	local Gumdrop
	local check = false
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local projectileRemote = {InvokeServer = function() end}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)

	local function getDropDistance(root)
		local result = workspace:Raycast(root.Position,Vector3.new(0, -500, 0),rayCheck)

		if result then
			return (root.Position.Y - result.Position.Y)
		end

		return math.huge 
	end
	
	local function firePearl(pos, spot, item)
		if item then		
			local pearl = getObjSlot('telepearl')
			local originalSlot = store.inventory.hotbarSlot
			hotbarSwitch(pearl)
			local meta = bedwars.ProjectileMeta.telepearl
			local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
			if calc then
				local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
				bedwars.ProjectileController:createLocalProjectile(meta, 'telepearl', 'telepearl', pos, nil, dir, {drawDurationSeconds = 1})
				projectileRemote:InvokeServer(item.tool, 'telepearl', 'telepearl', pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)
				task.wait(0.15)
				hotbarSwitch(originalSlot)
			end
		end
	end

	local function fireFireball(pos, spot, item)		
		if item then	
			local fireball = getObjSlot('fireball')
			local originalSlot = store.inventory.hotbarSlot
			hotbarSwitch(fireball)
			local meta = bedwars.ProjectileMeta.fireball
			local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
			if calc then
				local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
				bedwars.ProjectileController:createLocalProjectile(meta, 'fireball', 'fireball', pos, nil, dir, {drawDurationSeconds = 1})
				projectileRemote:InvokeServer(item.tool, 'fireball', 'fireball', pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)
				task.wait(0.15)
				hotbarSwitch(originalSlot)
			end
		end
	end

	local function launchpad(item)
		if item then
			local gum = getObjSlot('gumdrop_bounce_pad')
			local originalSlot = store.inventory.hotbarSlot
			hotbarSwitch(gum)
			task.wait(0.15)
			hotbarSwitch(originalSlot)
			local old = bedwars.LaunchPadController.attemptLaunch
			bedwars.LaunchPadController.attemptLaunch = function(...)
				local res = {old(...)}
				local self, block = ...
			
				if (workspace:GetServerTimeNow() - self.lastLaunch) < 0.4 then
					if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
						task.spawn(bedwars.breakBlock, block, false, nil, true)
					end
				end
			
					return unpack(res)
				end
			
			MLG:Clean(function()
				bedwars.LaunchPadController.attemptLaunch = old
			end)
		end
	end

	MLG = vape.Categories.Utility:CreateModule({
		Name = "MLG",
		Tooltip = "Impressive game plays tactics",
		Function = function(callback)
			if callback then
				if not Pearls.Enabled and not Fireball.Enabled and not Gumdrop.Enabled then
					vape:CreateNotification("MLG", "You dont have anything enabled for this.", 10, "alert")
					MLG:Toggle(false)
					return
				end
				repeat
					if Pearls.Enabled then
						if entitylib.isAlive then
							local root = entitylib.character.RootPart
							local pearl = getItem('telepearl')
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
							rayCheck.CollisionGroup = root.CollisionGroup
							local drop = getDropDistance(root)

							if pearl and root.Velocity.Y < -80 and drop > 20  then
								if not check then
									check = true
									local ground = getNearGround(20)
		
									if ground then
										firePearl(root.Position, ground, pearl)
									end
								end
							else
								check = false
							end
						end
					end
					if Fireball.Enabled then
						if entitylib.isAlive then
							local root = entitylib.character.RootPart
							local fireball = getItem('fireball')
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
							rayCheck.CollisionGroup = root.CollisionGroup
							local drop = getDropDistance(root)

							if fireball and drop < 20  then
								if not check then
									check = true
									local ground = getNearGround(20)
		
									if ground then
										fireFireball(root.Position, ground, fireball)
									end
								end
							else
								check = false
							end
						end
					end
					if Gumdrop.Enabled then
						if entitylib.isAlive then
							local root = entitylib.character.RootPart
							local gum = getItem('gumdrop_bounce_pad')
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
							rayCheck.CollisionGroup = root.CollisionGroup
							local drop = getDropDistance(root)

							if gum and drop <= 10  then
								if not check then
									check = true
									local ground = getNearGround(20)
		
									if ground then
										launchpad(gum)
									end
								end
							else
								check = false
							end
						end
					end
					task.wait(0.05)
				until MLG.Enabled
			else
 				
			end
		end
	})

	Pearls = MLG:CreateToggle({
		Name = "Pearl",
		Tooltip = "Good pearl plays, void and high ground",
		Default = true
	})
	Fireball = MLG:CreateToggle({
		Name = "Fireball",
		Tooltip = "Fires a fireball at the ground when close to ground deflecting fall damage",
		Default = true
	})
	Gumdrop = MLG:CreateToggle({
		Name = "Gumdrop",
		Tooltip = "Places an gumdrop whenever ur close to falling to the ground deflecting the fall damage",
		Default = true
	})
end)

run(function()
	local FullBright
	FullBright = vape.Categories.Render:CreateModule({
		Name = 'FullBright',
		Function = function(callback)
			if callback then
				lightingService.GlobalShadows = false
			else
				lightingService.GlobalShadows = true
			end
		end,
		Tooltip = 'Turns off global shadows and boosts your FPS!'
	})
end)

run(function()
    local BuyBlocksModule
    local GUICheck
    local DelaySlider
    local running = false

    local function getShopNPC()
        local shopFound = false
        if entitylib.isAlive then
            local localPosition = entitylib.character.RootPart.Position
            for _, v in store.shop do
                if (v.RootPart.Position - localPosition).Magnitude <= 20 then
                    shopFound = true
                    break
                end
            end
        end
        return shopFound
    end

    BuyBlocksModule = vape.Categories.Utility:CreateModule({
        Name = "BuyBlocks",
        Function = function(cb)
            running = cb

            if cb then
                task.spawn(function()
                    while running do
                        local canBuy = true
                        
                        if GUICheck.Enabled then
                            if bedwars.AppController:isAppOpen('BedwarsItemShopApp') then
                                canBuy = true
                            else
                                canBuy = false
                            end
                        else
                            canBuy = getShopNPC()
                        end

                        if canBuy then
                            local args = {
                                {
                                    shopItem = {
                                        currency = "iron",
                                        itemType = "wool_white",
                                        amount = 16,
                                        price = 8,
                                        category = "Blocks"
                                    },
                                    shopId = "2_item_shop_1"
                                }
                            }

                            pcall(function()
                                game:GetService("ReplicatedStorage")
                                :WaitForChild("rbxts_include")
                                :WaitForChild("node_modules")
                                :WaitForChild("@rbxts")
                                :WaitForChild("net")
                                :WaitForChild("out")
                                :WaitForChild("_NetManaged")
                                :WaitForChild("BedwarsPurchaseItem")
                                :InvokeServer(unpack(args))
                            end)
                        end

                        task.wait(1 / DelaySlider.GetRandomValue())
                    end
                end)
            end
        end,
        Tooltip = "Automatically buys wool blocks for you"
    })

    GUICheck = BuyBlocksModule:CreateToggle({
        Name = "GUI Check",
        Tooltip = "Only buy when shop GUI is open",
        Default = false
    })

    DelaySlider = BuyBlocksModule:CreateTwoSlider({
        Name = "Delay",
        Min = 0.1,
        Max = 2,
		DefaultMin = 0.1,
		DefaultMax = 0.4,
        Decimal = 10,
		Suffix = "s",
        Tooltip = "Delay between purchases"
    })
end)

run(function()
    local RepelLag
    local Delay
    local TransmissionOffset
    local originalRemotes = {}
    local queuedCalls = {}
    local isProcessing = false
    local callInterception = {}
    
    local function backupRemoteMethods()
        if not bedwars or not bedwars.Client then return end
        
        local oldGet = bedwars.Client.Get
        callInterception.oldGet = oldGet
        
        for name, path in pairs(remotes) do
            local remote = oldGet(bedwars.Client, path)
            if remote and remote.SendToServer then
                originalRemotes[path] = remote.SendToServer
            end
        end
    end
    
    local function processDelayedCalls()
        if isProcessing then return end
        isProcessing = true
        
        task.spawn(function()
            while RepelLag.Enabled and #queuedCalls > 0 do
                local currentTime = tick()
                local toExecute = {}
                
                for i = #queuedCalls, 1, -1 do
                    local call = queuedCalls[i]
                    if currentTime >= call.executeTime then
                        table.insert(toExecute, 1, call)
                        table.remove(queuedCalls, i)
                    end
                end
                
                for _, call in ipairs(toExecute) do
                    pcall(function()
                        if call.remote and call.method == "FireServer" then
                            call.remote:FireServer(unpack(call.args))
                        elseif call.remote and call.method == "InvokeServer" then
                            call.remote:InvokeServer(unpack(call.args))
                        elseif call.originalFunc then
                            call.originalFunc(call.remote, unpack(call.args))
                        end
                    end)
                end
                
                task.wait(0.001)
            end
            isProcessing = false
        end)
    end
    
    local function queueRemoteCall(remote, method, originalFunc, ...)
        local currentDelay = Delay.Value
            if entitylib.isAlive then
                local nearestDist = math.huge
                for _, entity in ipairs(entitylib.List) do
                    if entity.Targetable and entity.Player and entity.Player ~= lplr then
                        local dist = (entity.RootPart.Position - entitylib.character.RootPart.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                        end
                    end
                end
                
                if nearestDist < 15 then
                    local repelFactor = (15 - nearestDist) / 15
                    currentDelay = currentDelay * (1 + (repelFactor * 2))
                end
            end
        
        if TransmissionOffset.Value > 0 then
            local jitter = math.random(-TransmissionOffset.Value, TransmissionOffset.Value)
            currentDelay = math.max(0, currentDelay + jitter)
        end
        
        table.insert(queuedCalls, {
            remote = remote,
            method = method,
            originalFunc = originalFunc,
            args = {...},
            executeTime = tick() + (currentDelay / 1000)
        })
        
        processDelayedCalls()
    end
    
    local function interceptRemotes()
        if not bedwars or not bedwars.Client then return end
        
        local oldGet = callInterception.oldGet
        bedwars.Client.Get = function(self, remotePath)
            local remote = oldGet(self, remotePath)
            
            if remote and remote.SendToServer then
                local originalSend = remote.SendToServer
                remote.SendToServer = function(self, ...)
                    if RepelLag.Enabled and Delay.Value > 0 then
                        queueRemoteCall(self, "SendToServer", originalSend, ...)
                        return
                    end
                    return originalSend(self, ...)
                end
            end
            
            return remote
        end
        
        local function interceptSpecificRemote(path)
            local remote = oldGet(bedwars.Client, path)
            if remote and remote.FireServer then
                local originalFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    if RepelLag.Enabled and Delay.Value > 0 then
                        queueRemoteCall(self, "FireServer", originalFire, ...)
                        return
                    end
                    return originalFire(self, ...)
                end
            end
        end
        
        if remotes.AttackEntity then interceptSpecificRemote(remotes.AttackEntity) end
        if remotes.PlaceBlockEvent then interceptSpecificRemote(remotes.PlaceBlockEvent) end
        if remotes.BreakBlockEvent then interceptSpecificRemote(remotes.BreakBlockEvent) end
    end
    
    RepelLag = vape.Categories.World:CreateModule({
        Name = 'RepelLag',
        Function = function(callback)
            if callback then
                backupRemoteMethods()
                interceptRemotes()
                
            else
                if bedwars and bedwars.Client and callInterception.oldGet then
                    bedwars.Client.Get = callInterception.oldGet
                end
                
                for _, call in ipairs(queuedCalls) do
                    pcall(function()
                        if call.originalFunc then
                            call.originalFunc(call.remote, unpack(call.args))
                        end
                    end)
                end
                table.clear(queuedCalls)
            end
        end,
        Tooltip = 'Desync but sync\'s with the current world making you look fakelag and alittle with backtrack'

    })
    TransmissionOffset = RepelLag:CreateSlider({
		Name = "Transmission",
		Min = 0,
		Max = 5,
		Default = 2,
		Tooltip = 'jitteries ur movement'
	})
	Delay = RepelLag:CreateSlider({
		Name = "Delay",
		Suffix = "ms",
		Min = 5,
		Max = 1000,
		Default = math.floor(math.random(100,250) - math.random(1,5) - math.random())
	})
end)

run(function()
	local AEGT
	local e
	local function Reset()
		if #playersService:GetChildren() == 1 then return end
		local TeleportService = game:GetService("TeleportService")
		local data = TeleportService:GetLocalPlayerTeleportData()
		AEGT:Clean(TeleportService:Teleport(game.PlaceId, lplr, data))
	end
	AEGT = vape.Categories.Utility:CreateModule({
		Name = 'EmptyGameTP',
		Function = function(callback)
			if callback then
				if E.Enabled then
					AEGT:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
						if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
							Reset()
						end
					end))
					AEGT:Clean(vapeEvents.MatchEndEvent.Event:Connect(Reset))
				else
                    if #playersService:GetChildren() > 1 then
                        vape:CreateNotification("AutoEmptyGameTP", "Teleporting to Empty Game!", 6)
                        task.wait((6 / 3.335))
						Reset()
					end
				end
			else
				return
			end
		end,
		Tooltip = 'Makes you automatically TP to a empty game'
	})
	E = AEGT:CreateToggle({
		Name = "Game Ended",
		Default = true,
		Tooltip = "Makes you TP whenever you win/lose a match which resets the history"
	})
end)

run(function()
    local AutoWin
	local function Duels()
		if Speed.Enabled and Fly.Enabled then
			Fly:Toggle(false)
			task.wait(0.025)
			Speed:Toggle(false)
		elseif Speed.Enabled then
			Speed:Toggle(false)
		elseif Fly.Enabled then
			Fly:Toggle(false)
		end

		if not Scaffold.Enabled and not Breaker.Enabled then
			Breaker:Toggle(true)
			task.wait(0.025)
			Scaffold:Toggle(true)
		elseif not Scaffold.Enabled then
			Scaffold:Toggle(true)
		elseif not Breaker.Enabled then
			Breaker:Toggle(true)
		end

                    local T = 50
                    if #playersService:GetChildren() > 1 then
                        vape:CreateNotification("AutoWin", "Teleporting to Empty Game!", 6)
                        task.wait((6 / 3.335))
                        local data = TeleportService:GetLocalPlayerTeleportData()
                        AutoWin:Clean(TeleportService:Teleport(game.PlaceId, lplr, data))
                    end
                    if lplr.Team.Name ~= "Orange" and lplr.Team.Name ~= "Blue" then
                        vape:CreateNotification("AutoWin","Waiting for an assigned team! (this may take a while if early loaded)", 6)
                        task.wait(15)
                    end
                    local ID = lplr:GetAttribute("Team")
                    local GeneratorName = "cframe-" .. ID .. "_generator"
                    local ItemShopName = ID .. "_item_shop"
					if ID == "2" then
						ItemShopName = ID .. "_item_shop_1"
					else
						ItemShopName = ItemShopName
					end
                    local CurrentGen = workspace:FindFirstChild(GeneratorName)
                    local CurrentItemShop = workspace:FindFirstChild(ItemShopName)
                    local id = "0"
                	local oppTeamName = "nil"
                    if ID == "1" then
                        id = "2"
                        oppTeamName = "Orange"
                    else
                        id = "1"
                        oppTeamName = "Blue"
                    end
                    local OppBedName = id .. "_bed"
                    local OppositeTeamBedPos = workspace:FindFirstChild("MapCFrames"):FindFirstChild(OppBedName).Value.Position

					local function PurchaseWool()
					    replicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.BedwarsPurchaseItem:InvokeServer({
					        shopItem = {
					            currency = "iron",
					            itemType = "wool_white",
					            amount = 16,
					            price = 8,
					            category = "Blocks",
					            disabledInQueue = {"mine_wars"}
					        },
					        shopId = "1_item_shop"
					    })
					end
					
					local function fly()
					    task.spawn(function()
					        while task.wait() do
					            if entitylib and entitylib.isAlive then
					                local char = lplr.Character
					                local root = char and char.PrimaryPart
					                if root then
					                    local v = root.Velocity
					                    root.Velocity = Vector3.new(v.X, 0, v.Z)
					                end
					            end
					        end
					    end)
					end
					
					local function Speed()
					    task.spawn(function()
					        while task.wait() do
					            if entitylib and entitylib.isAlive then
					                local hum = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
					                if hum then
					                    hum.WalkSpeed = 23.05
					                end
					            end
					        end
					    end)
					end
					
					local function checkWallClimb()
					    if not (entitylib and entitylib.isAlive) then
					        return false
					    end
					
					    local character = lplr.Character
					    local root = character and character.PrimaryPart
					    if not root then
					        return false
					    end
					
					    local raycastParams = RaycastParams.new()
					    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					    raycastParams.FilterDescendantsInstances = {
					        character,
					        camera and camera:FindFirstChild("Viewmodel"),
					        Workspace:FindFirstChild("ItemDrops")
					    }
					
					    local origin = root.Position - Vector3.new(0, 1, 0)
					    local direction = root.CFrame.LookVector * 1.5
					
					    local result = Workspace:Raycast(origin, direction, raycastParams)
					    if result and result.Instance and result.Instance.Transparency < 1 then
					        root.Velocity = Vector3.new(root.Velocity.X, 100, root.Velocity.Z)
					    end
					
					    return true
					end
					
					local function climbwalls()
					    task.spawn(function()
					        while task.wait() do
					            if entitylib and entitylib.isAlive then
					                pcall(checkWallClimb)
					            else
					                break
					            end
					        end
					    end)
					end
                        local function MapLayoutBLUE()
                            if workspace.Map.Worlds:FindFirstChild("duels_Swamp") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.15)
                                local pos = {
                                    [1] = Vector3.new(54.42063522338867, 22.4999942779541, 99.56651306152344),
                                    [2] = Vector3.new(119.33378601074219, 22.4999942779541, 99.06503295898438),
                                    [3] = Vector3.new(231.82752990722656, 19.4999942779541, 98.30278015136719),
                                    [4] = Vector3.new(230.23426818847656, 19.4999942779541, 142.17169189453125),
                                    [5] = Vector3.new(237.4776153564453, 22.4999942779541, 142.03660583496094)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Blossom") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(153.83029174804688, 37.4999885559082, 146.81619262695312),
                                    [2] = Vector3.new(172.6735382080078, 37.4999885559082, 120.15453338623047),
                                    [3] = Vector3.new(172.6735382080078, 37.4999885559082, 120.15453338623047),
                                    [4] = Vector3.new(284.78765869140625, 37.4999885559082, 124.80931854248047),
                                    [5] = Vector3.new(293.6907958984375, 37.4999885559082, 143.09649658203125)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Darkholm") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(56.4425163269043, 70.4999771118164, 196.7547607421875),
                                    [2] = Vector3.new(188.90316772460938, 70.4999771118164, 198.4145050048828),
                                    [3] = Vector3.new(194.74700927734375, 73.4999771118164, 198.49697875976562),
                                    [4] = Vector3.new(198.50704956054688, 76.4999771118164, 198.38743591308594),
                                    [5] = Vector3.new(201.18421936035156, 79.4999771118164, 198.30943298339844),
                                    [6] = Vector3.new(340.8443603515625, 70.4999771118164, 197.34677124023438)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 4 or i == 5 or i == 6 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Christmas") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(143.5197296142578, 40.4999885559082, 410.59930419921875),
                                    [2] = Vector3.new(143.98350524902344, 40.4999885559082, 328.6651306152344),
                                    [3] = Vector3.new(133.665771484375, 40.4999885559082, 328.6337585449219),
                                    [4] = Vector3.new(134.53382873535156, 40.4999885559082, 253.40147399902344),
                                    [5] = Vector3.new(106.36888122558594, 40.4999885559082, 253.07655334472656),
                                    [6] = Vector3.new(108.05854797363281, 40.4999885559082, 162.84751892089844),
                                    [7] = Vector3.new(150.0508575439453, 40.4999885559082, 139.75106811523438)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Crystalmount") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(56.529605865478516, 31.4999942779541, 117.44342803955078),
                                    [2] = Vector3.new(243.1451873779297, 28.4999942779541, 117.13523864746094),
                                    [3] = Vector3.new(243.86920166015625, 28.4999942779541, 132.01922607421875),
                                    [4] = Vector3.new(284.8253173828125, 28.4999942779541, 131.13760375976562),
                                    [5] = Vector3.new(284.3399963378906, 28.4999942779541, 197.74057006835938),
                                    [6] = Vector3.new(336.2626953125, 28.4999942779541, 197.87362670898438),
                                    [7] = Vector3.new(336.4390563964844, 28.4999942779541, 212.56610107421875)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Desert-Shrine") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(160.9988250732422, 37.4999885559082, 104.86061096191406),
                                    [2] = Vector3.new(211.70367431640625, 37.4999885559082, 104.84205627441406),
                                    [3] = Vector3.new(225.6957244873047, 40.4999885559082, 105.22856140136719),
                                    [4] = Vector3.new(231.78103637695312, 43.4999885559082, 105.20640563964844),
                                    [5] = Vector3.new(240.7913360595703, 46.4999885559082, 105.17339324951172),
                                    [6] = Vector3.new(261.78643798828125, 46.4999885559082, 105.35729217529297),
                                    [7] = Vector3.new(260.72406005859375, 37.4999885559082, 147.41888427734375)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 4 or i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Canyon") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(106.2856216430664, 22.4999942779541, 167.7103271484375),
                                    [2] = Vector3.new(205.44677734375, 22.4999942779541, 168.1051483154297),
                                    [3] = Vector3.new(206.19129943847656, 22.4999942779541, 122.0677261352539),
                                    [4] = Vector3.new(246.20388793945312, 22.4999942779541, 122.23123931884766),
                                    [5] = Vector3.new(246.25616455078125, 22.4999942779541, 117.90743255615234),
                                    [6] = Vector3.new(340.50830078125, 22.4999942779541, 119.04676818847656),
                                    [7] = Vector3.new(408.0753479003906, 22.4999942779541, 119.86353302001953),
                                    [8] = Vector3.new(408.1478576660156, 25.4999942779541, 147.79750061035156),
                                    [9] = Vector3.new(408.3157958984375, 28.4999942779541, 152.88963317871094),
                                    [10] = Vector3.new(408.40478515625, 31.4999942779541, 156.04873657226562),
                                    [11] = Vector3.new(416.6556396484375, 31.4999942779541, 156.042724609375)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 9 or i == 10 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    if i == 8 then
                                        task.wait(0.85)
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Fountain-Peaks") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(197.8756103515625, 55.4999885559082, 146.2112274169922),
                                    [2] = Vector3.new(197.74893188476562, 55.4999885559082, 203.87440490722656),
                                    [3] = Vector3.new(197.7208709716797, 55.4999885559082, 216.67771911621094),
                                    [4] = Vector3.new(197.707763671875, 58.4999885559082, 222.7259063720703),
                                    [5] = Vector3.new(197.6983184814453, 61.4999885559082, 228.9031219482422),
                                    [6] = Vector3.new(197.71287536621094, 64.4999771118164, 234.8250732421875),
                                    [7] = Vector3.new(197.7032470703125, 67.4999771118164, 240.8802947998047),
                                    [8] = Vector3.new(197.7696990966797, 70.4999771118164, 242.91575622558594),
                                    [9] = Vector3.new(216.24256896972656, 70.4999771118164, 257.28955078125),
                                    [10] = Vector3.new(216.3074188232422, 70.4999771118164, 278.1252746582031),
                                    [11] = Vector3.new(198.38975524902344, 70.4999771118164, 278.18292236328125),
                                    [12] = Vector3.new(197.85623168945312, 55.4999885559082, 325.6739196777344)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 4 or i == 5 or i == 6 or i == 7 or i == 8 or i == 9 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Glacier") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(170.14671325683594, 28.4999942779541, 101.89541625976562),
                                    [2] = Vector3.new(170.22109985351562, 28.4999942779541, 84.97834777832031),
                                    [3] = Vector3.new(175.1810760498047, 31.4999942779541, 85.0855484008789),
                                    [4] = Vector3.new(183.48684692382812, 34.4999885559082, 85.162353515625),
                                    [5] = Vector3.new(251.9368896484375, 34.4999885559082, 85.79531860351562),
                                    [6] = Vector3.new(251.87530517578125, 34.4999885559082, 123.78746032714844),
                                    [7] = Vector3.new(312.71527099609375, 28.4999942779541, 124.30342864990234),
                                    [8] = Vector3.new(372.5546875, 28.4999942779541, 124.64036560058594)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 4 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Enchanted-Forest") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(150.46469116210938, 16.4999942779541, 86.60432434082031),
                                    [2] = Vector3.new(210.5728759765625, 16.4999942779541, 87.79756164550781),
                                    [3] = Vector3.new(216.8912811279297, 19.4999942779541, 87.77125549316406),
                                    [4] = Vector3.new(222.78244018554688, 22.4999942779541, 87.67369842529297),
                                    [5] = Vector3.new(227.1719512939453, 25.4999942779541, 87.5146484375),
                                    [6] = Vector3.new(226.99400329589844, 25.4999942779541, 130.34024047851562)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 4 or i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Glade") then
                                vape:CreateNotification("AutoWin", "Teleporting to lobby, incorrect map!", 4, "warning")
                                task.wait(2.25)
                                lobby()
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Mystic") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(220.50648498535156, 61.4999885559082, 56.93876647949219),
                                    [2] = Vector3.new(220.04396057128906, 49.4999885559082, 120.4498519897461),
                                    [3] = Vector3.new(219.68345642089844, 49.4999885559082, 206.69497680664062),
                                    [4] = Vector3.new(186.8123779296875, 49.4999885559082, 206.58248901367188),
                                    [5] = Vector3.new(186.54818725585938, 49.4999885559082, 218.91282653808594),
                                    [6] = Vector3.new(141.8109588623047, 40.4999885559082, 217.94798278808594),
                                    [7] = Vector3.new(141.24285888671875, 40.4999885559082, 236.9816131591797),
                                    [8] = Vector3.new(140.99461364746094, 43.4999885559082, 243.62637329101562),
                                    [9] = Vector3.new(140.87582397460938, 46.4999885559082, 249.68634033203125),
                                    [10] = Vector3.new(140.93898010253906, 49.4999885559082, 256.1976013183594),
                                    [11] = Vector3.new(129.94161987304688, 49.4999885559082, 282.0950012207031),
                                    [12] = Vector3.new(129.7279815673828, 49.4999885559082, 341.5072326660156),
                                    [13] = Vector3.new(137.8108367919922, 49.4999885559082, 341.5338134765625),
                                    [14] = Vector3.new(137.6667022705078, 40.4999885559082, 382.5955810546875),
                                    [15] = Vector3.new(153.81500244140625, 40.4999885559082, 381.9942321777344),
                                    [16] = Vector3.new(159.4097442626953, 43.4999885559082, 381.96942138671875),
                                    [17] = Vector3.new(165.2544708251953, 46.4999885559082, 381.9435119628906),
                                    [18] = Vector3.new(172.84909057617188, 49.4999885559082, 381.909912109375),
                                    [19] = Vector3.new(181.5446319580078, 49.4999885559082, 383.2634582519531),
                                    [20] = Vector3.new(181.60052490234375, 49.4999885559082, 391.0975646972656),
                                    [21] = Vector3.new(218.74085998535156, 49.4999885559082, 391.41815185546875)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 8 or i == 9 or i == 10 or i == 11 or i == 16 or i == 17 or i == 18 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Nordic") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(149.74044799804688, 55.4999885559082, 128.84291076660156),
                                    [2] = Vector3.new(149.46397399902344, 52.4999885559082, 119.18580627441406),
                                    [3] = Vector3.new(194.9976806640625, 49.4999885559082, 118.41926574707031),
                                    [4] = Vector3.new(194.60174560546875, 49.4999885559082, 80.95228576660156),
                                    [5] = Vector3.new(251.18060302734375, 49.4999885559082, 81.73896789550781),
                                    [6] = Vector3.new(250.67430114746094, 49.4999885559082, 117.65328979492188),
                                    [7] = Vector3.new(277.3354797363281, 49.4999885559082, 118.02685546875),
                                    [8] = Vector3.new(301.5650634765625, 52.4999885559082, 119.07581329345703)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 8 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Nordic-Snowy") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(149.74044799804688, 55.4999885559082, 128.84291076660156),
                                    [2] = Vector3.new(149.46397399902344, 52.4999885559082, 119.18580627441406),
                                    [3] = Vector3.new(194.9976806640625, 49.4999885559082, 118.41926574707031),
                                    [4] = Vector3.new(194.60174560546875, 49.4999885559082, 80.95228576660156),
                                    [5] = Vector3.new(251.18060302734375, 49.4999885559082, 81.73896789550781),
                                    [6] = Vector3.new(250.67430114746094, 49.4999885559082, 117.65328979492188),
                                    [7] = Vector3.new(277.3354797363281, 49.4999885559082, 118.02685546875),
                                    [8] = Vector3.new(301.5650634765625, 52.4999885559082, 119.07581329345703)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 8 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Pinewood") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(129.2021026611328, 28.4999942779541, 135.2041473388672),
                                    [2] = Vector3.new(153.8468475341797, 28.4999942779541, 136.81089782714844),
                                    [3] = Vector3.new(167.808837890625, 25.4999942779541, 204.21250915527344),
                                    [4] = Vector3.new(167.5161590576172, 25.4999942779541, 225.06863403320312),
                                    [5] = Vector3.new(167.30459594726562, 28.4999942779541, 250.10618591308594),
                                    [6] = Vector3.new(126.89143371582031, 28.4999942779541, 249.57664489746094)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Seasonal") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(124.22999572753906, 22.4999942779541, 50.354896545410156),
                                    [2] = Vector3.new(124.38113403320312, 25.4999942779541, 77.86675262451172),
                                    [3] = Vector3.new(132.7975616455078, 25.4999942779541, 77.82051849365234),
                                    [4] = Vector3.new(132.92849731445312, 25.4999942779541, 101.65450286865234),
                                    [5] = Vector3.new(133.16488647460938, 25.4999942779541, 193.8179931640625),
                                    [6] = Vector3.new(133.18614196777344, 28.4999942779541, 202.04595947265625),
                                    [7] = Vector3.new(133.21290588378906, 31.4999942779541, 212.46200561523438),
                                    [8] = Vector3.new(133.52256774902344, 25.4999942779541, 297.04766845703125)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 2 or i == 6 or i == 7 or i == 8 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Snowman-Park") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(161.58139038085938, 16.4999942779541, 171.4049530029297),
                                    [2] = Vector3.new(205.41207885742188, 16.4999942779541, 171.3085174560547),
                                    [3] = Vector3.new(205.36370849609375, 16.4999942779541, 149.45138549804688)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_SteamPunk") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(160.793701171875, 82.4999771118164, 180.54180908203125),
                                    [2] = Vector3.new(218.45816040039062, 82.4999771118164, 179.80137634277344),
                                    [3] = Vector3.new(260.0395202636719, 82.4999771118164, 180.11831665039062),
                                    [4] = Vector3.new(265.80975341796875, 85.4999771118164, 180.09951782226562),
                                    [5] = Vector3.new(272.1552429199219, 88.4999771118164, 180.07870483398438),
                                    [6] = Vector3.new(292.67315673828125, 91.4999771118164, 179.76800537109375),
                                    [7] = Vector3.new(292.5359191894531, 91.4999771118164, 212.19924926757812),
                                    [8] = Vector3.new(292.81573486328125, 94.4999771118164, 216.00205993652344),
                                    [9] = Vector3.new(292.77001953125, 97.4999771118164, 219.78807067871094),
                                    [10] = Vector3.new(292.73516845703125, 100.4999771118164, 222.6680145263672),
                                    [11] = Vector3.new(292.6996154785156, 103.4999771118164, 225.60629272460938),
                                    [12] = Vector3.new(292.6380920410156, 106.4999771118164, 230.70294189453125),
                                    [13] = Vector3.new(339.04364013671875, 106.4999771118164, 231.263916015625),
                                    [14] = Vector3.new(336.16845703125, 106.4999771118164, 204.35227966308594),
                                    [15] = Vector3.new(344.0719299316406, 109.4999771118164, 204.4552001953125),
                                    [16] = Vector3.new(381.0630798339844, 91.4999771118164, 204.93626403808594),
                                    [17] = Vector3.new(381.4077453613281, 91.4999771118164, 178.77200317382812)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 4 or i == 5 or i == 6 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Volatile") then
                                vape:CreateNotification("AutoWin", "Teleporting to lobby, incorrect map!", 4, "warning")
                                task.wait(2.25)
                                lobby()
                            else
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(3)
                            end
                        end

                        local function MapLayoutORANGE()
                            if workspace.Map.Worlds:FindFirstChild("duels_Swamp") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.15)
                                local pos = {
                                    [1] = Vector3.new(354.59832763671875, 22.4999942779541, 141.19931030273438),
                                    [2] = Vector3.new(288.35980224609375, 22.4999942779541, 140.82131958007812),
                                    [3] = Vector3.new(178.31858825683594, 19.4999942779541, 140.5794677734375),
                                    [4] = Vector3.new(178.41314697265625, 19.4999942779541, 97.60221862792969),
                                    [5] = Vector3.new(167.98536682128906, 22.4999942779541, 97.5783920288086)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Blossom") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(305.7127685546875, 37.4999885559082, 143.80267333984375),
                                    [2] = Vector3.new(294.0784912109375, 37.4999885559082, 166.19984436035156),
                                    [3] = Vector3.new(172.51058959960938, 37.4999885559082, 166.019287109375),
                                    [4] = Vector3.new(172.54029846191406, 37.4999885559082, 142.85401916503906),
                                    [5] = Vector3.new(153.874755859375, 37.4999885559082, 142.830078125)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Darkholm") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(459.380615234375, 70.4999771118164, 185.4072265625),
                                    [2] = Vector3.new(327.0589599609375, 70.4999771118164, 185.53668212890625),
                                    [3] = Vector3.new(321.13018798828125, 73.4999771118164, 185.5518341064453),
                                    [4] = Vector3.new(318.7851867675781, 76.4999771118164, 185.55780029296875),
                                    [5] = Vector3.new(315.27337646484375, 79.4999771118164, 185.56675720214844),
                                    [6] = Vector3.new(173.04278564453125, 70.4999771118164, 185.9304962158203)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 4 or i == 5 or i == 6 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Christmas") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(138.04017639160156, 40.4999885559082, 140.58433532714844),
                                    [2] = Vector3.new(115.14994049072266, 40.4999885559082, 140.646240234375),
                                    [3] = Vector3.new(115.0350341796875, 40.4999885559082, 192.96180725097656),
                                    [4] = Vector3.new(107.36815643310547, 40.4999885559082, 192.94497680664062),
                                    [5] = Vector3.new(107.2378158569336, 40.4999885559082, 252.27471923828125),
                                    [6] = Vector3.new(115.74702453613281, 40.4999885559082, 326.864990234375),
                                    [7] = Vector3.new(145.2953338623047, 40.4999885559082, 326.3784484863281),
                                    [8] = Vector3.new(146.02037048339844, 40.4999885559082, 419.9883117675781),
                                    [9] = Vector3.new(121.12679290771484, 40.4999885559082, 420.07379150390625),
                                    [10] = Vector3.new(120.96660614013672, 40.4999885559082, 431.7377624511719),
                                    [11] = Vector3.new(102.22850036621094, 40.4999885559082, 432.4336242675781)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Crystalmount") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(523.8486328125, 31.4999942779541, 212.9307861328125),
                                    [2] = Vector3.new(404.15264892578125, 28.4999942779541, 212.3941650390625),
                                    [3] = Vector3.new(339.4782409667969, 28.4999942779541, 212.12184143066406),
                                    [4] = Vector3.new(339.5323181152344, 28.4999942779541, 193.957763671875),
                                    [5] = Vector3.new(315.8712158203125, 28.4999942779541, 193.65440368652344),
                                    [6] = Vector3.new(316.3773498535156, 28.4999942779541, 164.9138641357422),
                                    [7] = Vector3.new(268.30816650390625, 28.4999942779541, 165.28636169433594),
                                    [8] = Vector3.new(268.2789306640625, 28.4999942779541, 132.95947265625),
                                    [9] = Vector3.new(248.2838897705078, 28.4999942779541, 132.472412109375),
                                    [10] = Vector3.new(248.64834594726562, 28.4999942779541, 117.51133728027344)
                                }
                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Desert-Shrine") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(408.21319580078125, 43.4999885559082, 147.07444763183594),
                                    [2] = Vector3.new(319.3170166015625, 37.4999885559082, 146.8579864501953),
                                    [3] = Vector3.new(258.67718505859375, 37.4999885559082, 146.6586151123047),
                                    [4] = Vector3.new(251.12399291992188, 40.4999885559082, 146.63404846191406),
                                    [5] = Vector3.new(244.779296875, 43.4999885559082, 146.6132354736328),
                                    [6] = Vector3.new(233.6015625, 46.4999885559082, 146.5764923095703),
                                    [7] = Vector3.new(211.4630889892578, 46.4999885559082, 146.4730224609375),
                                    [8] = Vector3.new(210.13014221191406, 37.4999885559082, 105.5939712524414)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 4 or i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Canyon") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(409.8771667480469, 22.49999237060547, 116.0271224975586),
                                    [2] = Vector3.new(327.4731750488281, 22.4999942779541, 122.96821594238281),
                                    [3] = Vector3.new(327.6976013183594, 25.4999942779541, 130.06983947753906),
                                    [4] = Vector3.new(326.8793029785156, 25.4999942779541, 165.20481872558594),
                                    [5] = Vector3.new(271.6249084472656, 22.4999942779541, 165.552978515625),
                                    [6] = Vector3.new(271.6521911621094, 22.49999237060547, 169.8865509033203),
                                    [7] = Vector3.new(107.6816177368164, 22.49999237060547, 171.72158813476562),
                                    [8] = Vector3.new(108.24556732177734, 22.49999237060547, 154.60629272460938),
                                    [9] = Vector3.new(108.06343841552734, 25.4999942779541, 141.64547729492188),
                                    [10] = Vector3.new(107.85572814941406, 28.4999942779541, 135.289306640625),
                                    [11] = Vector3.new(106.55116271972656, 31.4999942779541, 122.169677734375)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 9 or i == 10 or i == 11 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Fountain-Peaks") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(197.80709838867188, 55.4999885559082, 380.91845703125),
                                    [2] = Vector3.new(198.08798217773438, 55.4999885559082, 330.4879150390625),
                                    [3] = Vector3.new(198.1407470703125, 55.4999885559082, 319.4066162109375),
                                    [4] = Vector3.new(198.16429138183594, 58.4999885559082, 314.4744873046875),
                                    [5] = Vector3.new(198.19857788085938, 61.4999885559082, 307.2679443359375),
                                    [6] = Vector3.new(198.23214721679688, 64.4999771118164, 300.2276306152344),
                                    [7] = Vector3.new(198.2572784423828, 67.4999771118164, 294.9621276855469),
                                    [8] = Vector3.new(198.0744171142578, 70.4999771118164, 277.3271484375),
                                    [9] = Vector3.new(198.19863891601562, 73.4999771118164, 261.74713134765625),
                                    [10] = Vector3.new(198.17916870117188, 55.4999885559082, 208.74942016601562),
                                    [11] = Vector3.new(198.27981567382812, 55.4999885559082, 154.0118865966797)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 4 or i == 5 or i == 6 or i == 7 or i == 8 or i == 9 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Glacier") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(307.63275146484375, 28.4999942779541, 107.5975570678711),
                                    [2] = Vector3.new(308.0843811035156, 28.4999942779541, 123.1988296508789),
                                    [3] = Vector3.new(302.8423156738281, 31.4999942779541, 123.20875549316406),
                                    [4] = Vector3.new(224.78607177734375, 34.4999885559082, 123.57905578613281),
                                    [5] = Vector3.new(224.7245635986328, 34.4999885559082, 85.76427459716797),
                                    [6] = Vector3.new(166.7411651611328, 28.4999942779541, 85.52276611328125)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 4 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Enchanted-Forest") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(297.86676025390625, 16.4999942779541, 128.88902282714844),
                                    [2] = Vector3.new(248.98641967773438, 16.4999942779541, 128.79608154296875),
                                    [3] = Vector3.new(239.7410430908203, 19.4999942779541, 128.74380493164062),
                                    [4] = Vector3.new(233.1702117919922, 22.4999942779541, 128.7002716064453),
                                    [5] = Vector3.new(229.46270751953125, 25.4999942779541, 128.67581176757812),
                                    [6] = Vector3.new(229.83551025390625, 25.4999942779541, 82.51109313964844)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 3 or i == 4 or i == 5 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Glade") then
                                vape:CreateNotification("AutoWin", "Teleporting to lobby, incorrect map!", 4, "warning")
                                task.wait(2.25)
                                lobby()
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Mystic") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(221.40838623046875, 49.4999885559082, 398.5241394042969),
                                    [2] = Vector3.new(254.4637451171875, 49.4999885559082, 397.211669921875),
                                    [3] = Vector3.new(254.8128204345703, 49.4999885559082, 386.21221923828125),
                                    [4] = Vector3.new(298.4759216308594, 40.4999885559082, 386.5443420410156),
                                    [5] = Vector3.new(298.58660888671875, 40.4999885559082, 370.09735107421875),
                                    [6] = Vector3.new(298.7728271484375, 43.4999885559082, 362.7982177734375),
                                    [7] = Vector3.new(298.9396667480469, 46.4999885559082, 357.5649108886719),
                                    [8] = Vector3.new(298.80377197265625, 49.4999885559082, 349.3194580078125),
                                    [9] = Vector3.new(298.58892822265625, 49.4999885559082, 339.3221740722656),
                                    [10] = Vector3.new(310.25390625, 49.4999885559082, 339.0869140625),
                                    [11] = Vector3.new(310.1837463378906, 49.4999885559082, 262.0010681152344),
                                    [12] = Vector3.new(300.18365478515625, 49.4999885559082, 261.933349609375),
                                    [13] = Vector3.new(300.37420654296875, 40.4999885559082, 223.8512725830078),
                                    [14] = Vector3.new(285.1274719238281, 40.4999885559082, 223.8217315673828),
                                    [15] = Vector3.new(279.4645690917969, 43.4999885559082, 223.8112335205078),
                                    [16] = Vector3.new(272.19329833984375, 46.4999885559082, 223.79776000976562),
                                    [17] = Vector3.new(266.0102844238281, 49.4999885559082, 223.78663635253906),
                                    [18] = Vector3.new(252.8553924560547, 49.4999885559082, 223.3814239501953),
                                    [19] = Vector3.new(252.7893829345703, 49.4999885559082, 211.234130859375),
                                    [20] = Vector3.new(219.3946075439453, 49.4999885559082, 211.3135223388672)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 6 or i == 7 or i == 8 or i == 15 or i == 16 or i == 17 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Nordic-Snowy") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(292.3473815917969, 37.4999885559082, 128.8502960205078),
                                    [2] = Vector3.new(292.2837829589844, 37.4999885559082, 103.8826904296875),
                                    [3] = Vector3.new(246.86444091796875, 34.4999885559082, 103.998046875),
                                    [4] = Vector3.new(246.81077575683594, 34.4999885559082, 82.9254379272461),
                                    [5] = Vector3.new(198.99082946777344, 34.4999885559082, 83.04700469970703),
                                    [6] = Vector3.new(200.015625, 34.4999885559082, 139.6517333984375),
                                    [7] = Vector3.new(173.64576721191406, 34.4999885559082, 139.46446228027344),
                                    [8] = Vector3.new(150.15530395507812, 37.4999885559082, 139.02587890625)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 8 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Nordic") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(292.3473815917969, 37.4999885559082, 128.8502960205078),
                                    [2] = Vector3.new(292.2837829589844, 37.4999885559082, 103.8826904296875),
                                    [3] = Vector3.new(246.86444091796875, 34.4999885559082, 103.998046875),
                                    [4] = Vector3.new(246.81077575683594, 34.4999885559082, 82.9254379272461),
                                    [5] = Vector3.new(198.99082946777344, 34.4999885559082, 83.04700469970703),
                                    [6] = Vector3.new(200.015625, 34.4999885559082, 139.6517333984375),
                                    [7] = Vector3.new(173.64576721191406, 34.4999885559082, 139.46446228027344),
                                    [8] = Vector3.new(150.15530395507812, 37.4999885559082, 139.02587890625)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 8 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Pinewood") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(129.27752685546875, 28.4999942779541, 241.45860290527344),
                                    [2] = Vector3.new(79.45954132080078, 28.49999237060547, 240.6741943359375),
                                    [3] = Vector3.new(80.80793762207031, 28.49999237060547, 155.99095153808594),
                                    [4] = Vector3.new(91.66584777832031, 28.49999237060547, 156.12608337402344),
                                    [5] = Vector3.new(91.90682983398438, 28.49999237060547, 136.84848022460938),
                                    [6] = Vector3.new(129.66644287109375, 28.49999237060547, 137.31893920898438)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Seasonal") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(135.16567993164062, 22.4999942779541, 409.7474365234375),
                                    [2] = Vector3.new(135.17654418945312, 25.4999942779541, 380.8885803222656),
                                    [3] = Vector3.new(124.0099105834961, 25.49999237060547, 380.8028869628906),
                                    [4] = Vector3.new(124.02178955078125, 25.49999237060547, 280.3576354980469),
                                    [5] = Vector3.new(123.74276733398438, 25.49999237060547, 262.22003173828125),
                                    [6] = Vector3.new(123.6146469116211, 28.4999942779541, 253.8889617919922),
                                    [7] = Vector3.new(123.49169921875, 31.4999942779541, 245.8935546875),
                                    [8] = Vector3.new(123.3890380859375, 25.4999942779541, 169.56488037109375),
                                    [9] = Vector3.new(140.38137817382812, 25.49999237060547, 169.5316925048828)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if i == 2 or i == 6 or i == 7 then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Snowman-Park") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(140.38137817382812, 25.49999237060547, 169.5316925048828),
                                    [2] = Vector3.new(244.02467346191406, 16.4999942779541, 193.6885223388672),
                                    [3] = Vector3.new(164.97314453125, 16.49999237060547, 194.03672790527344),
                                    [4] = Vector3.new(164.86520385742188, 16.49999237060547, 169.71209716796875)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_SteamPunk") then
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(2.33)
                                local pos = {
                                    [1] = Vector3.new(459.31365966796875, 82.4999771118164, 180.3105010986328),
                                    [2] = Vector3.new(406.04095458984375, 82.4999771118164, 179.7035369873047),
                                    [3] = Vector3.new(399.0287780761719, 85.4999771118164, 179.84088134765625),
                                    [4] = Vector3.new(393.3252258300781, 88.4999771118164, 179.9452667236328),
                                    [5] = Vector3.new(370.205322265625, 91.4999771118164, 179.96041870117188),
                                    [6] = Vector3.new(371.1557312011719, 91.4999771118164, 148.01693725585938),
                                    [7] = Vector3.new(371.19158935546875, 94.4999771118164, 143.04385375976562),
                                    [8] = Vector3.new(371.111572265625, 97.4999771118164, 140.0428924560547),
                                    [9] = Vector3.new(371.05657958984375, 100.4999771118164, 137.93524169921875),
                                    [10] = Vector3.new(370.9500732421875, 103.4999771118164, 134.1337127685547),
                                    [11] = Vector3.new(370.477294921875, 106.4999771118164, 124.73361206054688),
                                    [12] = Vector3.new(335.9317321777344, 106.4999771118164, 124.79263305664062),
                                    [13] = Vector3.new(335.83599853515625, 106.4999771118164, 154.04205322265625),
                                    [14] = Vector3.new(324.33575439453125, 106.4999771118164, 154.00502014160156),
                                    [15] = Vector3.new(320.086669921875, 109.4999771118164, 153.9910888671875),
                                    [16] = Vector3.new(287.7663269042969, 91.4999771118164, 153.884765625),
                                    [17] = Vector3.new(287.6502380371094, 91.4999771118164, 181.8335723876953)
                                }

                                for i, waypoint in ipairs(pos) do
                                    vape:CreateNotification("AutoWin | Specific", "Fixing Position [" .. i .. "] !", 8)
                                    lplr.Character.Humanoid:MoveTo(waypoint)
                                    if
                                        i == 3 or i == 4 or i == 5 or i == 7 or i == 8 or i == 9 or i == 10 or i == 11 or
                                            i == 15
                                     then
                                        lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                    lplr.Character.Humanoid.MoveToFinished:Wait()
                                    task.wait(0.5)
                                end
                            elseif workspace.Map.Worlds:FindFirstChild("duels_Volatile") then
                                vape:CreateNotification("AutoWin", "Teleporting to lobby, incorrect map!", 4, "warning")
                                task.wait(2.25)
                                lobby()
                            else
                                vape:CreateNotification("AutoWin", "Moving back to Iron Gen!", 8)
                                lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                                task.wait(3)
                            end
                        end

                        if CurrentGen then
                            vape:CreateNotification("AutoWin", "Moving to Iron Gen!", 8)
                            lplr.Character.Humanoid:MoveTo(CurrentGen.Value.Position)
                            task.wait((T + 3.33))
                            vape:CreateNotification("AutoWin", "Moving to Shop!", 8)
                            lplr.Character.Humanoid:MoveTo(CurrentItemShop.Position)
                            Speed()
                            task.wait(1.5)
                            vape:CreateNotification("AutoWin", "Purchasing Wool!", 8)
                            task.wait(3)
                            for i = 6, 0, -1 do
                                PurchaseWool()
                                task.wait(0.05)
                            end
                            if oppTeamName == "Orange" then
                                MapLayoutBLUE()
                            else
                                MapLayoutORANGE()
                            end
                            vape:CreateNotification("AutoWin", "Moving to " .. oppTeamName .. "'s Bed!", 8)
                            fly()
                            climbwalls()
                            task.spawn(function()
                                lplr.Character.Humanoid:MoveTo(OppositeTeamBedPos)
                            end)
                            
                            lplr.Character.Humanoid.MoveToFinished:Connect(function()
								lplr.Character.Humanoid:MoveTo(OppositeTeamBedPos)
							end)
                        end
	end

	local function Skywars()
        local T = 10
        if #playersService:GetChildren() > 1 then
            vape:CreateNotification("AutoWin", "Teleporting to Empty Game!", 6)
            task.wait((6 / 3.335))
            local data = TeleportService:GetLocalPlayerTeleportData()
            AutoWin:Clean(TeleportService:Teleport(game.PlaceId, lplr, data))
        end
		task.wait((T + 3.33))
		local Delays = {}
		local function lootChest(chest)
            vape:CreateNotification("AutoWin", "Grabbing Items in chest", 8)
			chest = chest and chest.Value or nil
			local chestitems = chest and chest:GetChildren() or {}
			if #chestitems > 1 and (Delays[chest] or 0) < tick() then
				Delays[chest] = tick() + 0.2
				bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest)
		
				for _, v in chestitems do
					if v:IsA('Accessory') then
						task.spawn(function()
							pcall(function()
								bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
							end)
						end)
					end
				end
		
				bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(nil)
			end
		end
	
		local localPosition = entitylib.character.RootPart.Position
		local chests = collection('chest', AutoWin)
		repeat task.wait(0.1) until store.queueType ~= 'bedwars_test'
		if not store.queueType:find('skywars') then return end
		for _, v in chests do
			if (localPosition - v.Position).Magnitude <= 30 then
				vape:CreateNotification("AutoWin", "Moving to chest",2)
				entitylib.character.Humanoid:MoveTo(v.Position)
				lootChest(v:FindFirstChild('ChestFolderValue'))
			end
		end
		task.wait(4.85)
        vape:CreateNotification("AutoWin", "Resetting..", 3)
		entitylib.character.Humanoid.Health = (lplr.Character:GetAttribute("MaxHealth") - lplr.Character:GetAttribute("Health"))
		vape:CreateNotification("AutoWin", "Requeueing.", 1.85)
		AutoWin:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
				if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
					bedwars.QueueController:joinQueue(store.queueType)
				end
		end))
		AutoWin:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(...)
			bedwars.QueueController:joinQueue(store.queueType)
		end))
	end


    AutoWin = vape.Categories.Exploits:CreateModule({
        Name = "AutoWin",
        Tooltip = "Makes you go into a empty game and win!",
        Function = function(callback)
            if not callback then
           	 	vape:CreateNotification("AutoWin", "Disabled next game!", 4.5, "warning")
                return
            end
			local GameMode = readfile('mewvape/profiles/autowin.txt')
			if GameMode == "duels" then
				Duels()
			elseif GameMode == "skywars" then
				Skywars()
			else
           	 	vape:CreateNotification("AutoWin", "File does not exist? switching to use duels method!", 4.5, "warning")
                Duels()
			end
    	end
    })
end)

run(function()
	local ZephyrExploit
	local zepcontroller = require(lplr.PlayerScripts.TS.controllers.games.bedwars.kit.kits['wind-walker']['wind-walker-controller'])
	local old, old2
	ZephyrExploit = vape.Categories.Exploits:CreateModule({
		Name = 'ZephyrExploit',
		Function = function(callback)
			if callback then
				old = zepcontroller.updateSpeed
				old2 = zepcontroller.updateJump
				zepcontroller.updateSpeed = function(v1,v2) 
					v1 = {currentSpeedModifier = nil}
					v2 = 5
					return old(v1,v2)
				end
				zepcontroller.updateJump = function(v1,v2) 
					v1 = {doubleJumpActive = nil}
					v2 = 5
					return old2(v1,v2)
				end
			else
				zepcontroller.updateSpeed = old
				zepcontroller.updateJump = old2
				old = nil
				old2 = nil
			end
		end,
		Tooltip = 'Anti-Cheat Bypasser!'
	})
end)

run(function()
	local AutoShoot
	local Delay
	local Blatant
	local old
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	local projectileRemote = {InvokeServer = function() end}
	local FireDelays = {}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)
	
	
	local function getProjectiles()
		local items = {}
		for _, item in store.inventory.inventory.items do
			local proj = bedwars.ItemMeta[item.itemType].projectileSource
			local ammo = proj and getAmmo(proj)
			if ammo then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType(ammo),
					proj
				})
			end
		end
		return items
	end
	
	AutoShoot = vape.Categories.Inventory:CreateModule({
		Name = 'AutoShoot',
		Function = function(callback)
			if callback then				
				repeat
					local ent = entitylib.EntityPosition({
						Part = 'RootPart',
						Range = Blatant.Enabled and 32 or 23,
						Players = true,
						Wallcheck = true
					})
					if ent then
						local pos = entitylib.character.RootPart.Position
						for _, data in getProjectiles() do
							local item, ammo, projectile, itemMeta = unpack(data)
							if (FireDelays[item.itemType] or 0) < tick() then
								rayCheck.FilterDescendantsInstances = {workspace.Map}
								local meta = bedwars.ProjectileMeta[projectile]
								local projSpeed, gravity = meta.launchVelocity, meta.gravitationalAcceleration or 196.2
								local calc = prediction.SolveTrajectory(pos, projSpeed, gravity, ent.RootPart.Position, ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, ent.Jumping and 42.6 or nil, rayCheck)
								if calc then
									local slot = getObjSlot(projectile)
									local switched = switchHotbar(slot)
									task.spawn(function()
										local dir, id = CFrame.lookAt(pos, calc).LookVector, httpService:GenerateGUID(true)
										local shootPosition = (CFrame.new(pos, calc) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).Position
										bedwars.ProjectileController:createLocalProjectile(meta, ammo, projectile, shootPosition, id, dir * projSpeed, {drawDurationSeconds = 1})
										local res = projectileRemote:InvokeServer(item.tool, ammo, projectile, shootPosition, pos, dir * projSpeed, id, {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)
										if not res then
											FireDelays[item.itemType] = tick()
										else
											local shoot = itemMeta.launchSound
											shoot = shoot and shoot[math.random(1, #shoot)] or nil
											if shoot then
												bedwars.SoundManager:playSound(shoot)
											end
										end
									end)
									FireDelays[item.itemType] = tick() + itemMeta.fireDelaySec
									if switched then
										task.wait(0.05)
									end
								end
							end
						end
					end
					task.wait(Delay.Value / 1000)
				until not AutoShoot.Enabled
			end
		end,
		Tooltip = 'automatically\'s make you shoot all types of projectiles when near a player'
	})
	Delay = AutoShoot:CreateSlider({
		Name = "Delay",
		Min = 1,
		Max = 1000,
		Suffix = "ms",
		Default = 250,
	})
	Blatant = AutoShoot:CreateToggle({
		Name = "Blatant",
		Default = false,
	})
end)

run(function()
	local Clutch
	local UseBlacklisted_Blocks
	local blacklisted
	local Speed
	local LimitToItems
	local RequireMouse
	local SilentAim
	local lastPlace = 0
	local clutchCount = 0
	local lastResetTime = 0
	local function GetBlocks()
		if store.hand.toolType == 'block' then
			return store.hand.tool.Name, store.hand.amount
		elseif (not LimitToItems.Enabled) then
			local wool, amount = getWool()
			if wool then
				return wool, amount
			else
				for _, item in store.inventory.inventory.items do
					if bedwars.ItemMeta[item.itemType].block then
						return item.itemType, item.amount
					end
				end
			end
		end
	
		return nil, 0
	end

	local function callPlace(blockpos, block, rotate)
		task.spawn(bedwars.placeBlock, blockpos, block, rotate)
	end

	local function nearCorner(poscheck, pos)
		local startpos = poscheck - Vector3.new(3, 3, 3)
		local endpos = poscheck + Vector3.new(3, 3, 3)
		local check = poscheck + (pos - poscheck).Unit * 100
		return Vector3.new(math.clamp(check.X, startpos.X, endpos.X), math.clamp(check.Y, startpos.Y, endpos.Y), math.clamp(check.Z, startpos.Z, endpos.Z))
	end

	local function blockProximity(pos)
		local mag, returned = 60
		local tab = getBlocksInPoints(bedwars.BlockController:getBlockPosition(pos - Vector3.new(21, 21, 21)), bedwars.BlockController:getBlockPosition(pos + Vector3.new(21, 21, 21)))
		for _, v in tab do
			local blockpos = nearCorner(v, pos)
			local newmag = (pos - blockpos).Magnitude
			if newmag < mag then
				mag, returned = newmag, blockpos
			end
		end
		table.clear(tab)
		return returned
	end

	Clutch = vape.Categories.World:CreateModule({
		Name = 'Clutch',
		Function = function(callback)
			if callback then
				Clutch:Clean(runService.Heartbeat:Connect(function()
					if not entitylib.isAlive then return end
					local root = entitylib.character.RootPart
					local blocks = select(1, GetBlocks())
					if not blocks then return end
					
					if blocks and not UseBlacklisted_Blocks.Enabled then
						for i,v in blacklisted.ListEnabled do
							if blocks == v then
								return																																																																																																																																																																									
							end																																																																																																																																																																												
						end
					end
					
					if RequireMouse.Enabled and not inputService:IsMouseButtonPressed(0) then return end

					
					local vy = root.Velocity.Y
					local now = os.clock()
					
					if (now - lastResetTime) > 5 then
						clutchCount = 0
						lastResetTime = now
					end
					
					local cooldown = math.clamp(HoldBase - (Speed.Value * 0.015), 0.01, HoldBase)
					
					if vy < -6 and (now - lastPlace) > cooldown then
						local target = roundPos(root.Position - Vector3.new(0, entitylib.character.HipHeight + 4.5, 0))
						local exists, blockpos = getPlacedBlock(target)
						
						if not exists then
							local prox = blockProximity(target)
							local placePos = prox or (target * 3)
							
							callPlace(placePos, blocks, false)
							lastPlace = now
							clutchCount = clutchCount + 1
							
							
							if SilentAim.Enabled then
								local camera = workspace.CurrentCamera
								local camCFrame = camera and camera.CFrame
								local camType = camera and camera.CameraType
								local camSubject = camera and camera.CameraSubject
								local lv = root.CFrame.LookVector
								local newLook = -Vector3.new(lv.X, 0, lv.Z).Unit
								local rootPos = root.Position
								root.CFrame = CFrame.new(rootPos, rootPos + newLook)
								if camera and camCFrame then
									camera.CameraType = camType
									camera.CameraSubject = camSubject
									camera.CFrame = camCFrame
								end
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'automatically\'s places a block when falling to clutch'
	})
	UseBlacklisted_Blocks = Clutch:CreateToggle({
		Name = "Use Blacklisted Blocks",
		Default = false,
		Tooltip = "Allows clutching with blacklisted blocks"
	})
	blacklisted = Clutch:CreateTextList({
		Name = "Blacklisted Blocks",
		Placeholder = "tnt"
	})
	Speed = Clutch:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 15,
		Default = 8,
		Tooltip = 'How fast it places the blocks'
	})
	LimitToItems = Clutch:CreateToggle({
		Name = 'Limit to items',
		Default = false,
		Tooltip = "Only clutch when holding blocks"
	})
	RequireMouse = Clutch:CreateToggle({
		Name = 'Require mouse down',
		Default = false,
		Tooltip = "Only clutch when holding left click"
	})
	SilentAim = Clutch:CreateToggle({
		Name = 'SilentAim',
		Default = false,
		Tooltip = "Corrects ur position when placing blocks"
	})
end)

run(function()
	local BetterLassy
	local WallCheck
	local Distance
	local Angle
	local Delay
	local Limits
	local Sorts
	local CanLasso = true
	local projectileRemote = {InvokeServer = function() end}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)
	BetterLassy = vape.Categories.Legit:CreateModule({
		Name = 'AutoLassy',
		Tooltip = 'makes you be semi-blatant at lassy',
		Function = function(callback)
			if store.equippedKit ~= "cowgirl" then
				vape:CreateNotification("BetterLassy","Kit required only!",8,"warning")
				return
			end
			if callback then
				repeat
					local item = getItem("lasso")
					if not item then task.wait(0.1) continue end
					local plrs = entitylib.AllPosition({
						Range = Distance.Value,
						Wallcheck = WallCheck.Enabled,
						Part = "RootPart",
						Players = true,
						NPCs = false,
						Limit = 1,
						Sort = sortmethods[Sorts.Value]
					})
					local char = entitylib.character
					local root = char.RootPart
					if plrs then
						local ent = plrs[1]
						if ent and ent.RootPart then
							local delta = ent.RootPart.Position - root.Position
							local localFacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
							local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
							if angle > (math.rad(Angle.Value) / 2) then continue end
							if Limits.Enabled then
								if store.hand.toolType ~= "lasso" then
									continue
								end
							end
							if item and CanLasso then
								task.wait(1 / Delay.GetRandomValue())		
								local meta = bedwars.ProjectileMeta.lasso
								local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, ent.RootPart.Velocity, Vector3.zero, workspace.Gravity, 0, 0)
								if calc then
									local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
									bedwars.ProjectileController:createLocalProjectile(meta, 'lasso', 'lasso', pos, nil, dir, {drawDurationSeconds = 1})
									projectileRemote:InvokeServer(item.tool, 'lasso', 'lasso', pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)     
									CanLasso = false
									task.wait(1 / Delay.GetRandomValue() - math.random())
									CanLasso = true
								end
							end
						end
					end
					task.wait(0.05)
				until not BetterLassy.Enabled
			end
		end	
	})
	Distance = BetterLassy:CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 24,
		Default = 12,
		Suffix = "Studs"
	})
	Delay = BetterLassy:CreateTwoSlider({
		Name = 'Delay',
		Min = 0,
		Max = 2,
		Decimal = 10,
		Suffix = "s",
		DefaultMin = 0.2,
		DefaultMax = 1
	})
	Angle = BetterLassy:CreateSlider({
		Name = "Angle",
		Min = 1,
		Max = 360,
		Default = 120
	})
	WallCheck = BetterLassy:CreateToggle({Name='Wall Check',Default=true})
	Limits = BetterLassy:CreateToggle({Name='Limit to items',Default=true})
	Sorts = BetterLassy:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
end)

run(function()
    local VanessaCharger    
    local old
	local old2
    local lastChargeTime = 0
    
    VanessaCharger = vape.Categories.Blatant:CreateModule({
        Name = 'VanessaCharger',
        Function = function(callback)
            if callback then
				local currentTime = tick()
                old = bedwars.TripleShotProjectileController.getChargeTime
                bedwars.TripleShotProjectileController.getChargeTime = function(self)
                	local OldNow = tick()
                    local delayAmount = 0
                    if OldNow - lastChargeTime < delayAmount then
                        return oldGetChargeTime(self)
                    end
                            
                    lastChargeTime = currentTime
                    return 0
                end
				old2 = bedwars.TripleShotProjectileController.overchargeStartTime
                bedwars.TripleShotProjectileController.overchargeStartTime = tick()
            else
				bedwars.TripleShotProjectileController.overchargeStartTime = old2
                bedwars.TripleShotProjectileController.getChargeTime = old
                lastChargeTime = 0
				old = nil
				old2 = nil
            end
        end,
        Tooltip = 'Auto charges Vanessa to triple shot instantly'
    })
end)

run(function()
	local BetterMetal
	local StreamerMode
	local Delay
	local Animation
	local Distance
	local Limits
	local Legit
	BetterMetal = vape.Categories.Legit:CreateModule({
		Name = "AutoMetal",
		Tooltip = 'Automatically collects metals around you',
		Function = function(callback)
			if store.equippedKit ~= "metal_detector" then
				vape:CreateNotification("BetterMetal","Kit required only!",8,"warning")
				return
			end
			task.spawn(function()
				while BetterMetal.Enabled do
					if not entitylib.isAlive then task.wait(0.1); continue end
					local character = entitylib.character
					if not character or not character.RootPart then task.wait(0.1); continue end
					local tool = (store and store.hand and store.hand.tool) and store.hand.tool or nil
					if not tool or tool.Name ~= "metal_detector" then task.wait(0.5); continue end
					local localPos = character.RootPart.Position
					local metals = collectionService:GetTagged("hidden-metal")
					for _, obj in pairs(metals) do
						if obj:IsA("Model") and obj.PrimaryPart then
							local metalPos = obj.PrimaryPart.Position
							local distance = (localPos - metalPos).Magnitude
							local range = Legit.Enabled and 10 or (Distance.Value or 8)
							if distance <= range then
								if StreamerMode.Enabled then
									local Key = obj:FindFirstChild('hidden-metal-prompt').KeyboardKeyCode
									vim:SendKeyEvent(true, Key, false, game)
									task.wait(obj:FindFirstChild('hidden-metal-prompt').HoldDuration + math.random())
									vim:SendKeyEvent(false, Key, false, game)
								else
								local waitTime = Legit.Enabled and .854 or (1 / (Delay.GetRandomValue and Delay:GetRandomValue() or 1))
								task.wait(waitTime)
								if Legit.Enabled or Animation.Enabled then
									bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.AnimationType.SHOVEL_DIG)
									bedwars.SoundManager:playSound(bedwars.SoundList.SNAP_TRAP_CONSUME_MARK)
								end
								pcall(function()
									bedwars.Client:Get('CollectCollectableEntity'):SendToServer({id = obj:GetAttribute("Id")})
								end)
								task.wait(0.1)
								end

							end
						end
					end
					task.wait(0.1)
				end
			end)
		end
	})
	Limits = BetterMetal:CreateToggle({Name='Limit To Item',Default=false})
	StreamerMode = BetterMetal:CreateToggle({Name='Streamer Mode',Default=false})
	Distance = BetterMetal:CreateSlider({Name='Range',Min=6,Max=12,Default=8})
	Delay = BetterMetal:CreateTwoSlider({
		Name = "Delay",
		Min = 0,
		Max = 2,
		DefaultMin = 0.4,
		DefaultMax = 1,
		Suffix = 's',
        Decimal = 10,	
	})
	Animation = BetterMetal:CreateToggle({Name='Animations',Default=true})
	Legit = BetterMetal:CreateToggle({
		Name='Legit',
		Default=true,
		Darker=true,
		Function = function(v)
			Animation.Object.Visible = (not v)
			Delay.Object.Visible = (not v)
			Distance.Object.Visible = (not v)
			Limits.Object.Visible = (not v)
		end
	})
end)

run(function()
	local BetterRamil
	local Distance
	local Sorts
	local Angle
	local MaxTargets
	local Targets
	local MovingTornadoDistance
	local UseTornandos
	BetterRamil = vape.Categories.Legit:CreateModule({
		Name = "AutoRamil",
		Tooltip = 'Automatically uses Ramil\'s Tornado ability',
		Function = function(callback)
			if store.equippedKit ~= "airbender" then
				vape:CreateNotification("BetterRamil","Kit required only!",8,"warning")
				return
			end
			if callback then
				repeat
		            local plrs = entitylib.AllPosition({
		                Range = AttackRange.Value,
		                Wallcheck = Targets.Walls.Enabled,
		                Part = "RootPart",
		                Players = Targets.Players.Enabled,
		                NPCs = Targets.NPCs.Enabled,
		                Limit = MaxTargets.Value,
		                Sort = sortmethods[Sorts.Value]
		            })
					local castplrs = nil

					if UseTornandos.Enabled then
						castplrs = entitylib.AllPosition({
							Range = MovingTornadoDistance.Value,
							Wallcheck = Targets.Walls.Enabled,
							Part = "RootPart",
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sorts.Value]
		            	})
					end
		
		            local char = entitylib.character
		            local root = char.RootPart
		
		            if plrs then
		                local ent = plrs[1]
		                if ent and ent.RootPart then
		                    local delta = ent.RootPart.Position - root.Position
		                    local localFacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		                    local angle = math.acos(localFacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		                    if angle > (math.rad(Angle.Value) / 2) then continue end
							if bedwars.AbilityController:canUseAbility('airbender_tornado') then
								bedwars.AbilityController:useAbility('airbender_tornado')
							end
		                end
		            end
					if castplrs then
		                local ent = castplrs[1]
		                if ent and ent.RootPart then
							if UseTornandos.Enabled then
								if bedwars.AbilityController:canUseAbility('airbender_moving_tornado') then
									bedwars.AbilityController:useAbility('airbender_moving_tornado')
								end
							end
						end
					end
					task.wait(0.2)
				until not BetterRamil.Enabled
			end


		end
	})
	Targets = BetterRamil:CreateTargets({Players = true,NPCs = false,Walls = true})
    Angle = BetterRamil:CreateSlider({
        Name = "Angle",
        Min = 0,
        Max = 360,
        Default = 180
    })
	Sorts = BetterRamil:CreateDropdown({
		Name = "Sorts",
		List = {'Damage','Threat','Kit','Health','Angle'}
	})
	MaxTargets = BetterRamil:CreateSlider({
		Name = "Max Targets",
		Min = 1,
		Max = 3,
		Default = 2
	})
	Distance = BetterRamil:CreateSlider({
		Name = "Distance",
		Min = 1,
		Max = 25,
		Default = 18,
		Suffix = function(v)
			if v <= 1 then
				return 'stud'
			else
				return 'studs'
			end
		end
	})
	MovingTornadoDistance = BetterRamil:CreateSlider({
		Name = "Tornado Distance",
		Min = 1,
		Max = 31,
		Default = 18,
		Suffix = function(v)
			if v <= 1 then
				return 'stud'
			else
				return 'studs'
			end
		end
	})
	UseTornandos = BetterRamil:CreateToggle({Name='Use Moving Tornado\'s',Default=false,Function=function(v) MovingTornadoDistance.Object.Visible = v end})
end)

run(function()	

	NM = vape.Categories.Render:CreateModule({
		Name = 'NightmareEmote',
		Tooltip = 'Client-Sided VFX, Server-Sided Animation',
		Function = function(callback)
			if callback then				
				local CharForNM = lplr.Character
				
				if not CharForNM then return end
				
				local NightmareEmote = replicatedStorage:WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("NightmareEmote"):Clone()
				asset = NightmareEmote
				NightmareEmote.Parent = game.Workspace
				lastPosition = CharForNM.PrimaryPart and CharForNM.PrimaryPart.Position or Vector3.new()
				
				task.spawn(function()
					while asset ~= nil do
						local currentPosition = CharForNM.PrimaryPart and CharForNM.PrimaryPart.Position
						if currentPosition and (currentPosition - lastPosition).Magnitude > 0.1 then
							asset:Destroy()
							asset = nil
							NM:Toggle()
							break
						end
						lastPosition = currentPosition
						NightmareEmote:SetPrimaryPartCFrame(CharForNM.LowerTorso.CFrame + Vector3.new(0, -2, 0))
						task.wait(0.1)
					end
				end)
				
				local NMDescendants = NightmareEmote:GetDescendants()
				local function PartStuff(Prt)
					if Prt:IsA("BasePart") then
						Prt.CanCollide = false
						Prt.Anchored = true
					end
				end
				for i, v in ipairs(NMDescendants) do
					PartStuff(v, i - 1, NMDescendants)
				end
				local Outer = NightmareEmote:FindFirstChild("Outer")
				if Outer then
					tweenService:Create(Outer, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Outer.Orientation + Vector3.new(0, 360, 0)
					}):Play()
				end
				local Middle = NightmareEmote:FindFirstChild("Middle")
				if Middle then
					tweenService:Create(Middle, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Middle.Orientation + Vector3.new(0, -360, 0)
					}):Play()
				end
                anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://9191822700"
				anim = CharForNM.Humanoid:LoadAnimation(anim)
				anim:Play()
			else 
                if anim then 
					anim:Stop()
					anim = nil
				end
				if asset then
					asset:Destroy() 
					asset = nil
				end
			end
		end
	})
end)

run(function()
    local PlayerLevel
	local level 
	local old

	PlayerLevel = vape.Categories.Utility:CreateModule({
        Name = 'SetPlayerLevel',
		Tooltip = "Sets your player level to 1000 (client sided)",
        Function = function(callback)
			if callback then
				old = lplr:GetAttribute("PlayerLevel")
				lplr:SetAttribute("PlayerLevel", level.Value)
			else
				lplr:SetAttribute("PlayerLevel", old)
				old = nil
			end
		end
	})

	level = PlayerLevel:CreateSlider({
		Name = 'Player Level',
		Min = 1,
		Max = 1000,
		Default = 100,
		Function = function(val)
			if PlayerLevel.Enabled then
				lplr:SetAttribute("PlayerLevel", val)
			end
		end
	})
end)

run(function()
	local WoolChanger
	local oldTexture
	local oldColor
	local OldMaterial
	local oldColorBlock
	local oldColorBlockColor
	local oldWoolHotBar
	local color
	local Color = Color3.new(1,1,1)
	local GUIEdit 
	WoolChanger = vape.Categories.Blatant:CreateModule({
		Name = 'WoolChanger',
		Function = function(callback)
			if callback then
				local function getWorldFolder()
					local Map = workspace:WaitForChild("Map", math.huge)
					local Worlds = Map:WaitForChild("Worlds", math.huge)
					if not Worlds then return nil end

					return Worlds:GetChildren()[1] 
				end
				local worldFolder = getWorldFolder()
				if not worldFolder then return end
				local blocks = worldFolder:WaitForChild("Blocks")
				local NewMaterial = Instance.new('MaterialVariant')
				NewMaterial.Parent = cloneref(game:GetService('MaterialService'))
				NewMaterial.Name = 'rbxassetid://16991768606'
				NewMaterial.ColorMap  = 'rbxassetid://16991768606'
				NewMaterial.StudsPerTile = 3
				NewMaterial.RoughnessMap = 'rbxassetid://16991768606'
				NewMaterial.BaseMaterial = 'Fabric'
				task.spawn(function()
					if not GUIEdit.Enabled then return end
					repeat 
						for i, v in lplr.PlayerGui.hotbar:GetDescendants() do
							if v:IsA("ImageLabel") then
								if v.Name == "1" then
									if v.Image == "rbxassetid://7923577182" or v.Image == "rbxassetid://7923577311" or v.Image == "rbxassetid://7923578297" or v.Image == "rbxassetid://7923578297" or v.Image == "rbxassetid://6765309820" or v.Image == "rbxassetid://7923579098" or v.Image == "rbxassetid://7923577655" or v.Image == "rbxassetid://7923579263" or v.Image == "rbxassetid://7923579520" or v.Image == "rbxassetid://7923578762" or v.Image == "rbxassetid://7923578533" or v.Image == "rbxassetid://15380238075" then
										oldColorBlock = v.Image
										oldColorBlockColor = v.ImageColor3
										v.Image = "rbxassetid://7923579263"
										v.ImageColor3 = Color
									end
								end
							end
						end
						task.wait(0.01)
					until not WoolChanger.Enabled or not GUIEdit.Enabled
				end)
				WoolChanger:Clean(gameCamera:FindFirstChild("Viewmodel").ChildAdded:Connect(function(obj)
					if string.find(obj.Name, "wool") then
						for i, texture in obj:FindFirstChild('Handle'):GetChildren() do
							if texture:IsA('Texture') then
								oldTexture = texture.Texture
								texture.Texture = "rbxassetid://16991768606"
								oldColor = texture.Color3
								texture.Color3 = Color
							end
						end
					end
				end))
				WoolChanger:Clean(blocks.ChildAdded:Connect(function(obj)
					if string.find(obj.Name, "wool") then
						if obj:GetAttribute("PlacedByUserId") == lplr.UserId then
							OldMaterial = obj.MaterialVariant
							oldColorBlock = obj.Color
							obj.MaterialVariant = "rbxassetid://16991768606"
							obj.Color = Color
						end
					end
				end))
				WoolChanger:Clean(workspace.ChildAdded:Connect(function(obj)
					if string.find(obj.Name, "wool") then
						if obj:GetAttribute("PlacedByUserId") == lplr.UserId then
							OldMaterial = obj.MaterialVariant
							oldColorBlock = obj.Color
							obj.MaterialVariant = "rbxassetid://16991768606"
							obj.Color = Color
						end
					end
				end))
				WoolChanger:Clean(lplr.Character.ChildAdded:Connect(function(obj)
					if string.find(obj.Name, "wool") then
						for i, texture in obj:FindFirstChild('Handle'):GetChildren() do
							if texture:IsA('Texture') then
								oldTexture = texture.Texture
								texture.Texture = "rbxassetid://16991768606"
								oldColor = texture.Color3
								texture.Color3 = Color
							end
						end
					end
				end))
            else
				for i, v in lplr.PlayerGui.hotbar:GetDescendants() do
					if v:IsA("ImageLabel") then
						if v.Name == "1" then
							if v.Image == "rbxassetid://7923579263" then
								v.Image = oldColorBlock
								v.ImageColor3 = oldColorBlockColor
								oldColorBlock = nil
								oldColorBlockColor = nil
							end
						end
					end
				end
				for i, obj in workspace:GetDescendants() do
					if string.find(obj.Name, "wool") then
						if obj:GetAttribute("PlacedByUserId") == lplr.UserId then
							obj.MaterialVariant = OldMaterial
							obj.Color = oldColorBlock
							OldMaterial = nil
							oldColor = nil
						end
					end
				end
			end
		end,
		Tooltip = 'Changes your blocks from a custom color(client only)'
	})
	color = WoolChanger:CreateColorSlider({
		Name = "Wool Color",
		Function = function(hue,sat,val)
			if WoolChanger.Enabled then
				local v1 = Color3.fromHSV(hue,sat,val)
				local R = math.floor(v1.R * 255)
				local G = math.floor(v1.G * 255)
				local B = math.floor(v1.B * 255)
				Color = Color3.fromRGB(R,G,B)
			end
		end
	})
	GUIEdit = WoolChanger:CreateToggle({
		Name = "Hotbar Edit",
		Tooltip = 'changer effects the hotbar lol',
		Default = false,
		Function = function(v)
			repeat 
				for i, v in lplr.PlayerGui.hotbar:GetDescendants() do
					if v:IsA("ImageLabel") then
						if v.Name == "1" then
							if v.Image == "rbxassetid://7923577182" or v.Image == "rbxassetid://7923577311" or v.Image == "rbxassetid://7923578297" or v.Image == "rbxassetid://7923578297" or v.Image == "rbxassetid://6765309820" or v.Image == "rbxassetid://7923579098" or v.Image == "rbxassetid://7923577655" or v.Image == "rbxassetid://7923579263" or v.Image == "rbxassetid://7923579520" or v.Image == "rbxassetid://7923578762" or v.Image == "rbxassetid://7923578533" or v.Image == "rbxassetid://15380238075" then
								oldColorBlock = v.Image
								oldColorBlockColor = v.ImageColor3
								v.Image = "rbxassetid://7923579263"
								v.ImageColor3 = Color
							end
						end
					end
				end
				task.wait(0.01)
			until not WoolChanger.Enabled or not v
		end
	})
end)

run(function()
	local RS 
	RS = vape.Categories.Utility:CreateModule({
		Name = "Stream Remover",
		Tooltip = 'this is client only, disables everyones streamer mode',
		Function = function(callback)
			if callback then
	
				old = bedwars.GamePlayer.canSeeThroughDisguise
				bedwars.GamePlayer.canSeeThroughDisguise = function()
					return true
				end
			else
				bedwars.GamePlayer.canSeeThroughDisguise = old
				old = nil	
			end
		end
	})
end)

run(function()
	local DinoTamerExploit
	DinoTamerExploit = vape.Categories.Exploits:CreateModule({
		Name = "DinoTamerExploit",
		Function = function(callback) 	
			if callback then
				repeat
					bedwars.Client:Get("ConsumeItem"):SendToServer({item=replicatedStorage.Inventories[lplr.Name].dino_deploy})
					replicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.Dismount:FireServer()
					task.wait()
				until not DinoTamerExploit.Enabled
			else
				warn('disabled')
			end
		end
	})
end)

run(function()
	local BetterUma
	local Range
	local AutoSummon
	local UHS
	local UAS 
	local Target
	local Em
	local Dim
	local Delay
	local projectileRemote = nil
	task.spawn(function()
		local s, err = pcall(function()
			projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
		end)
		if not s or err then
			projectileRemote = {InvokeServer = function() end}
			warn(err)
		end
	end)
	local function FindDimGen(origin)
		local obj, velo
		for i, dims in workspace.ItemDrops:GetChildren() do
			if dims:IsA("BasePart") then
				if dims.Name == "diamond" then
					local d = (dims.Position - origin).Magnitude
					if Range.Value <= d then
						obj = dims
						velo = obj.AssemblyLinearVelocity.Magnitude
					end
				end
			end
		end
		return obj, velo
	end
	local function FindEmGen(origin)
		local obj, velo
		for i, ems in workspace.ItemDrops:GetChildren() do
			if ems:IsA("BasePart") then
				if ems.Name == "emerald" then
					local d = (ems.Position - origin).Magnitude
					if Range.Value <= d then
						obj = ems
						velo = obj.AssemblyLinearVelocity.Magnitude
					end
				end
			end
		end
		return obj,velo
	end
	local Meta = ""
	local CanShoot = true
	BetterUma = vape.Categories.Legit:CreateModule({
		Name = "AutoUma",
		Tooltip = 'Autouma by shooting spirits at emeralds and diamonds',
		Function = function(callback)
			if callback then
				if store.equippedKit ~= "spirit_summoner" then
					vape:CreateNotification("BetterUma","Kit required only!",8,"warning")
					return
				end
				repeat
						if AutoSummon.Enabled then
							local stone = getItem("summon_stone")
							if stone then
								if UHS.Enabled and bedwars.AbilityController:canUseAbility("summon_heal_spirit") then
									bedwars.AbilityController:useAbility("summon_heal_spirit")
								end
								if UAS.Enabled and bedwars.AbilityController:canUseAbility("summon_attack_spirit") then
									bedwars.AbilityController:useAbility("summon_attack_spirit")
								end
								if UHS.Enabled and UAS.Enabled then
									local heal = lplr:GetAttribute("ReadySummonedHealSpirits") or 0
									local atk  = lplr:GetAttribute("ReadySummonedAttackSpirits") or 0

									if heal ~= atk and bedwars.AbilityController:canUseAbility("change_spirit_affinity") then
										bedwars.AbilityController:useAbility("change_spirit_affinity")
									end
								end
							else
								task.wait(0.1)
								continue
							end
						end
						if Target.Enabled then
							if Em.Enabled then
								local pos,spot = FindEmGen(entitylib.character.RootPart.Position)
								if pos and CanShoot then
									CanShoot = false
									local staff = getItem("spirit_staff")
									if  not staff then task.wait(0.1) continue end
									if lplr:GetAttribute("ReadySummonedHealSpirits") > lplr:GetAttribute("ReadySummonedAttackSpirits") then
										Meta = "heal_spirit"
									else
										Meta = "attack_spirit"
									end
									local meta = bedwars.ProjectileMeta[Meta]
									local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
									if calc then
										local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
										bedwars.ProjectileController:createLocalProjectile(meta, Meta, Meta, pos, nil, dir, {drawDurationSeconds = 0})
										projectileRemote:InvokeServer(staff.tool, Meta, Meta, pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 0, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)     
										task.wait(1 / Delay.GetRandomValue() + math.random())
										CanShoot = true
									end
								else
									task.wait(0.1)
									continue
								end
							end
							if Dim.Enabled then
								local pos,spot = FindDimGen(entitylib.character.RootPart.Position)
								if pos and CanShoot then
									CanShoot = false
									local staff = getItem("spirit_staff")
									if  not staff then task.wait(0.1) continue end
									if lplr:GetAttribute("ReadySummonedHealSpirits") > lplr:GetAttribute("ReadySummonedAttackSpirits") then
										Meta = "heal_spirit"
									else
										Meta = "attack_spirit"
									end
									local meta = bedwars.ProjectileMeta[Meta]
									local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
									if calc then
										
										local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
										bedwars.ProjectileController:createLocalProjectile(meta, Meta, Meta, pos, nil, dir, {drawDurationSeconds = 0})
										projectileRemote:InvokeServer(staff.tool, Meta, Meta, pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 0, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)     
										task.wait(1 / Delay.GetRandomValue() + math.random())
										CanShoot = true
									end
								else
									task.wait(0.1)
									continue
								end
							end
						end
					task.wait(1 / Delay.GetRandomValue())
				until not BetterUma.Enabled
			end
		end
	})
	Range = BetterUma:CreateSlider({
		Name = "Range",
		Min = 1,
		Max = 80,
		Default = 45,
		Suffix = function(val)
			if val >= 1 then
				return "studs"
			else
				return "stud"
			end
		end
	})
	Delay = BetterUma:CreateTwoSlider({
		Name = "Delay",
		Min = 0.1,
		Max = 2,
		DefaultMin = 0.5,
		DefaultMax = 2
	})
	UHS = BetterUma:CreateToggle({
		Name = "Use heal spirit",
		Default = true,
		Visible = false,
		Darker=true
	})
	UAS = BetterUma:CreateToggle({
		Name = "Use attack spirit",
		Default = true,
		Visible = false,
		Darker=true
	})
	AutoSummon = BetterUma:CreateToggle({
		Name='Auto Summon',
		Default=true,
		Function=function(v)
			UHS.Object.Visible=v
			UAS.Object.Visible=v
		end
	})
	Em = BetterUma:CreateToggle({
		Name = "Emerald",
		Default = true,
		Visible = false,
		Darker=true
	})
	Dim = BetterUma:CreateToggle({
		Name = "Diamond",
		Default = true,
		Visible = false,
		Darker=true
	})
	Target = BetterUma:CreateToggle({
		Name='Target item drops',
		Default=true,
		Function=function(v)
			Em.Object.Visible=v
			Dim.Object.Visible=v
		end
	})
end)

run(function() 
    local MatchHistory
    
    MatchHistory = vape.Categories.Exploits:CreateModule({
        Name = "MatchHistoryReset",
        Tooltip = "Resets your match history",
        Function = function(callback)
            if callback then 
                MatchHistory:Toggle(false)
                local TeleportService = game:GetService("TeleportService")
                local data = TeleportService:GetLocalPlayerTeleportData()
                MatchHistory:Clean(TeleportService:Teleport(game.PlaceId, lplr, data))
            end
        end,
    }) 
end)
