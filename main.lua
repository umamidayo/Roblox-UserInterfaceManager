-- Anything that's obvious to highly skilled scripters will not be commented, as it's expected to know what a service or variable does; based on their names
-- This is a client-sided script that handles events sent by the server, as well as connecting any player data changes to the user interface.

-- Forcing the script to wait until the client is ready
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

-- Formatting the the passed number value to decimal form by using string.format keywords
function Format(Int)
	return string.format("%02i", Int)
end

-- Converts the minutes given to hours and formats it corresponding to time
function convertToHMS(Minutes)
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours) .. ":" .. Format(Minutes) .. ":" .. "00"
end

-- This function sets up the client user interface and makes connections to the player's data, such as money and experience points
function Initialize()
	serverinfoGui.Location.Text = "SERVER LOCATION: " .. string.upper(region.Value) .. ", " .. string.upper(country.Value)
	serverinfoGui.WorldTime.Text = "WORLD TIME: " .. game.Lighting.TimeOfDay
	serverinfoGui.PlayTime.Text = "PLAY TIME: " .. convertToHMS(playTime.Value)
	playerinfoGui.Money.Text = "$" .. money.Value .. ".00"
	playerinfoGui.XP.Text = xp.Value .. " XP"
	lastMoney = money.Value
	
	-- Displays the world time in the game
	game.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		serverinfoGui.WorldTime.Text = "WORLD TIME: " .. game.Lighting.TimeOfDay
	end)

	-- Displays how long the player has played in the game
	playTime.Changed:Connect(function()
		serverinfoGui.PlayTime.Text = "PLAY TIME: " .. convertToHMS(playTime.Value)
	end)
	
	money.Changed:Connect(function()
		soundFX.Money:Play()
		playerinfoGui.Money.Text = "$" .. money.Value .. ".00"
		
		-- If statement to display and animate the color based on gain / loss difference
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
	
	-- Displays XP animation and value
	xp.Changed:Connect(function()
		playerinfoGui.XP.Text = xp.Value .. " XP"
		local tween = TweenService:Create(playerinfoGui.XP, statsGlow, {TextColor3 = Color3.fromRGB(32, 166, 255)})
		tween:Play()
		tween.Completed:Wait()
		TweenService:Create(playerinfoGui.XP, statsGlow, {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
end

-- Once the player is loaded and the previous code is available, it will run the initialization
Initialize()

-- Spawn Disclaimer

local spawnEvent = Remotes:WaitForChild("SpawnDisclaimer")
local spawnDisclaimerFX = Lighting:WaitForChild("SpawnDisclaimer")
local spawnDisclaimer = gui.SpawnDisclaimer
local appearTime = 0
local active = false

-- Shows the user interface of the spawn protection
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

-- Spawn protection event, timer variable changes based on the time that they spent in the enemy spawn zone
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

-- Displays the team that captured a specific area, passed by the remote event
flagEvent.OnClientEvent:Connect(function(team, area)
	local message = string.upper(team .. " have captured " .. area)
	local newFlagText = flagText:Clone()
	newFlagText.Parent = flagFrame
	flagSoundFX:Play()
	-- Typewriter effect
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

-- A function that directs the pathing of the dialogue based on the player's interaction with said NPC
local UpdateDialog = function(DialogueData)
	-- Updates the dialogue text
	DialogueModule.Topic = DialogueData.Topic
	NPCFrame.Dialogue.Text = DialogueModule[DialogueModule.Topic].Dialogue
	
	-- If there's a function connected to the specific module variable, then it'll run it
	if DialogueModule[DialogueModule.Topic]["Function"] then
		DialogueModule[DialogueModule.Topic]["Function"]()
	end
	
	-- If there's dialogue from the module, it will populate the choices, otherwise keep them hidden
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
		-- When dialogue finishes or there's no more dialogue, it will clean up and exit the dialogue for the player
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

-- This collects all of the buttons and connects them to the dialog module
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

-- Collects all of the NPCs in the game and connects the corresponding module from ReplicatedStorage to them
for _,NPC:Model in pairs(workspace:WaitForChild("NPCs"):GetChildren()) do
	NPC.HumanoidRootPart.ProximityPrompt.Triggered:Connect(function()
		NPC.HumanoidRootPart.ProximityPrompt.Enabled = false
		DialogueModule = require(Dialogues[NPC.Name])
		
		-- On initial conversation, it will automatically route to the introduction of the dialogue
		DialogueModule.Topic = DialogueModule["Intro"].Topic
		TargetNPC = NPC
		NPCFrame.NPCName.Text = NPC.Name
		NPCFrame.Visible = true
		
		-- Updates the dialogue and connects the choices to the dialogue module
		UpdateDialog(DialogueModule["Intro"])
		
		-- This makes sure that the dialogue closes when the player walks away
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

-- Missions: Helps the players know where to go and what to do

local MissionFrame = script.Parent.MissionFrame
local MissionData = nil

Remotes.Mission.OnClientEvent:Connect(function(EventType:string, NewMissionData)
	-- We cache the new mission data, which consists of a table of values
	MissionData = NewMissionData
	
	-- EventType is a string that routes the connection to perform different functions
	-- I'm not going to explain each individual statement, but basically it updates the header and body text of the user interface for the player
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

-- If you need more comments from me to prove that I made this code and understand it, then you're being ridiculous.
-- It shouldn't be confusing to understand how client user interface scripts work.
