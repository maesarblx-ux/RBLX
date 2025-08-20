--!strict
--[[
    Input Module
    @X_FSX | Approach
    August 02, 2025

    This module provides a wrapper around `ContextActionService` to simplify 
    handling input events for specific `KeyCode` or `GamepadKeyCode` bindings. 
    It emits signals for different `UserInputState` transitions: Began, Ended, 
    Canceled, Changed, and None.

    Each input binding instance is given a unique identifier and exposes 
    Signal-based events, allowing multiple consumers to respond to input changes.

    Features:
    - Binds input actions to signals using ContextActionService
    - Automatically maps UserInputState to corresponding events
    - Supports manual unbinding via `:Disconnect()`

    API:
    - InputModule.new(KeyCode: Enum.KeyCode, GamepadKeyCode: Enum.KeyCode?) → InputClass
        • .Began: Signal<InputObject>
        • .Ended: Signal<InputObject>
        • .Canceled: Signal<InputObject>
        • .Changed: Signal<InputObject>
        • .None: Signal<InputObject>
        • .Disconnect() → ()

    Example:
        local Input = InputModule.new(Enum.KeyCode.E)
        Input.Began:Connect(function(Input: InputObject)
            print("E key pressed", Input)
        end)
        Input:Disconnect()
--]]

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Signal = require(script.Signal)

local InputModule = {}

export type InputClass = {
    Disconnect: (self: InputClass) -> (),
    
    ID: string,
    
    Began: Signal.Signal<InputObject>,
    Ended: Signal.Signal<InputObject>,
    Canceled: Signal.Signal<InputObject>,
    Changed: Signal.Signal<InputObject>,
    None: Signal.Signal<InputObject>,
}

local Class = {} :: InputClass do
    -- Disconnects the input object
    function Class:Disconnect()
        ContextActionService:UnbindAction(self.ID)
    end
    
    table.freeze(Class)
end

local InputStates: {[Enum.UserInputState]: string} = table.freeze({
    [Enum.UserInputState.Begin] = "Began",
    [Enum.UserInputState.End] = "Ended",
    [Enum.UserInputState.Cancel] = "Canceled",
    [Enum.UserInputState.Change] = "Changed",
    [Enum.UserInputState.None] = "None",
})

local Meta = table.freeze({__index = Class})

type MetaInputObject = typeof(setmetatable({} :: InputClass, Meta))

-- Creates a new input object
function InputModule.new(KeyCode: Enum.KeyCode, GamepadKeyCode: Enum.KeyCode?): MetaInputObject
    local self = setmetatable({}, Meta) :: MetaInputObject
    
    self.ID = HttpService:GenerateGUID(false)
    
    self.Began = Signal.new()
    self.Ended = Signal.new()
    self.Canceled = Signal.new()
    self.Changed = Signal.new()
    self.None = Signal.new()
    
    ContextActionService:BindAction(self.ID, function(ActionName: string, InputState: Enum.UserInputState, InputObject: InputObject)
        if ActionName ~= self.ID then return end
        self[InputStates[InputState] or "None"]:Fire(InputObject)
    end, false, KeyCode, GamepadKeyCode)
    
    return self
end

return table.freeze(InputModule)
