--[[

	----------------------------------------------------------
	    	  Directory (Initializing and Searching)
	----------------------------------------------------------
	
	Credits: @DarthFS
	
	Searching:
	
		local TableExtender, Input = DirectoryManager.PathSearchAsync {
			'Shared: TableExtender, Input',
			'Client: Inventory, Quest',
		};
		
	Initializing:
	
		local function MainInit(Path, Environment) // Handled on Client and Server
			Environment = ( type(Environment) == 'string' and Environment ) or error('Environment argument must be a string!');
			Path = ( type(Path) == 'string and Path ) or error('Path argument must be a string!');
			
			return DirectoryManager.Init(Path, Environment);
		end;
		
		local _ = MainInit(PlayerScripts.Client, 'Client') and print('Success!');

--]]

-- // Services / Modules

local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService        = game:GetService('RunService');
local Players           = game:GetService('Players');

local TableExtender = require(ReplicatedStorage:WaitForChild('Shared').Utilities.Container);
local Error = require(ReplicatedStorage:WaitForChild('Shared').Utilities.Error);

-- // Constants (Variables, Functions, Tables)

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
	['Client'] = RunService:IsClient() and Players.LocalPlayer.PlayerScripts.Client;
	['Server'] = RunService:IsServer() and game:GetService('ServerScriptService').Server; -- We don't define the service at the top of our script just incase the client is trying to access it
	['Shared'] = ReplicatedStorage:WaitForChild('Shared');
};

-- // Main Manager (Utilizes all the code written above)

local DirectoryManager = {_InternalGetters = {},};
DirectoryManager.ClassName = 'Directory';

function DirectoryManager.PathSearchAsync(Information) -- .PathSearchAsync (Information: table)
	Information = ( type(Information) == 'string' and Information ) or Error.With(): InvalidArgument():At {Line = 95, Function = '.PathSearchAsync', ValueName = type(Information),};
	
	local SerializedData = SerializePathArguments (Information);
	local ModuleBuffer = {};
	
	for _, Fragment in ipairs(SerializedData) do
		Fragment = Fragment and TableWrapper.New(Fragment);
		
		local CachedEnvironment = Fragment.DeepSearch ('Environment');
		local BagReference = Fragment.DeepSearch ('SerializedTable');
		
		if ( CachedEnvironment == 'Shared' ) then
			
			for _, Component in ipairs(Environments[CachedEnvironment]:GetDescendants()) do
				if BagReference[Component.Name] then
					ModuleBuffer[#ModuleBuffer + 1] = DirectoryManager.SafeLoadComponent(Component);
				end;
			end;
		else
			local LocatedGetter = DirectoryManager._InternalGetters[CachedEnvironment] or Error.With(): InvalidArgument():At {
				Line = 104, Function = '.PathSearchAsync', ValueName = SerializedData.Environment
			};

			for Index, Component in pairs(LocatedGetter) do
				if BagReference[Index] then
					ModuleBuffer[#ModuleBuffer + 1] = Component;
				end;
			end;
		end;
	end;
	
	return ModuleBuffer;
end;

function DirectoryManager.Init(RequestedEnvironment) -- .Init (RequestedEnvironment: string)
	RequestedEnvironment = ( type(RequestedEnvironment) == 'string' and RequestedEnvironment ) or Error.With(): InvalidArgument():At {Line = 103, Function = '.Init', ValueName = type(RequestedEnvironment),};
	RequestedEnvironment = Environments[RequestedEnvironment] or Error.With(): InvalidArgument():At {Line = 107, Function = '.Init', ValueName = RequestedEnvironment,};
	
	for _, Pathway in ipairs(RequestedEnvironment:GetDescendants()) do
		
	end;
end;

function DirectoryManager.SafeLoadComponent(Component) -- .SafeLoadComponent (Component: userdata)
	Component = ( type(Component) == 'userdata' and Component ) or Error.With(): InvalidArgument():At {Line = 120, Function = '.SafeLoadComponent', ValueName = type(Component),};
	
	
end;

return DirectoryManager;
