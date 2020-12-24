--[[

	----------------------------------------------------------
	    	  Directory (Initializing and Searching)
	----------------------------------------------------------
	
	Credits: @DarthFS
	
	Searching:
	
		local PackedModules = DirectoryManager.PathSearchAsync {
			'Shared: TableExtender, Input',
			'Client: Inventory, Quest',
		};
		
	Initializing:
	
		local function InitializeServer(Environment)
			Environment = ( type(Environment) == 'string' and Environment ) or Error.With(): InvalidArgument():At {Line = 11, Function = 'InitializeServer', ValueName = Environment};
	
			return SystemsDirectory.Init(Environment);
		end;

		local Worked, PackedEnvironment = InitializeServer('Server');

--]]

-- // Services / Modules

local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService        = game:GetService('RunService');
local Players           = game:GetService('Players');

local TableExtender = require(ReplicatedStorage:WaitForChild('Shared').Utilities.Container);
local Error = require(ReplicatedStorage:WaitForChild('Shared').Utilities.Error);

-- // Constants (Variables, Functions, Tables)

local RunServiceHeartbeat = RunService.Heartbeat;
local IsYielding     = false;

local TableWrapper = TableExtender._TableWrapper;
local function ReturnCompatability(Table, IteratorFlag) -- ReturnCompatability (Table: table, IteratorFlag: boolean)
	Table = ( type(Table) == 'table' and Table ) or Error.With(): InvalidArgument():At {Line = 41, Function = 'ReturnCompatability', ValueName = tostring(Table),};
	local _ = ( type(IteratorFlag) == 'boolean' ) or Error.With(): InvalidArgument():At {Line = 42, Function = 'ReturnCompatability', ValueName = tostring(IteratorFlag),};

	if (IteratorFlag) then
		return ( Table[1] and ipairs ) or ( pairs(Table) and pairs );
	end;

	return ( Table[1] and 'ipairs' ) or ( pairs(Table) and 'pairs' );
end;

local function SerializePathArguments(Table) -- SerializePathArguments (Table: table)
	Table = ( ReturnCompatability(Table, false) == 'ipairs' and Table ) or Error.With(): InvalidArgument():At {Line = 52, Function = 'SerializePathArguments', ValueName = ReturnCompatability(Table, false),};
	Table = ( #Table ~= 0 and Table) or Error.With(): InvalidArgument():At {Line = 53, Function = 'SerializePathArguments', ValueName = tostring(Table),};

	local ParsedData, Path = {}, nil;
	for Index, Component in ipairs(Table) do
		Path = string.split(Component, ': ');

		ParsedData[Index] = { Environment = Path[1], 
			SerializedTable = TableWrapper.New (string.split(Path[2], ', ')),
		};

		ParsedData[Index].SerializedTable.ConvertType('Structure: Bag');
	end;

	return ParsedData; 
end;

local Environments = {
	['Client'] = RunService:IsClient() and Players.LocalPlayer.PlayerScripts.Client,
	['Server'] = RunService:IsServer() and game:GetService('ServerScriptService').Server, -- We don't define the service at the top of our script just incase the client is trying to access it
	['Shared'] = ReplicatedStorage:WaitForChild('Shared'),
};

-- // Main Manager (Utilizes all the code written above)

local DirectoryManager = {
	_InternalGetters = {},
	_HasInitialized = {Client = true, Server = true},
};
DirectoryManager.ClassName = 'Directory';

function DirectoryManager.PathSearchAsync(Information) -- .PathSearchAsync (Information: table)
	Information = ( type(Information) == 'table' and Information ) or Error.With(): InvalidArgument():At {Line = 95, Function = '.PathSearchAsync', ValueName = type(Information),};
	
	local SerializedData, ModuleBuffer = SerializePathArguments (Information), {};
	for _, Fragment in ipairs(SerializedData) do		
		if DirectoryManager._HasInitialized[Fragment.Environment] then
			IsYielding = IsYielding == false;
			repeat RunService.Heartbeat:Wait() until not IsYielding;
		end;
		
		if ( Fragment.Environment == 'Shared' ) then
			for _, Component in ipairs(Environments[Fragment.Environment]:GetDescendants()) do
				if rawset(Fragment.SerializedTable, Component.Name) then
					ModuleBuffer[Component.Name] = DirectoryManager.SafeLoadComponent(Component);
				end;
			end;
		else
			local LocatedGetter = DirectoryManager._InternalGetters[Fragment.Environment] or warn('Environment does not exist!');
			
			for Index, Component in pairs(LocatedGetter) do
				if (rawget(Fragment.SerializedTable, Index)) then -- Fragment.SerializedTable is a wrapper hooked with an __index method
 					ModuleBuffer[Index] = Component;
				end;
			end;
		end;
	end;
	
	return ModuleBuffer;
end;

function DirectoryManager.Init(RequestedEnvironment) -- .Init (RequestedEnvironment: string)
	RequestedEnvironment = ( type(RequestedEnvironment) == 'string' and RequestedEnvironment ) or Error.With(): InvalidArgument():At {Line = 103, Function = '.Init', ValueName = type(RequestedEnvironment),};
	RequestedEnvironment = Environments[RequestedEnvironment] or Error.With(): InvalidArgument():At {Line = 107, Function = '.Init', ValueName = RequestedEnvironment,};
	
	if (not DirectoryManager._HasInitialized[RequestedEnvironment.Name]) then return end;
	
	local InternalGetters = DirectoryManager._InternalGetters;
	InternalGetters[RequestedEnvironment.Name] = InternalGetters[RequestedEnvironment.Name] or {};
	
	local CachedEnvironment = InternalGetters[RequestedEnvironment.Name];
	for _, Pathway in ipairs(RequestedEnvironment:GetDescendants()) do
		local Derived = DirectoryManager.SafeLoadComponent (Pathway);
		Derived = Derived or warn(('Unable to load module: %s'):format(Pathway.Name));
		
		if (type(Derived) == 'table' and Derived.Init) then
			local _ = ( type(Derived.Init) == 'function' ) and Derived:Init ();
		end;
		
		CachedEnvironment[Pathway.Name] = Derived;
	end;
	
	DirectoryManager._HasInitialized[RequestedEnvironment.Name] = nil;
	IsYielding = IsYielding and false;
	
	return true, CachedEnvironment;
end;

function DirectoryManager.SafeLoadComponent(Component) -- .SafeLoadComponent (Component: userdata)
	Component = ( type(Component) == 'userdata' and Component ) or Error.With(): InvalidArgument():At {Line = 120, Function = '.SafeLoadComponent', ValueName = type(Component),};
	
	local Success, Result = pcall(require, Component);
	return ( Success == true ) and Result;
end;

return DirectoryManager;
