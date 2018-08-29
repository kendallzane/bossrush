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

if (script.Parent ~= game:GetService("ServerScriptService")) then
	warn("Midair Jump Script (server side) is in the wrong place! Put it in ServerScriptService.");
else
	print("VivianConquest's Midair Jump Script (server side) loaded!");
end

--[[
	midairJumpNumber:			Number of midair jumps allowed to the player.
									1 = 1 midair jump (double jump)
									2 = 2 midair jumps (triple jump)
									etc...
							
									0 = no midair jumps (normal Roblox stuff)
									-1 (or any negative number) = infinite midair jumps
							
	midairJumpVelocity: 		How high the midair jump goes.
								Experiment to see what works best in your game.
					
	midairJumpForce:			Force applied when midair jumping. Also affects double jump height.
								The default is a good number IMO.
								I tested altering the force based on the total mass of the character,
								but I don't think it makes much difference.
					
	midairJumpSpeedBonus:		An extra bonus to Humanoid.WalkSpeed when jumping.
								I think giving a small boost makes the jump feel more powerful.
								
	midairJumpEffects:			When true, it shows a special effect when you midair jump, styled
								the one in the Super Smash Bros. series. You can disable it if you
								want.
								
	midairJumpSound:			When true, plays the default Roblox jump sound when doing a midair 
								jump. Can be modified to play a custom sound if you want.
--]]

local midairJumpNumber = 1;
local midairJumpVelocity = 31;
local midairJumpForce = 14000;
local midairJumpSpeedBonus = 2;
local midairJumpEffects = true;
local midairJumpSound = true;

game.Players.PlayerAdded:connect(function(player)
	
	--[[
		Variables concerning the double jumping system are put in a folder in the Player.
		Feel free to modify for your own implementation.
	--]]
	
	local stats = Instance.new("Folder");
	stats.Name = "Stats"
	stats.Parent = player;
		
	local val = Instance.new("IntValue");
	val.Name = "JumpsLeft";
	val.Value = midairJumpNumber;
	val.Parent = stats;
		
	local val = Instance.new("BoolValue");
	val.Name = "JumpDebounce";
	val.Value = false;
	val.Parent = stats;
		
	player.CharacterAdded:connect(function(character)
		
		local humanoid = character:WaitForChild("Humanoid");
		local stats = player:WaitForChild("Stats");
		local jumpsLeft = stats:WaitForChild("JumpsLeft");
		
		--[[
			The force for the midair jumps comes from a BodyVelocity placed in the character's
			HumanoidRootPart. R6 and R15 characters both should have that.
			
			The force is always there, but is turned on only when needed. That saves us
			having to constantly create and destroy BodyVelocitys.
		--]]
		
		local root = character:WaitForChild("HumanoidRootPart");
		local force = Instance.new("BodyVelocity");
		force.Name = "MidairJumpForce";
		force.Velocity = Vector3.new(0, 0, 0);
		force.maxForce = Vector3.new(0, 0, 0);
		force.Parent = root;
		
		humanoid.StateChanged:connect(function(_, newState)
			
			--[[
				Here we reset the character's midair jumps after they land.
				We can't always rely on "Landed" to fire, so we check among many different
				Humanoid States. You can add or remove any if you want.
			--]]
			
			local landStates = {
				[Enum.HumanoidStateType.Landed] = true,
				[Enum.HumanoidStateType.Running] = true,
				[Enum.HumanoidStateType.Swimming] = true,
				[Enum.HumanoidStateType.RunningNoPhysics] = true,
				[Enum.HumanoidStateType.GettingUp] = true,
				[Enum.HumanoidStateType.Climbing] = true,
			};
			
			if (landStates[newState]) then
				jumpsLeft.Value = midairJumpNumber;
			end
			
		end)
		
	end)
	
end)

--[[
	Here we set up the RemoveEvents that make this script work.
	
	JumpRequest: 		What a client sends to us. They perform a check
						to see if they should midair jump, but the server
						is the main one doing the sanity checking.
	
	JumpAnimRequest:	Simply, when a character does a midair jump, we
						ask to change their humanoid state so they do the
						character's jumping animation. That can only be
						done locally.
	
	JumpEffectRequest:	Here we ask the client to create the visual for the
						midair jumps. Doing this on the server side would
						have the effect not be consistent with the player's
						position. 
						
						This fires to ALL clients, so all effects are drawn
						client side for all players. By default, this only
						happens if the player is in close range to the player
						who is midair jumping.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage");

local JumpRequest = Instance.new("RemoteEvent", ReplicatedStorage);
JumpRequest.Name = "JumpRequest";
 
local JumpAnimRequest = Instance.new("RemoteEvent", ReplicatedStorage);
JumpAnimRequest.Name = "JumpAnimRequest";

local JumpEffectRequest = Instance.new("RemoteEvent", ReplicatedStorage);
JumpEffectRequest.Name = "JumpEffectRequest";

local function onJumpRequest(player)
	
	--[[
		A player wants to do a midair jump. We sanity check so that exploiters
		can't fly wherever they want.
		
		Sanity checks slightly compacted for convenience...
	--]]
	
	local character = player.Character;
	if not (player.Character) then return; end
	
	local humanoid = character:FindFirstChild("Humanoid");
	if not (humanoid) then return; end
		
	if not (character:IsDescendantOf(workspace)) then return; end
	
	if (humanoid:GetState() ~= Enum.HumanoidStateType.Freefall) then return; end
	
	local stats = player:FindFirstChild("Stats");
	if not (stats) then return; end
	
	local debounce = stats:FindFirstChild("JumpDebounce");
	if not (debounce) then return; end
	
	local jumpsLeft = stats:FindFirstChild("JumpsLeft");
	if not (jumpsLeft) then return; end
	
	local head = character:FindFirstChild("Head");
	if not (head) then return; end
	
	local root = character:FindFirstChild("HumanoidRootPart");
	if not (root) then return; end
	
	local force = root:FindFirstChild("MidairJumpForce");
	if not (force) then return; end
	
	if (debounce.Value == true) then return; end
	
	if (jumpsLeft.Value ~= 0) then
		
		--[[
			The checks are complete, and the request to double jump is valid.
		--]]
				
		debounce.Value = true;
		
		--[[
			Decrease the number of midair jumps by one, unless they're infinite.
		--]]
		
		if (jumpsLeft.Value > 0) then
			jumpsLeft.Value = jumpsLeft.Value - 1;
		end
		
		--[[
			Play the jumping sound.
		--]]
		
		if (midairJumpSound) then
			local head = character:FindFirstChild("Head");
			if (head) then
				local jumpSound = head:FindFirstChild("Jumping");
				if (jumpSound) then
					jumpSound:Play();
				end
			end
		end
		
		--[[
			Play the jumping animation.
		--]]
		
		JumpAnimRequest:FireClient(player);
		
		--[[
			Create the midair jump effects.
		--]]
		
		if (midairJumpEffects) then
			JumpEffectRequest:FireAllClients(player);
		end
			
		--[[
			Set the BodyVelocity active, and speed up player if necessary.
		--]]
		
		force.maxForce = Vector3.new(0, midairJumpForce, 0);
		force.Velocity = Vector3.new(0, midairJumpVelocity, 0);
		humanoid.WalkSpeed = humanoid.WalkSpeed + midairJumpSpeedBonus;
		
		--[[
			Because a jump is just a brief moment of upward force, the
			BodyVelocity is only active for a fraction of a second.
		--]]
		
		wait(0.1);
		
		force.maxForce = Vector3.new(0, 0, 0);
		force.Velocity = Vector3.new(0, 0, 0);
		
		wait(0.2);
		
		--[[
			Set the character's speed back to normal.
		--]]
		
		humanoid.WalkSpeed = humanoid.WalkSpeed - midairJumpSpeedBonus;
		
	end
	
	debounce.Value = false;
	
end
 
JumpRequest.OnServerEvent:Connect(onJumpRequest);


