--[[

	----------------------------------------------------------
	    	  Directory (Initializing and Searching)
	----------------------------------------------------------
	
	Credits: @DarthFS
	
	Searching:
	
		local Domains, Gojo = DirectoryManager.SearchPath('Shared', 'Domains', 'Gojo');
		
	Initializing:
	
		local function InitializeServer(Environment)
			Environment = ( type(Environment) == 'string' and Environment ) or Error.With(): InvalidArgument():At {Line = 11, Function = 'InitializeServer', ValueName = Environment};
	
			return SystemsDirectory.Init(Environment);
		end;

		local PackedEnvironment = InitializeServer('Server'); -- // Returns all the required modules from the environment

--]]

-- // Services / Modules
local replicatedStorage = game:GetService('ReplicatedStorage');
local runService = game:GetService('RunService')
local players = game:GetService('Players');

-- // Constants (Variables, Functions, Tables)
local runServiceHeartbeat = runService.Heartbeat;
local environments = {
	['Client'] = runService:IsClient() and players.LocalPlayer.Backpack.Client,
	['Server'] = runService:IsServer() and game:GetService('ServerScriptService').Server, -- We don't define the service at the top of our script just incase the client is trying to access it
	['Shared'] = replicatedStorage:WaitForChild('Shared'),
};

-- // Main Directory Functions
local DirectoryManager = {
	_internalGetters = {},
	_hasNotInitialized = {Client = true, Server = true, Shared = true}
}
DirectoryManager.ClassName = 'DirectoryManager'

function DirectoryManager.SearchPath(requestedEnvironment, ...)
	requestedEnvironment = ( type(requestedEnvironment) == 'string' and requestedEnvironment ) or error('Environment argument must be a string')
	local packedArguments, buffer = {...}, {}
	
	local internalGetters = DirectoryManager._internalGetters
	local indexedGetter = internalGetters[requestedEnvironment]
	if not indexedGetter then
		repeat runServiceHeartbeat:Wait() until internalGetters[requestedEnvironment]
		indexedGetter = internalGetters[requestedEnvironment]
	end
	
	for _, componentName in ipairs(packedArguments) do
		buffer[#buffer + 1] = indexedGetter[componentName]
	end
	return unpack(buffer)
end;
function DirectoryManager.Init(requestedEnvironment)
	requestedEnvironment = environments[requestedEnvironment] or error('Environment argument is not valid')
	local internalGetters = DirectoryManager._internalGetters[requestedEnvironment.Name] or {}
	
	local initFuncName = ( runService:IsClient() and 'Client' or 'Server' ) .. 'Init'
	for _, pathWay in ipairs(requestedEnvironment:GetDescendants()) do
		local derivedResult = nil;
		if pathWay.ClassName == 'ModuleScript' then
			derivedResult = DirectoryManager.SafeLoadComponent(pathWay) or warn(('Unable to load module: %s'):format(pathWay.Name));

			if type(derivedResult) == 'table' and derivedResult[initFuncName] then
				local _ = ( type(derivedResult[initFuncName]) == 'function' ) and coroutine.wrap(derivedResult[initFuncName])(derivedResult)
			end
		end
		internalGetters[pathWay.Name] = derivedResult
	end
	DirectoryManager._hasNotInitialized[requestedEnvironment.Name] = nil
	print(requestedEnvironment.Name .. ': ')
	print(internalGetters)

	return true, internalGetters
end
function DirectoryManager.SafeLoadComponent(component)
	component = ( type(component) == 'userdata' and component ) or error('Component argument must be a userdata')

	local success, result = pcall(require, component)
	return ( success == true ) and result
end

return DirectoryManager
