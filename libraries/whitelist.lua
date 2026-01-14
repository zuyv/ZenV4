return function()
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
local textChatService = cloneref(game:GetService('TextChatService'))
local httpService = cloneref(game:GetService('HttpService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local lplr = cloneref(playersService.LocalPlayer)
local vape = shared.vape
local hash = loadstring(downloadFile('newvape/libraries/hash.lua'), 'hash')()
local whitelists = {'28c05066ce60a1761f316af3b7cebc974d834e63ff27710860e13c1551f0a305604bcdd609b6587bddaf17ea499c5f178378f729cd1406ff3cd0c4ead8906bda'}
local users = {}
local perms = {}
local function checkwhitelist(str, plr)
	str = str or (plr.Name..tostring(plr.UserId))
	local newhash = hash.sha512(str..'SelfReport')
	if newhash then
		for _, v in whitelists do
			if v == newhash then
				perms[plr] = true
				return true
			end
		end
	end

	perms[plr] = false
	return false
end
local localWhitelisted = false
local detected = {}
task.spawn(function()
	localWhitelisted = checkwhitelist(lplr.Name .. tostring(lplr.UserId), lplr)
end)

local function notifyOnyxUser(plr)
	if detected[plr.UserId] then return end
	detected[plr.UserId] = true
	vape:CreateNotification('Relic',plr.Name.." is using relic!",10,'alert')
end

task.spawn(function()
	if not localWhitelisted then return end
	for _, plr in playersService:GetPlayers() do
		if plr ~= lplr and checkwhitelist(plr.Name .. tostring(plr.UserId), plr) then
			notifyOnyxUser(plr)
            table.insert(users,plr)
            local oldinjection = vape.Uninject
            vape.Uninject = function()
                vape:CreateNotification("Relic","You cant hide from whitelisted users :P",8,"warning")
                return
            end
		end
	end
end)

vape:Clean(playersService.PlayerAdded:Connect(function(plr)
	if not localWhitelisted then return end
	if plr == lplr then return end
	task.spawn(function()
		plr.CharacterAdded:Wait()
		if checkwhitelist(plr.Name .. tostring(plr.UserId), plr) then
			notifyOnyxUser(plr)
            table.insert(users,plr)
            local oldinjection = vape.Uninject
            vape.Uninject = function()
                vape:CreateNotification("Relic","You cant hide from whitelisted users :P",8,"warning")
                return
            end
		end
	end)
end))

task.spawn(function()
	local isWhitelisted = checkwhitelist(lplr.Name .. tostring(lplr.UserId), lplr)
	if isWhitelisted then
        vape:CreateNotification("Relic","You are currently whitelisted :D",8)
        print('debug whitelist for now adding kick commands and allat later')
	end
end)
end