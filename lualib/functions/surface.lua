---
-- Fonction Surface
---
---------------------------------------------------------------------------------------------
local util =          require(ritnmods.teleport.defines.mods.vanilla.lib.util)
local crash_site =    require(ritnmods.teleport.defines.mods.vanilla.lib.CrashSite)
---------------------------------------------------------------------------------------------
local ritnlib = {}
ritnlib.utils =       require(ritnmods.teleport.defines.functions.utils)
ritnlib.seablock =    require(ritnmods.teleport.defines.mods.seablock)
ritnlib.player =      require(ritnmods.teleport.defines.functions.player)
ritnlib.inventory =   require(ritnmods.teleport.defines.functions.inventory)
---------------------------------------------------------------------------------------------
local prefix_enemy = ritnmods.teleport.defines.prefix.enemy

-- Système de cessé le feu avec les ennemies lors d'un changement d'état d'un joueur.
local function UpdateCeaseFires(LuaSurface)

  if global.teleport.surfaces[LuaSurface.name] then 

    local forces = {}
		table.insert(forces, "guides")
		if LuaSurface.name == "nauvis" then 
			table.insert(forces, "player")
		else 
			table.insert(forces, LuaSurface.name)
		end

    if global.teleport.surfaces[LuaSurface.name].map_used then 
      -- Map active
      for _,force in pairs(forces) do
        if game.forces[force] then 
          print(">> active enemy : " .. force)
          if LuaSurface.name == "nauvis" then 
            game.forces["enemy"].set_cease_fire(force, false)
          else 
            game.forces["enemy"].set_cease_fire(force, false)
            local enemy = prefix_enemy .. LuaSurface.name
            if game.forces[enemy] then 
              game.forces[enemy].set_cease_fire(force, false)
            end
          end
        end
      end
    else
      -- Map inactive
      for _,force in pairs(forces) do
        if game.forces[force] then 
          print(">> désactive enemy : " .. force)
          if LuaSurface.name == "nauvis" then 
            game.forces["enemy"].set_cease_fire(force, true)
          else 
            game.forces["enemy"].set_cease_fire(force, true)
            local enemy = prefix_enemy .. LuaSurface.name
            if game.forces[enemy] then 
              game.forces[enemy].set_cease_fire(force, true)
            end
          end
        end
      end
    end
  end

end


-- Fonction de creation d'un portail sur la surface
local function create_portal(LuaSurface, position, player_name, raiseBuilt, createBuildEffectSmoke)
    
    local raise_built = false
    local create_build_effect_smoke

    if raiseBuilt ~= nil then raise_built = raiseBuilt end
    if createBuildEffectSmoke ~= nil then create_build_effect_smoke = createBuildEffectSmoke end

    local LuaEntity = LuaSurface.create_entity({
        name = ritnmods.teleport.defines.name.entity.portal,
        position = position,
        force = player_name,
        raise_built = raise_built,
        player = player_name,
        create_build_effect_smoke = create_build_effect_smoke
    })

    return LuaEntity
end


-- Generation de la structure de données global de la surface du joueur.
local function generateSurface(LuaSurface)

  if LuaSurface.name == "nauvis" then 
    if global.teleport.surfaces["nauvis"] then return end
  end

  global.teleport.surfaces[LuaSurface.name] = {
    name = LuaSurface.name,
    exception = false,
    last_use = 0,
    map_used = false,
    origine = {},
    value = {
        portal = 0,
        id_portal = 0,
        teleporter = 0,
        id_teleporter = 0,
    },
    portals = {},
    teleporters = {},
    inventories = {},
    players = {},
    finish = settings.startup[ritnmods.teleport.defines.name.settings.restart].value,
  }

  if not global.teleport.surfaces[LuaSurface.name] then
    global.teleport.surface_value = global.teleport.surface_value + 1
  end

  print(">> (debug) - function : generateSurface ok !")
end

-- Ajoute un player dans la structure de donnée surface.player()
local function addPlayer(LuaPlayer)
  local LuaSurface = LuaPlayer.surface
  global.teleport.surfaces[LuaSurface.name].players[LuaPlayer.name] = {
    name = LuaPlayer.name,
    tp = true,
    tick = game.tick,
  }
  pcall(function()
    if global.teleport.surfaces[LuaSurface.name].players[LuaPlayer.name] then 
      print(">> player add '" .. LuaPlayer.name .. "' - Surface : " .. LuaSurface.name)
    end
  end)

  global.teleport.surfaces[LuaSurface.name].map_used = ritnlib.utils.tableBusy(global.teleport.surfaces[LuaSurface.name].players)
  UpdateCeaseFires(LuaSurface)
end

-- Supprime un player dans la structure de donnée surface.player()
local function removePlayer(LuaPlayer, oldSurface)
    for i,player in pairs(global.teleport.surfaces[oldSurface.name].players) do
      if global.teleport.surfaces[oldSurface.name].players[i].name == LuaPlayer.name then 
        global.teleport.surfaces[oldSurface.name].players[i] = nil
        pcall(function()
          if global.teleport.surfaces[oldSurface.name].players[i] == nil then 
            print(">> player removed '" .. LuaPlayer.name .. "' - Surface : " .. oldSurface.name)
          end
        end)
      end 
    end
    
    global.teleport.surfaces[oldSurface.name].map_used = ritnlib.utils.tableBusy(global.teleport.surfaces[oldSurface.name].players)
    UpdateCeaseFires(oldSurface)
end



-- Creation du Lobby d'un joueur
local function createLobby(e)

  local surface=e.surface
  local area=e.area
  local tv={}
  local t={}
  local tx
  local base_tile=1

  for x = area.left_top.x, area.right_bottom.x do 
      for y= area.left_top.y, area.right_bottom.y do
          if((x>-4 and x<3) and (y>-4 and y<3))then
              tx=tx or {} table.insert(tx,{name="refined-concrete",position={x,y}})
          else
              local tile="out-of-map"
              table.insert(t, {name=tile,position={x,y}}) tv[x]=tv[x] or {} tv[x][y]=true
          end
      end
  end

  surface.destroy_decoratives{area=area}
  if(tx)then surface.set_tiles(tx) end
  surface.set_tiles(t)
  for k,v in pairs(surface.find_entities_filtered{type="character",invert=true,area=area})do v.destroy{raise_destroy=true} end

end


-- Creation de la surface et force du joueur
local function createSurface(LuaPlayer)

        --return map_gen avec nouvelle seed
        local map_gen = ritnlib.utils.mapGeneratorNewSeed()

        local LuaSurface = game.create_surface(LuaPlayer.name, map_gen)  
        local tiles = {}
        
        for x=-1,1 do
          for y=-1,1 do
            table.insert(tiles, {name = "lab-white", position = {x, y}})
          end
        end
        
        LuaSurface.set_tiles(tiles) 
        local LuaForce = game.create_force(LuaPlayer.name)
        LuaForce.reset()
        LuaForce.research_queue_enabled = true
        LuaForce.chart(LuaSurface, {{x = -100, y = -100}, {x = 100, y = 100}})
        if game.active_mods["SeaBlock"] then  
          ritnlib.seablock.startMap(LuaSurface)
        end
        
        for k,v in pairs(game.forces) do
          if v.name ~= "enemy" and v.name ~= "neutral" then
            LuaForce.set_friend(v.name,true)
            game.forces["player"].set_friend(LuaForce.name, true)
          end
        end
  
        for r_name,recipe in pairs(LuaPlayer.force.recipes) do
          LuaForce.recipes[r_name].enabled = recipe.enabled
        end

        --Chargement des items
        LuaPlayer.clear_items_inside()
        local items_start_variantes = 1
        -- Variantes avec SpaceBlock
        if game.active_mods["spaceblock"] then
          items_start_variantes = 2
        end
        if game.active_mods["SeaBlock"] then
          items_start_variantes = 3
        end
        ritnlib.player.give_start_item(LuaPlayer, items_start_variantes)


        -- Creation de la structure de map dans les données
        generateSurface(game.surfaces.nauvis)
        global.teleport.surfaces["nauvis"].exception = true
        global.teleport.surfaces["nauvis"].map_used = true
        generateSurface(LuaSurface)
        global.teleport.surfaces[LuaSurface.name].exception = LuaPlayer.admin
        global.teleport.surfaces[LuaSurface.name].inventories[LuaPlayer.name] = ritnlib.inventory.init()
        table.insert(global.teleport.surfaces[LuaSurface.name].origine, LuaPlayer.name)

        -- 1.8.0
        -- Enregistrement de la surface d'origine
        if not global.teleport.players[LuaPlayer.name] then 
          global.teleport.players[LuaPlayer.name] = {origine = LuaSurface.name}
        end
        local origine = global.teleport.players[LuaPlayer.name].origine

        -- Teleportation sur la surface du personnage.
        ritnlib.inventory.save(LuaPlayer, global.teleport.surfaces[origine].inventories[LuaPlayer.name])
        LuaPlayer.teleport({0,0}, origine)
        
        
        -- Add Crash site :
        if items_start_variantes <= 1 then   
          crash_site.create_crash_site(LuaSurface, {-5,-6}, util.copy(global.crashed_ship_items), util.copy(global.crashed_debris_items))
          util.remove_safe(LuaPlayer, global.crashed_ship_items)
          util.remove_safe(LuaPlayer, global.crashed_debris_items)
        end

end



-- Test 1.8.0
commands.add_command("test", "<name>", 
  function (e)

    if e.player_index then 
      local LuaPlayer = game.players[e.player_index]
      if LuaPlayer.name == "Ritn" then
        if e.parameter ~= nil then
          local LuaPlayerFake = {
            name = e.parameter,
            admin = false,
            force = {},
          }
          
                  --return map_gen avec nouvelle seed
                  local map_gen = ritnlib.utils.mapGeneratorNewSeed()

                  local LuaSurface = game.create_surface(LuaPlayerFake.name, map_gen)  
                  local tiles = {}

                  LuaSurface.set_tiles(tiles) 
                  local LuaForce = game.create_force(LuaPlayerFake.name)
                  -- add force à LuaPlayerFake
                  LuaPlayerFake.force = LuaForce
                  --
                  LuaForce.reset()
                  LuaForce.research_queue_enabled = true
                  LuaForce.chart(LuaSurface, {{x = -100, y = -100}, {x = 100, y = 100}})
                  if game.active_mods["SeaBlock"] then  
                    ritnlib.seablock.startMap(LuaSurface)
                  end

                  for k,v in pairs(game.forces) do
                    if v.name ~= "enemy" and v.name ~= "neutral" then
                      LuaForce.set_friend(v.name,true)
                      game.forces["player"].set_friend(LuaForce.name, true)
                    end
                  end

                  for r_name,recipe in pairs(LuaPlayerFake.force.recipes) do
                    LuaForce.recipes[r_name].enabled = recipe.enabled
                  end

                  -- Creation de la structure de map dans les données
                  generateSurface(game.surfaces.nauvis)
                  global.teleport.surfaces["nauvis"].exception = true
                  global.teleport.surfaces["nauvis"].map_used = true
                  generateSurface(LuaSurface)
                  global.teleport.surfaces[LuaSurface.name].exception = LuaPlayerFake.admin
                  global.teleport.surfaces[LuaSurface.name].inventories[LuaPlayerFake.name] = ritnlib.inventory.init()
                  table.insert(global.teleport.surfaces[LuaSurface.name].origine, LuaPlayerFake.name)

                  -- 1.8.0
                  -- Enregistrement de la surface d'origine
                  if not global.teleport.players[LuaPlayerFake.name] then 
                    global.teleport.players[LuaPlayerFake.name] = {origine = LuaSurface.name}
                  end

          print(">> debug : function : test -> ok !")
        end
      end
    end
    
  end
)



----------------------------
-- Chargement des fonctions
local flib = {}
flib.create_portal = create_portal
flib.generateSurface = generateSurface
flib.addPlayer = addPlayer
flib.removePlayer = removePlayer
flib.UpdateCeaseFires = UpdateCeaseFires
flib.createLobby = createLobby
flib.createSurface = createSurface

-- Retourne la liste des fonctions
return flib







