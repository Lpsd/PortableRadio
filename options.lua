--------------------------------------------------------------------
--------------------- [PortableRadio] OPTIONS ----------------------
--------------------------------------------------------------------

DEBUG = true

-- Key bindings
-- For keys, see https://docs.ue4ss.com/lua-api/table-definitions/key.html
-- e.g: Key.R, Key.F, Key.F1, Key.CAPS_LOCK
-- Choose ONE key only

-- For modifiers (Shift, Ctrl, Alt), see https://docs.ue4ss.com/lua-api/table-definitions/modifierkey.html
-- You can choose no modifiers, a single modifier, or multiple modifiers
-- e.g (none): {}
-- e.g (Shift): {ModifierKey.SHIFT}
-- e.g (Ctrl + Alt): {ModifierKey.CONTROL, ModifierKey.ALT}

-- [[ Toggle radio ]]
-- Default: Key.B
KEY_TOGGLE_RADIO = Key.B
-- Default: {ModifierKey.SHIFT}
MODIFIERS_TOGGLE_RADIO = {ModifierKey.SHIFT}

-- [[ Change radio frequency ]]
-- Default: Key.F
KEY_CHANGE_RADIO_FREQUENCY = Key.F
-- Default: {ModifierKey.SHIFT}
MODIFIERS_CHANGE_RADIO_FREQUENCY = {ModifierKey.SHIFT}

-- 0 - 10
-- Default: 1.0
DEFAULT_RADIO_VOLUME = 1.0

-- Whether to always try to load the radio asset on spawn
-- Default: true
ALWAYS_TRY_LOAD_ASSET = true

-- Which radio asset to spawn
-- Default: /Game/_STALKER2/GameDesign/QuestInteractiveObjects/Radio/GenericRadio/Radio_120/Hub/BP_100_Rads_Bar_120.BP_100_Rads_Bar_120_C
RADIO_BP_ASSET = "/Game/_STALKER2/GameDesign/QuestInteractiveObjects/Radio/GenericRadio/Radio_120/Hub/BP_100_Rads_Bar_120.BP_100_Rads_Bar_120_C"
