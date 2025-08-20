--!strict
--[[
    Connections Module
    @X_FSX | Approach
    August 02, 2025

    This module provides a lightweight utility for managing multiple `RBXScriptConnection` 
    objects in a centralized and organized manner. It allows for:
    - Connecting and storing connections with optional keys
    - Disconnecting individual connections via keys
    - Disconnecting all managed connections at once

    Useful for ensuring proper cleanup of event listeners, particularly in component-based
    or object-oriented systems.

    API:
    - Connections.new() → ConnectionsObject
        • .Connect(connection: RBXScriptConnection, key: any?) → ()
        • .Disconnect(key: any) → ()
        • .DisconnectAll() → ()

    Example:
        local Connections = Connections.new()
        Connections:Connect(Part.Touched:Connect(OnTouched), "TouchListener")
        Connections:Disconnect("TouchListener") -- Disconnects specific connection
        Connections:DisconnectAll() -- Disconnects all active connections
--]]

local Connections = {}

export type ConnectionsObject = {
    Connect: (self: ConnectionsObject, Connection: RBXScriptConnection, Key: any?) -> (),
    Disconnect: (self: ConnectionsObject, Key: any?) -> (),
    DisconnectAll: (self: ConnectionsObject) -> (),
    
    _connections: {[any | number]: () -> ()}
}

local Class = {} :: ConnectionsObject do
    -- Connects a connection to a key if defined
    function Class:Connect(Connection: RBXScriptConnection, Key: any?)
        local NewKey = Key or #self._connections + 1
        self._connections[NewKey] = function()
            Connection:Disconnect()
            self._connections[NewKey] = nil
        end
    end

    -- Disconnects a connection
    function Class:Disconnect(Key: any)
        local Disconnect = self._connections[Key]
        if not Disconnect then return end
        Disconnect()
    end
    
    -- Disconnects all connections
    function Class:DisconnectAll()
        for _, v in self._connections do
            v()
        end
    end
    
    table.freeze(Class)
end

local Meta = table.freeze({__index = Class})

type MetaConnectionsObject = typeof(setmetatable({} :: ConnectionsObject, Meta))

-- Creates new connection object
function Connections.new(): MetaConnectionsObject
    local self = setmetatable({}, Meta) :: MetaConnectionsObject
    
    self._connections = {}
    
    return self
end

return table.freeze(Connections)
