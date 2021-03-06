local numSteps = 1;

local brick = Instance.new("Part");
brick.Anchored = true;
brick.Size = Vector3.new(10, 10, 10);
brick.Material = "SmoothPlastic";
local r = 255;
local g = 255;
local b = 255;
brick.Color = Color3.fromRGB (r, g, b);
brick.CanCollide = false;
local numIterations = 0;
local totalSteps = 0;

function step(currentBrick)
	--up, down, left, right, above, below;
	
	local freeArray = {1, 1, 1, 1, 1, 1};
	local numFree = 0;
	local toBuild = 0;
	
	local direction;
	local ray;
	
	ray = Ray.new(currentBrick.Position, Vector3.new(0, 0, 10));
	local hit, pos = workspace:FindPartOnRay(ray, currentBrick);
	if (hit == nil) then
		freeArray[1] = 0;
		numFree = numFree + 1;
	end
	
	ray = Ray.new(currentBrick.Position, Vector3.new(0, 0, -10));
	local hit, pos = workspace:FindPartOnRay(ray, currentBrick);
	if (hit == nil) then
		freeArray[2] = 0;
		numFree = numFree + 1;
	end
	
	ray = Ray.new(currentBrick.Position, Vector3.new(-10, 0, 0));
	local hit, pos = workspace:FindPartOnRay(ray, currentBrick);
	if (hit == nil) then
		freeArray[3] = 0;
		numFree = numFree + 1;
	end
	
	ray = Ray.new(currentBrick.Position, Vector3.new(10, 0, 0));
	local hit, pos = workspace:FindPartOnRay(ray, currentBrick);
	if (hit == nil) then
		freeArray[4] = 0;
		numFree = numFree + 1;
	end
	
	ray = Ray.new(currentBrick.Position, Vector3.new(0, 10, 0));
	local hit, pos = workspace:FindPartOnRay(ray, currentBrick);
	if (hit == nil) then
		freeArray[5] = 0;
		numFree = numFree + 1;
	end
	
	ray = Ray.new(currentBrick.Position, Vector3.new(0, -10, 0));
	local hit, pos = workspace:FindPartOnRay(ray, currentBrick);
	if (hit == nil) then
		freeArray[6] = 0;
		numFree = numFree + 1;
	end
	
	if (numFree == 0) then
		print("Steps: ", numSteps);
		totalSteps = totalSteps + numSteps;
		local average = totalSteps / numIterations;
		print("Average:", average);
		print();
		return;
	end
	
	local toPick;
	local rng = Random.new();
	toPick = rng:NextInteger(1, numFree);
	for index, value in ipairs(freeArray) do
		if (value == 0) then 
			toPick = toPick - 1;
			if (toPick  == 0) then
				toBuild = index;
			end
		end
	end
	
	local c = brick:Clone();
	
	if (toBuild == 1) then
		c.Position = currentBrick.Position + Vector3.new(0, 0, 10);
	elseif (toBuild == 2) then
		c.Position = currentBrick.Position + Vector3.new(0, 0, -10);
	elseif (toBuild == 3) then
		c.Position = currentBrick.Position + Vector3.new(-10, 0, 0);
	elseif (toBuild == 4) then
		c.Position = currentBrick.Position + Vector3.new(10, 0, 0);
	elseif (toBuild == 5) then
		c.Position = currentBrick.Position + Vector3.new(0, 10, 0);
	elseif (toBuild == 6) then
		c.Position = currentBrick.Position + Vector3.new(0, -10, 0);
	end
	
	r = r + rng:NextInteger(-3, 3);
	if (r < 0) then r = 0; end
	if (r > 255) then r = 255; end
	
	g = g + rng:NextInteger(-3, 3);
	if (g < 0) then g = 0; end
	if (g > 255) then g = 255; end
	
	b = b + rng:NextInteger(-3, 3);
	if (b < 0) then b = 0; end
	if (b > 255) then b = 255; end
	
	if (currentBrick) then
		currentBrick.Color = Color3.fromRGB(r, g, b);
	end
	
	c.Color = Color3.fromRGB(0, 0, 0);
	
	c.Parent = script;
	numSteps = numSteps + 1;
	wait(0.01);
	step(c);
	
end

function restart()
	
	numIterations = numIterations + 1;
	print("Iteration:", numIterations);
	
	local children = script:GetChildren();
	for i = 1, #children do
    	if (children[i].ClassName == "Part") then
			children[i]:Destroy();
		end
	end
	
	local c = brick:Clone();
	r = 255;
	g = 255;
	b = 255;
	c.Color = Color3.fromRGB (r, g, b);
	c.Position = Vector3.new(0, 0, 0);
	c.Parent = script;
	numSteps = 1;
	step(c);
	
end

while true do
	restart();
	wait(1);
end