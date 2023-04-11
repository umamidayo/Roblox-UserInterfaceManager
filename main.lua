repeat task.wait() until game:IsLoaded()

local player = game.Players.LocalPlayer
local gui = script.Parent

-- Services

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Pathing

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Tween Info

local statsGlow = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- Server Info Data

local serverInfo = ReplicatedStorage:WaitForChild("ServerInfo")
local region = serverInfo:WaitForChild("Region")
local country = serverInfo:WaitForChild("Country")
local serverinfoGui = gui:WaitForChild("ServerInfo")
local playerinfoGui = gui:WaitForChild("PlayerInfo")
local soundFX = SoundService:WaitForChild("SoundFX")

-- Player Info Data

local playTime = player:WaitForChild("PlayTime")
local money = player:WaitForChild("Money")
local xp = player:WaitForChild("XP")
local lastMoney = nil

-- Initialize player information + functions

function Format(Int)
	return string.format("%02i", Int)
end

function convertToHMS(Minutes)
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours) .. ":" .. Format(Minutes) .. ":" .. "00"
end

function Initialize()
	serverinfoGui.Location.Text = "SERVER LOCATION: " .. string.upper(region.Value) .. ", " .. string.upper(country.Value)
	serverinfoGui.WorldTime.Text = "WORLD TIME: " .. game.Lighting.TimeOfDay
	serverinfoGui.PlayTime.Text = "PLAY TIME: " .. convertToHMS(playTime.Value)
	playerinfoGui.Money.Text = "$" .. money.Value .. ".00"
	playerinfoGui.XP.Text = xp.Value .. " XP"
	lastMoney = money.Value
	
	game.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		serverinfoGui.WorldTime.Text = "WORLD TIME: " .. game.Lighting.TimeOfDay
	end)

	playTime.Changed:Connect(function()
		serverinfoGui.PlayTime.Text = "PLAY TIME: " .. convertToHMS(playTime.Value)
	end)
	
	money.Changed:Connect(function()
		soundFX.Money:Play()
		playerinfoGui.Money.Text = "$" .. money.Value .. ".00"
		
		if money.Value >= lastMoney then
			local tween = TweenService:Create(playerinfoGui.Money, statsGlow, {TextColor3 = Color3.fromRGB(73, 255, 70)})
			tween:Play()
			tween.Completed:Wait()
			TweenService:Create(playerinfoGui.Money, statsGlow, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		else
			local tween = TweenService:Create(playerinfoGui.Money, statsGlow, {TextColor3 = Color3.fromRGB(255, 21, 21)})
			tween:Play()
			tween.Completed:Wait()
			TweenService:Create(playerinfoGui.Money, statsGlow, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end
		
		lastMoney = money.Value

	end)
	
	xp.Changed:Connect(function()
		playerinfoGui.XP.Text = xp.Value .. " XP"
		local tween = TweenService:Create(playerinfoGui.XP, statsGlow, {TextColor3 = Color3.fromRGB(32, 166, 255)})
		tween:Play()
		tween.Completed:Wait()
		TweenService:Create(playerinfoGui.XP, statsGlow, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
end

Initialize()

-- Spawn Disclaimer

local spawnEvent = Remotes:WaitForChild("SpawnDisclaimer")
local spawnDisclaimerFX = Lighting:WaitForChild("SpawnDisclaimer")
local spawnDisclaimer = gui.SpawnDisclaimer
local appearTime = 0
local active = false

function timerCountDown(timer)
	repeat
		spawnDisclaimer.Visible = true
		appearTime -= 1
		task.wait(1)
	until appearTime <= 0
	spawnDisclaimerFX.Enabled = false
	spawnDisclaimer.Visible = false
	active = false
end

spawnEvent.OnClientEvent:Connect(function(timer)
	appearTime += 1.2
	
	spawnDisclaimerFX.Enabled = true
	spawnDisclaimer.Disclaimer.Text = "YOU ARE IN A RESTRICTED AREA, LEAVE IN " .. timer .. " SECONDS OR BE KICKED."
	
	if active == true then return end
	active = true
	timerCountDown(timer)
end)

-- Flag Captures

local flagEvent = Remotes:WaitForChild("FlagEvent")
local flagFrame = script.Parent.FlagFrame
local flagText = script.FlagText
local flagSoundFX = game:WaitForChild("SoundService"):WaitForChild("SoundFX"):WaitForChild("RadioSquelch")

flagEvent.OnClientEvent:Connect(function(team, area)
	local message = string.upper(team .. " have captured " .. area)
	local newFlagText = flagText:Clone()
	newFlagText.Parent = flagFrame
	flagSoundFX:Play()
	for i = 1, #message do
		newFlagText.Text = string.sub(message, 1, i)
		task.wait(0.025)
	end
	Debris:AddItem(newFlagText, 10)
end)

-- NPC Dialogues

local NPCStorage = game:GetService("ReplicatedStorage"):WaitForChild("NPCStorage")
local Dialogues = NPCStorage:WaitForChild("Dialogues")

local DialogueModule = nil
local NPCFrame = script.Parent.NPCFrame
local Buttons = {
	NPCFrame.Choices.Choice1,
	NPCFrame.Choices.Choice2,
	NPCFrame.Choices.Choice3,
	NPCFrame.Choices.Choice4
}

local TargetNPC = nil

local UpdateDialog = function(DialogueData)
	DialogueModule.Topic = DialogueData.Topic
	NPCFrame.Dialogue.Text = DialogueModule[DialogueModule.Topic].Dialogue
	
	if DialogueModule[DialogueModule.Topic]["Function"] then
		DialogueModule[DialogueModule.Topic]["Function"]()
	end
	
	if #DialogueModule[DialogueModule.Topic].Choices > 0 then
		for i,button:TextButton in pairs(Buttons) do
			if DialogueModule[DialogueModule.Topic].Choices[i] then
				button.Text = DialogueModule[DialogueModule.Topic].Choices[i]
				button.Visible = true
			else
				button.Visible = false
			end
		end
	else
		for i,button:TextButton in pairs(Buttons) do
			button.Visible = false
		end
		
		task.wait(string.len(NPCFrame.Dialogue.Text) / 10)
		NPCFrame.Visible = false
		
		if TargetNPC then
			TargetNPC.HumanoidRootPart.ProximityPrompt.Enabled = true
			TargetNPC = nil
		end
	end
end

for index,button:TextButton in pairs(Buttons) do
	button.MouseButton1Click:Connect(function()
		if not TargetNPC then return end
		local DialogueData = DialogueModule.PathChoice(index)
		UpdateDialog(DialogueData)
	end)
end

-- Since the game takes time to load the NPCs, we need to implement a wait for them to load.

repeat 
	task.wait()
until #workspace:WaitForChild("NPCs"):GetChildren() > 0

for _,NPC:Model in pairs(workspace:WaitForChild("NPCs"):GetChildren()) do
	NPC.HumanoidRootPart.ProximityPrompt.Triggered:Connect(function()
		NPC.HumanoidRootPart.ProximityPrompt.Enabled = false
		DialogueModule = require(Dialogues[NPC.Name])
		
		DialogueModule.Topic = DialogueModule["Intro"].Topic
		TargetNPC = NPC
		NPCFrame.NPCName.Text = NPC.Name
		NPCFrame.Visible = true
		
		UpdateDialog(DialogueModule["Intro"])
		
		while true do
			if (player.Character.PrimaryPart.Position - NPC.PrimaryPart.Position).Magnitude > 12 then
				NPCFrame.Visible = false
				TargetNPC.HumanoidRootPart.ProximityPrompt.Enabled = true
				TargetNPC = nil
				break
			end
			
			task.wait(1)
		end
	end)
end

-- Missions: Helps the players know where to go and what to do.

local MissionFrame = script.Parent.MissionFrame
local MissionData = nil

Remotes.Mission.OnClientEvent:Connect(function(EventType:string, NewMissionData)
	MissionData = NewMissionData
	
	if EventType == "NewMissionData" then
		if MissionData.Type == "Raid" then
			MissionFrame.Header.Text = "RAID MISSION OBJECTIVE"
			MissionFrame.Body.Text = "Go to the mission location: " .. MissionData.Location
			MissionFrame.Visible = true
		elseif MissionData.Type == "Convoy" then
			if MissionData.Step == 1 then
				MissionFrame.Header.Text = "CONVOY MISSION OBJECTIVE"
				MissionFrame.Body.Text = "Go to the base warehouse to pick up the supplies"
				MissionFrame.Visible = true
			end
		end
	elseif EventType == "Update" then
		if MissionData.Type == "Raid" then
			MissionFrame.Header.Text = "RAID MISSION OBJECTIVE"
			MissionFrame.Body.Text = "Eliminate hostiles: " .. MissionData.Enemies .. " left"
			MissionFrame.Visible = true
		elseif MissionData.Type == "Convoy" then
			if MissionData.Step == 2 then
				MissionFrame.Header.Text = "CONVOY MISSION OBJECTIVE"
				MissionFrame.Body.Text = "Deliver the following supplies to " .. MissionData.Location .. ": " .. MissionData.Cargo.Ammo .. " ammo box, " .. MissionData.Cargo.Supply .. " supply box, " .. MissionData.Cargo.Food .. " food box."
				MissionFrame.Visible = true
			elseif MissionData.Step == 3 then
				MissionFrame.Header.Text = "CONVOY MISSION OBJECTIVE"
				MissionFrame.Body.Text = "Drop off the supplies in the drop off zone."
				MissionFrame.Visible = true
			end
		end
	elseif EventType == "Complete" then
		MissionFrame.Header.Text = "COMPLETED MISSION"
		MissionFrame.Body.Text = "Good work operator! You've been rewarded " .. MissionData.Reward.XP .. " EXP and $" .. MissionData.Reward.Cash
		MissionFrame.Visible = true
		task.wait(10)
		MissionFrame.Visible = false
	elseif EventType == "Abandon" then
		MissionFrame.Header.Text = "MISSION ABANDONED"
		MissionFrame.Body.Text = "Your mission has been cancelled without penalty"
		MissionFrame.Visible = true
		task.wait(10)
		MissionFrame.Visible = false
	end
end)
