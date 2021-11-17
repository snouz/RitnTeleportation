---------------------------------------------------------------------------------------------
-- >>  GUI LOBBY
---------------------------------------------------------------------------------------------
local ritnlib = {}
ritnlib.utils =       require(ritnmods.teleport.defines.functions.utils)
ritnlib.inventory =   require(ritnmods.teleport.defines.functions.inventory)
ritnlib.player =     require(ritnmods.teleport.defines.functions.player)
---------------------------------------------------------------------------------------------
local ritnGui = {}
ritnGui.lobby =        require(ritnmods.teleport.defines.gui.lobby.GuiElements)
ritnGui.lobby.action = require(ritnmods.teleport.defines.gui.lobby.action)
---------------------------------------------------------------------------------------------
local prefix_lobby = ritnmods.teleport.defines.name.gui.prefix.lobby
local definesGuiLobby = ritnmods.teleport.defines.name.gui.lobby


-- Fonction : on_gui_click
local function on_gui_click(e)
    local element = e.element
    local LuaPlayer = game.players[e.player_index]
    local center = LuaPlayer.gui.center
    local LuaGui = center[prefix_lobby .. definesGuiLobby.flow_common]
    local pattern = "([^-]*)-?([^-]*)-?([^-]*)"
    local LuaGui_name = ""
    local click = {
      ui, element, name, action
    }
  
    -- Action de la frame : Gui_Lobby
    if LuaGui == nil then return end
    
    LuaGui_name = prefix_lobby .. definesGuiLobby.flow_common
    if LuaGui.name ~= LuaGui_name then return end
    if element == nil then return end
    if element.valid == false then return end
    -- récupération des informations lors du clique
    click.ui, click.element, click.name = string.match(element.name, pattern)
    click.action = click.element .. "-" .. click.name

    -- Actions
    if click.ui == "lobby" then
        if click.element ~= "button" then return end
        if not ritnGui.lobby.action[click.action] then return end
        ritnGui.lobby.action[click.action](LuaPlayer)
        return
    end


end


local function on_player_changed_surface(e)
  -- actualise TOUT les GUI lobby des joueurs sur les surfaces lobby
  for _,LuaPlayer in pairs(game.players) do 
    if LuaPlayer.connected and LuaPlayer.valid and LuaPlayer.character then 
      --if LuaPlayer.character.active == false then 
        local surface = LuaPlayer.surface.name
        if string.sub(surface, 1, 6) == "lobby~" then 
          ritnGui.lobby.open(LuaPlayer)
        end
      --end
    end
  end
end


-- Commandes : 
commands.add_command("accept", "<player>", 
  function (e)  

    local LuaPlayer = game.players[e.player_index]

    if e.parameter ~= nil then
      local playerSend = e.parameter
      if global.teleport.surfaces[LuaPlayer.name] then 
        if global.teleport.surfaces[LuaPlayer.name].request[playerSend] then
          if global.teleport.surfaces[LuaPlayer.name].request[playerSend].state == 1 then 
            local LuaSurface = game.surfaces[LuaPlayer.name]

            global.teleport.surfaces[LuaSurface.name].inventories[playerSend] = ritnlib.inventory.init()
            table.insert(global.teleport.surfaces[LuaSurface.name].origine, playerSend)

            -- Enregistrement de la surface d'origine
            if not global.teleport.players[playerSend] then 
              global.teleport.players[playerSend] = {origine = LuaSurface.name}
            end
            local origine = global.teleport.players[playerSend].origine

            -- Teleportation sur la surface du personnage.
            LuaPlayer = game.players[playerSend]
            ritnlib.inventory.save(LuaPlayer, global.teleport.surfaces[origine].inventories[LuaPlayer.name])
            LuaPlayer.teleport({0,0}, origine)
            LuaPlayer.character.active = true

            -- Arrive sans rien
            LuaPlayer.clear_items_inside()
            
            -- suppression de la request
            global.teleport.surfaces[LuaSurface.name].request[playerSend] = nil
            -- fermeture de la fenetre après la création de la map
            ritnGui.lobby.close(LuaPlayer)
          elseif global.teleport.surfaces[LuaPlayer.name].request[playerSend].state == 0 then 
            global.teleport.surfaces[LuaPlayer.name].request[playerSend] = nil
          end
        end
      end
    end

  end
)


commands.add_command("reject", "<player>", 
  function (e)  

    local LuaPlayer = game.players[e.player_index]

    if e.parameter ~= nil then
      local playerSend = e.parameter
      if global.teleport.surfaces[LuaPlayer.name] then 
        if global.teleport.surfaces[LuaPlayer.name].request[playerSend] then
          if global.teleport.surfaces[LuaPlayer.name].request[playerSend].state == 1 then 
            -- suppression de la request
            global.teleport.surfaces[LuaPlayer.name].request[playerSend] = nil
          end
        end
      end
    end

  end
)


commands.add_command("reject_all", "<player>", 
  function (e)  

    local LuaPlayer = game.players[e.player_index]

    if e.parameter ~= nil then
      local playerSend = e.parameter
      if global.teleport.surfaces[LuaPlayer.name] then 
        if global.teleport.surfaces[LuaPlayer.name].request[playerSend] then
          if global.teleport.surfaces[LuaPlayer.name].request[playerSend].state == 1 then 
            -- suppression de la request
            global.teleport.surfaces[LuaPlayer.name].request[playerSend].state = 0
            global.teleport.surfaces[LuaPlayer.name].request[playerSend].reject_all=true
          end
        end
      end
    end

  end
)




-- Creation du module
local module = {}
module.events = {}

-- Chargement des modules
module.events[defines.events.on_gui_click] = on_gui_click
module.events[defines.events.on_player_changed_surface] = on_player_changed_surface


return module