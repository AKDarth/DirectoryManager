--[[

	----------------------------------------------------------
	    	  Directory (Initializing and Searching)
	----------------------------------------------------------
	
	Credits: @DarthFS
	
	Searching:
	
		local Domains, Gojo = DirectoryManager.PathSearchAsync('Shared', 'Domains', 'Gojo');
		
	Initializing:
	
		local function InitializeServer(Environment)
			Environment = ( type(Environment) == 'string' and Environment ) or Error.With(): InvalidArgument():At {Line = 11, Function = 'InitializeServer', ValueName = Environment};
	
			return SystemsDirectory.Init(Environment);
		end;

		local Worked, PackedEnvironment = InitializeServer('Server');

--]]

-- // Services / Modules
local replicatedStorage = game:GetService('ReplicatedStorage');
local runService        = game:GetService('RunService');
local players           = game:GetService('Players');

-- // Constants (Variables, Functions, Tables)
local runServiceHeartbeat = runService.Heartbeat;
local isYielding          = false;

local environments = {
	['Client'] = runService:IsClient() and players.LocalPlayer.Backpack.Client,
	['Server'] = runService:IsServer() and game:GetService('ServerScriptService').Server, -- We don't define the service at the top of our script just incase the client is trying to access it
	['Shared'] = replicatedStorage:WaitForChild('Shared'),
};
-- // Main Directory Functions
local DirectoryManager = {
	_internalGetters = {},
	_hasNotInitialized = {Client = true, Server = true}
}
DirectoryManager.ClassName = 'DirectoryManager'

function DirectoryManager.PathSearchAsync(requestedEnvironment, ...)
	requestedEnvironment = ( type(requestedEnvironment) == 'string' and requestedEnvironment ) or error('Environment argument must be a string')
	local packedArguments, buffer = {...}, {}
	
	local cachedEnvironment = environments[requestedEnvironment] or error('Requested environment does not exist')
	if DirectoryManager._hasNotInitialized[cachedEnvironment] then
		isYielding = isYielding == false
		repeat runServiceHeartbeat:Wait() until not isYielding
	end
	
	for _, componentOne in ipairs(packedArguments) do
		if DirectoryManager._internalGetters[componentOne] then
			buffer[#buffer + 1] = componentOne
		end
	end
		
	return unpack(buffer)
end;
function DirectoryManager.Init(requestedEnvironment)
	requestedEnvironment = environments[requestedEnvironment] or error('Environment argument is not valid')
	local internalGetters = DirectoryManager._internalGetters
	internalGetters[requestedEnvironment.Name] = internalGetters[requestedEnvironment.Name] or {}
	
	for _, pathWay in ipairs(requestedEnvironment:GetDescendants()) do
		local derivedResult = nil;
		if pathWay.ClassName == 'ModuleScript' then
			derivedResult = DirectoryManager.SafeLoadComponent(pathWay);
			derivedResult = derivedResult or warn(('Unable to load module: %s'):format(pathWay.Name))
			
			if type(derivedResult) == 'table' and derivedResult.Init then
				local _ = ( type(derivedResult.Init) == 'function' ) and derivedResult:Init();
			end
		end
		
		internalGetters[requestedEnvironment.Name] = derivedResult
	end
	DirectoryManager._hasNotInitialized[requestedEnvironment.Name] = nil
	isYielding = isYielding and false
	
	return true, internalGetters[requestedEnvironment.Name]
end
function DirectoryManager.SafeLoadComponent(component)
	component = ( type(component) == 'userdata' and component ) or error('Component argument must be a userdata')
	
	local success, result = pcall(require, component)
	return ( success == true ) and result
end
