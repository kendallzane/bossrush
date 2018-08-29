--[[
	If you tried to make a script that allows your player to midair jump using
	the tutorial found here (as of 8/29/2018):
	
	http://wiki.roblox.com/index.php?title=User:Memory_Address/DoubleJump
	
	It wouldn't work, for three reasons: one, it doesn't respect FilteringEnabled,
	two, Roblox player physics have updated so that setting a character's
	velocity directly won't work (since the client has control over it's own
	character), and three, R15 characters don't have a "Torso" exactly.
	
	So, this is an updated version of the script that works in the modern era.
	
	I am a noob programmer so this probably isn't perfect code, but it should 
	be easy enough to read/modify.		
--]]

if (script.Parent.Name ~= "PlayerScripts") then
	warn("Midair Jump Script (client side) is in the wrong place! Put it in StarterPlayer.StarterPlayerScripts");
else
	print("VivianConquest's Midair Jump Script (client side) loaded!")
end

--[[
	First, simply get our character and humanoid.
--]]

local localPlayer = game:GetService("Players").LocalPlayer;
local character;
local humanoid;

local function characterAdded(char)
	
	character = char;
	humanoid = char:WaitForChild("Humanoid");
	
end

if localPlayer.Character then
	characterAdded(localPlayer.Character);
end
 
localPlayer.CharacterAdded:connect(characterAdded);

--[[
	Here we set up the RemoveEvents that make this script work.
	
	JumpRequest: 		What we send to the server. We perform a check
						to see if they should midair jump, but the server
						is the main one doing the sanity checking.
	
	JumpAnimRequest:	Simply, when a character does a midair jump, the
						server asks to change our humanoid state so that
						it does the character's jumping animation. That can 
						only be done locally.
	
	JumpEffectRequest:	Here the server asks us to create the visual for the
						midair jumps. Doing this on the server side would
						have the effect not be consistent with the player's
						position. 
						
						This fires to ALL clients, so all effects are drawn
						client side for all players. By default, this only
						happens if the player is in close range to the player
						who is midair jumping.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage");

local JumpRequest = ReplicatedStorage:WaitForChild("JumpRequest");
local JumpAnimRequest = ReplicatedStorage:WaitForChild("JumpAnimRequest");
local JumpEffectRequest = ReplicatedStorage:WaitForChild("JumpEffectRequest");

--[[
	Here we use UserInputService, which fires whenever the player requests to
	jump. If the proper conditions are met for a midair jump, we ask the 
	server to do that for us.
--]]

local UserInputService = game:GetService("UserInputService");
local stats = localPlayer:WaitForChild("Stats");
local debounce = stats:WaitForChild("JumpDebounce");
local jumpsLeft = stats:WaitForChild("JumpsLeft");

UserInputService.JumpRequest:connect(function()
	
	if not character or not humanoid then return; end
	
	if (humanoid:GetState() ~= Enum.HumanoidStateType.Freefall) then return; end
	
	if (debounce.Value == true) then return; end
	
	if (jumpsLeft.Value ~= 0) then
		JumpRequest:FireServer();
	end;
	
end)

--[[
	Here we change our Humanoid State to jumping when the server requests us to.
	This is the simplest way to get the default animation script to player the
	player's jumping animation.
--]]

local function onJumpAnimRequest()
	
	if not character or not humanoid then return; end
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
	
end

JumpAnimRequest.OnClientEvent:Connect(onJumpAnimRequest);

--[[
	The jump effect is this: a decal on a completely transparent, non-collidable,
	anchored part. Over the course of 0.4 seconds, the part increases in size, 
	and the decal becomes transparent.
	
	We use TweenService to tween these properties of the part and decal, so the
	animation is smooth.
	
	The effect in question is clone from the part that is the child of this script.
	
	If you don't want the jump effect to play, then you can change that with a 
	variable in the server script.
--]]

local TweenService = game:GetService("TweenService");

local brickGoal = {};
brickGoal.Size = Vector3.new(6, 0.05, 6);

local decalGoal = {};
decalGoal.Transparency = 1;

local tweenInfo = TweenInfo.new(0.4);

local function onJumpEffectRequest(player)
	
	--[[
		Here we decide whether or not to create the effect.
		
		If the player doing a midair jump isn't us, and is farther than 100 units
		away from us, we won't create the effect. You can tweak this if you want.
	--]]
	
	if (player ~= localPlayer) then
		local distance = getDistanceBetweenPlayers(player, localPlayer);
		print("Distance between " .. localPlayer.Name .. " and " .. player.Name .. ": " .. distance);
		if (distance == nil or distance > 100) then
			return;
		end
	end
	
	--[[
		Now we simply create the effect, and turn the tweens on so it animates.
	--]]
	
	local character = player.Character;
	local position = character.HumanoidRootPart.Position + Vector3.new(0, -2, 0);
	
	local effectPart = script.Effect:Clone();
			
			
	local tween = TweenService:Create(effectPart, tweenInfo, brickGoal);
	tween:play();
	tween = TweenService:Create(effectPart.DecalTop, tweenInfo, decalGoal);
	tween:play();
	tween = TweenService:Create(effectPart.DecalBottom, tweenInfo, decalGoal);
	tween:play();
	effectPart.Position = position;
	effectPart.Parent = workspace;
			
	--[[
		Here we make it so the effect is destroyed after 0.4 seconds, which is how
		long it takes for it to tween to complete transparency.
	--]]
			
	game:GetService("Debris"):AddItem(effectPart, 0.4);
	
end

JumpEffectRequest.OnClientEvent:Connect(onJumpEffectRequest);

	--[[
		This is the function used to calculate if the player is close enough for
		us to draw the jumping effect. This would go well in a module script.
	--]]

function getDistanceBetweenPlayers(p1, p2)
	
	if not (p1.Character) then
		return nil;
	end
	
	local c2 = p2.Character;
	local c2Head;
	
	if (c2) then
		c2Head = c2:FindFirstChild("Head");
	else 
		return nil;
	end
	
	if (c2Head) then
		return p1:DistanceFromCharacter(c2Head.Position);
	else
		return nil;
	end
	
end






 





