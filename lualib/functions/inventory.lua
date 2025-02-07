---
-- Fonction "player"
---
local flib = {}
---------------------------------------------------------------------------------------------
local ritnlib = {}
ritnlib.utils =       require(ritnmods.teleport.defines.functions.utils)
---------------------------------------------------------------------------------------------

-- Init structure
local function initInventory()
  local invGlobal = {}

  invGlobal[defines.inventory.character_main] = game.create_inventory(ritnmods.teleport.defines.value.inventory_size)
  invGlobal[defines.inventory.character_guns] = game.create_inventory(ritnmods.teleport.defines.value.inventory_size)
  invGlobal[defines.inventory.character_ammo] = game.create_inventory(ritnmods.teleport.defines.value.inventory_size)
  invGlobal[defines.inventory.character_armor] = game.create_inventory(ritnmods.teleport.defines.value.inventory_size)
  invGlobal[defines.inventory.character_trash] = game.create_inventory(ritnmods.teleport.defines.value.inventory_size)
  invGlobal["cursor"] = game.create_inventory(1)
  invGlobal["logistic_param"] = {
    {name="slot_count", value = 0},
    {name="character_personal_logistic_requests_enabled", value = false}
  }

  ritnlib.utils.ritnLog(">> (debug) - function inventory : init -> ok")
  return invGlobal
end



-- SaveInventory
local function saveInventory(invGlobal, LuaPlayer, defines)
  local inventory = LuaPlayer.get_inventory(defines)
    if inventory ~= nil then
      for i=1, #inventory do 
        local stack = inventory[i]
        if stack.valid then
          invGlobal[defines][i].swap_stack(stack)
        end
      end
    end
    ritnlib.utils.ritnLog(">> (debug) - function inventory : saveInventory -> ok")
end

--LoadInventory
local function loadInventory(invGlobal, LuaPlayer, defines)
  local inventory1 = LuaPlayer.get_inventory(defines)
  local inventory = invGlobal[defines]
  if inventory1 ~= nil then
    for i=1, #inventory1 do 
      local stack = inventory[i]
      if stack.valid then
        inventory1[i].swap_stack(stack)
      end
    end
  end
  ritnlib.utils.ritnLog(">> (debug) - function inventory : loadInventory -> ok")
end



--New Save
local function save_all_inventory(LuaPlayer, invGlobal)
  saveInventory(invGlobal, LuaPlayer, defines.inventory.character_main)
  saveInventory(invGlobal, LuaPlayer, defines.inventory.character_guns)
  saveInventory(invGlobal, LuaPlayer, defines.inventory.character_ammo)
  saveInventory(invGlobal, LuaPlayer, defines.inventory.character_armor)
  saveInventory(invGlobal, LuaPlayer, defines.inventory.character_trash)
  ritnlib.utils.ritnLog(">> (debug) - function inventory : saveAllInventory -> ok")
end

--New Get
local function load_all_inventory(LuaPlayer, invGlobal)
  loadInventory(invGlobal, LuaPlayer, defines.inventory.character_armor) -- fix 1.4.51
  loadInventory(invGlobal, LuaPlayer, defines.inventory.character_main)
  loadInventory(invGlobal, LuaPlayer, defines.inventory.character_guns)
  loadInventory(invGlobal, LuaPlayer, defines.inventory.character_ammo)
  loadInventory(invGlobal, LuaPlayer, defines.inventory.character_trash)
  ritnlib.utils.ritnLog(">> (debug) - function inventory : loadAllInventory -> ok")
end


------------------------------------------------------------------------------------------
-- LOGISTIC
------------------------------------------------------------------------------------------
-- Save Logistic
local function saveLogistic(LuaPlayer, invGlobal)
  -- Demande logistique
  local slot_count = LuaPlayer.character.request_slot_count -- Correctif pour la v1.1
  invGlobal["logistic_param"] = {
    {name="slot_count", value = slot_count},
    {name="character_personal_logistic_requests_enabled", value = LuaPlayer.character_personal_logistic_requests_enabled}
  }
  invGlobal["logistic_inv"] = {}
  if slot_count > 0 then 
    for slot_index=1,slot_count do 
      local logistic_slot = LuaPlayer.get_personal_logistic_slot(slot_index)
      table.insert(invGlobal["logistic_inv"], logistic_slot)
      LuaPlayer.clear_personal_logistic_slot(slot_index)
    end
  else 
    invGlobal["logistic_inv"] = nil
  end
  ritnlib.utils.ritnLog(">> (debug) - function inventory : savelogistic -> ok")
end

-- Load Logistic
local function loadLogistic(LuaPlayer, invGlobal)
  local slot_count = 0
  if invGlobal["logistic_param"] ~= nil then
    LuaPlayer.character_personal_logistic_requests_enabled = invGlobal["logistic_param"][2].value
    if invGlobal["logistic_param"][1].value ~= 0 then
      slot_count = invGlobal["logistic_param"][1].value
    end
  end
  if invGlobal["logistic_inv"] ~= nil then 
    if slot_count ~= 0 then
      local inv = invGlobal["logistic_inv"]
      for slot_index,slot in pairs(inv) do
        local value = {name = slot.name, min = slot.min, max = slot.max}
        local result = LuaPlayer.set_personal_logistic_slot(slot_index, value)
      end
    end
  end
  ritnlib.utils.ritnLog(">> (debug) - function inventory : loadLogistic -> ok")
end

------------------------------------------------------------------------------------------
-- CURSOR
------------------------------------------------------------------------------------------
-- Save Cursor
local function saveCursor(LuaPlayer, invGlobal)
  local stack = LuaPlayer.cursor_stack
  if stack.valid then
    invGlobal["cursor"][1].swap_stack(stack)
  end
  ritnlib.utils.ritnLog(">> (debug) - function inventory : saveCursor -> ok")
end

-- Load Cursor
local function loadCursor(LuaPlayer, invGlobal)
  local stack = invGlobal["cursor"][1]
  if stack.valid then
    LuaPlayer.cursor_stack.swap_stack(stack)
  end
  ritnlib.utils.ritnLog(">> (debug) - function inventory : loadCursor -> ok")
end

------------------------------------------------------------------------------------------
-- Cancel All Crafting
local function cancel_all_crafting(LuaPlayer)
  local len = LuaPlayer.crafting_queue_size
  if len > 0 then
    pcall(function()
      for i,craft in pairs(LuaPlayer.crafting_queue) do
        local options = {index=craft.index, count=craft.count}
        LuaPlayer.cancel_crafting(options)
      end
      ritnlib.utils.ritnLog(">> (debug) - function inventory : cancel_all_crafting -> ok")
    end)
  end
  
end

------------------------------------------------------------------------------------------

--- SAVE
local function save(LuaPlayer, invGlobal)
  -- No characters
  if LuaPlayer.character == nil then return end

  -- init data inventory (global)
  if not invGlobal then
    invGlobal = initInventory()
  end

  cancel_all_crafting(LuaPlayer)
  save_all_inventory(LuaPlayer, invGlobal)
  saveCursor(LuaPlayer, invGlobal)
  saveLogistic(LuaPlayer, invGlobal)
  ritnlib.utils.ritnLog(">> (debug) - function inventory : SAVE -> ok")
end

--- LOAD
local function load(LuaPlayer, invGlobal)
  -- No characters
  if LuaPlayer.character == nil then return end

  -- init data inventory (global)
  if not invGlobal then
    invGlobal = initInventory()
  end

  load_all_inventory(LuaPlayer, invGlobal)
  loadCursor(LuaPlayer, invGlobal)
  loadLogistic(LuaPlayer, invGlobal)
  ritnlib.utils.ritnLog(">> (debug) - function inventory : LOAD -> ok")
end


-- fonction non local, renvoie le curseur dans l'inventaire principale
-- selon un nom de l'item et la surface où le joueur se trouve.
local function clearCursor(LuaPlayer, itemName)
  if LuaPlayer.surface.name == global.teleport.players[LuaPlayer.name].origine then return end
  if LuaPlayer.cursor_stack.count == 0 then return end
  
  local LuaItemStack = LuaPlayer.cursor_stack
  if LuaItemStack.name ~= itemName then 
    return
  else 
    LuaPlayer.clear_cursor()
    LuaPlayer.print(ritnmods.teleport.defines.name.caption.msg.cursor)
    ritnlib.utils.ritnLog(">> (debug) - function inventory : clear cursor -> ok")
  end
end


----------------------------
-- Chargement des fonctions
flib.init = initInventory
flib.save = save
flib.get = load
flib.clearCursor = clearCursor

-- Retourne la liste des fonctions
return flib