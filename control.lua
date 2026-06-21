script.on_event(defines.events.on_built_entity, function(event)
    HandlePlacedEntity(event)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    HandlePlacedEntity(event)
end)

script.on_event(defines.events.script_raised_built, function(event)
    HandlePlacedEntity(event)
end)

script.on_event(defines.events.script_raised_revive, function(event)
    HandlePlacedEntity(event)
end)

function HandlePlacedEntity(event)
    local ModularChest = {
        ["Tier1"] = {
            ["Size1"] = "modular-chest",
            ["horizontal"] = {
                ["Size6"] = "long-iron-chest",
                ["Size13"] = "long-iron-chest-1x13",
                ["Size20"] = "long-iron-chest-1x20",
                ["Size27"] = "long-iron-chest-1x27",
                ["Size34"] = "long-iron-chest-1x34",
                ["Size41"] = "long-iron-chest-1x41",
                ["Size48"] = "long-iron-chest-1x48",
                ["Size55"] = "long-iron-chest-1x55",
            },
            ["vertical"] = {
                ["Size6"] = "long-iron-chest-v",
                ["Size13"] = "long-iron-chest-v-1x13",
                ["Size20"] = "long-iron-chest-v-1x20",
                ["Size27"] = "long-iron-chest-v-1x27",
                ["Size34"] = "long-iron-chest-v-1x34",
                ["Size41"] = "long-iron-chest-v-1x41",
                ["Size48"] = "long-iron-chest-v-1x48",
                ["Size55"] = "long-iron-chest-v-1x55",
            },
        },
        ["Tier2"] = {
            ["Size1"] = "modular-steel-chest",
            ["horizontal"] = {
                ["Size6"] = "long-steel-chest",
                ["Size13"] = "long-steel-chest-1x13",
                ["Size20"] = "long-steel-chest-1x20",
                ["Size27"] = "long-steel-chest-1x27",
                ["Size34"] = "long-steel-chest-1x34",
                ["Size41"] = "long-steel-chest-1x41",
                ["Size48"] = "long-steel-chest-1x48",
                ["Size55"] = "long-steel-chest-1x55",
            },
            ["vertical"] = {
                ["Size6"] = "long-steel-chest-v",
                ["Size13"] = "long-steel-chest-v-1x13",
                ["Size20"] = "long-steel-chest-v-1x20",
                ["Size27"] = "long-steel-chest-v-1x27",
                ["Size34"] = "long-steel-chest-v-1x34",
                ["Size41"] = "long-steel-chest-v-1x41",
                ["Size48"] = "long-steel-chest-v-1x48",
                ["Size55"] = "long-steel-chest-v-1x55",
            },
        },
    }

    local CurrentChestTier

    for k, v in pairs(ModularChest) do
        if event.entity.name == ModularChest[k].Size1 then -- previously event.created_entity
            CurrentChestTier = k
        end
    end
    if CurrentChestTier == nil then
        return
    end

    local NewChestX = event.entity.position.x
    local NewChestY = event.entity.position.y
    local CurrentQuality = event.entity.quality.name

    --local CurrentSurface = game.players[event.player_index].surface
    local CurrentSurface = event.entity.surface
    -- Robot- and script-built entities do not always have a last_user.
    -- The entity itself always carries the force that the merged chest needs.
    local CurrentUserForce = event.entity.force

    local function FindChest(ChestName, Position)
        return CurrentSurface.find_entity(
            {name=ChestName, quality=CurrentQuality},
            Position
        )
    end

    function DestroyChest(Direction, OffsetPos)
    	local SearchX = 0
    	local SearchY = 0

    	if Direction == "horizontal" then
    		SearchX = -1
    	elseif Direction == "vertical" then
    		SearchY = -1
    	end

        local FoundChestSize

        local ChestInventory

        local ChestPosition = { NewChestX + (OffsetPos * SearchX), NewChestY + (OffsetPos * SearchY)}
        local FoundChest = FindChest(ModularChest[CurrentChestTier]["Size1"], ChestPosition)

        if FoundChest ~= nil then
            if FoundChest.can_be_destroyed() then
                ChestInventory = FoundChest.get_inventory(defines.inventory.chest).get_contents()
                FoundChest.destroy()
                return ChestInventory
            end
        end

        if FindChest(ModularChest[CurrentChestTier][Direction]["Size6"], ChestPosition) ~= nil then
            FoundChestSize = "Size6"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size13"], ChestPosition) ~= nil then
            FoundChestSize = "Size13"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size20"], ChestPosition) ~= nil then
            FoundChestSize = "Size20"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size27"], ChestPosition) ~= nil then
            FoundChestSize = "Size27"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size34"], ChestPosition) ~= nil then
            FoundChestSize = "Size34"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size41"], ChestPosition) ~= nil then
            FoundChestSize = "Size41"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size48"], ChestPosition) ~= nil then
            FoundChestSize = "Size48"
        elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size55"], ChestPosition) ~= nil then
            FoundChestSize = "Size55"
        else
            return ChestInventory
        end

        FoundChest = FindChest(ModularChest[CurrentChestTier][Direction][FoundChestSize], ChestPosition)
        if FoundChest.can_be_destroyed() then
            ChestInventory = FoundChest.get_inventory(defines.inventory.chest).get_contents()
            FoundChest.destroy()
        end

        return ChestInventory
    end

    function SpawnChest(Direction, LowPos, ChestSize, ChestInventories)
        local NewEntity
        local SizeName = "Size" .. ChestSize
    	local ChestName = ModularChest[CurrentChestTier][Direction][SizeName]

    	if Direction == "horizontal" then
    		NewEntity = CurrentSurface.create_entity(
			{
                name=ChestName,
                force=CurrentUserForce,
                quality=CurrentQuality,
                position={NewChestX - LowPos - (0.5 * ChestSize - 0.5), NewChestY}
    		})
    	elseif Direction == "vertical" then
    		NewEntity = CurrentSurface.create_entity(
			{
                name=ChestName,
                force=CurrentUserForce,
                quality=CurrentQuality,
                position={NewChestX, NewChestY - LowPos - (0.5 * ChestSize - 0.5)}
    		})
    	end

        for k, v in pairs(ChestInventories) do
            for key, value in pairs(v) do
                NewEntity.get_inventory(defines.inventory.chest).insert({
                    name=value.name,
                    count=value.count,
                    quality=value.quality
                })
            end
        end
    end

    function PlaceChest(Direction, ChestSize, TileArray, LowPos, HighPos)
    	local CurrentTestPos = LowPos
    	local ValidPosFound = false

    	--while no valid position for a new chest is found yet and you can still fit the chest inside the test area
    	while ValidPosFound == false and CurrentTestPos + ChestSize - 1 <= HighPos do
    		
    		--make sure you don't try to only use part of one chest to make a new one
    		local TestPos = CurrentTestPos
    		while TestPos < CurrentTestPos + ChestSize do
    			TestPos = TestPos + TileArray[TestPos]
    		end
    		TestPos = TestPos - 1

    		--if you only use whole chests replace the chests in the selected area with the new one
    		if TestPos == CurrentTestPos + ChestSize - 1 then
                local ChestInventories = {}
    			for i = CurrentTestPos, CurrentTestPos + ChestSize - 1 do
    				ChestInventories[i] = DestroyChest(Direction, i)
    			end
    			SpawnChest(Direction, CurrentTestPos, ChestSize, ChestInventories)
    			ValidPosFound = true
    		end

    		CurrentTestPos = CurrentTestPos + 1
    	end

    	return ValidPosFound
    end

    function CheckTotalLengthAll(Direction)
    	local SearchX = 0
    	local SearchY = 0

    	if Direction == "horizontal" then
    		SearchX = 1
    	elseif Direction == "vertical" then
    		SearchY = 1
    	end

    	local CurSearchPos = 0

    	local SearchArray = {}
    	for i = -55, 55 do
    		SearchArray[i] = 0
    	end


    	--create array with data about chests in the world around the newly placed chest
		for i = -54, 54 do
            local SearchPosition = { NewChestX - (i * SearchX), NewChestY - (i * SearchY)}
            if FindChest(ModularChest[CurrentChestTier]["Size1"], SearchPosition) ~= nil then
                SearchArray[i] = 1
            else
                if FindChest(ModularChest[CurrentChestTier][Direction]["Size6"], SearchPosition) ~= nil then
                    SearchArray[i] = 6
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size13"], SearchPosition) ~= nil then
                    SearchArray[i] = 13
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size20"], SearchPosition) ~= nil then
                    SearchArray[i] = 20
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size27"], SearchPosition) ~= nil then
                    SearchArray[i] = 27
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size34"], SearchPosition) ~= nil then
                    SearchArray[i] = 34
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size41"], SearchPosition) ~= nil then
                    SearchArray[i] = 41
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size48"], SearchPosition) ~= nil then
                    SearchArray[i] = 48
                elseif FindChest(ModularChest[CurrentChestTier][Direction]["Size55"], SearchPosition) ~= nil then
                    SearchArray[i] = 55
                end
            end
		end


		--local DebugText = ""
		--for i = -55, 55 do
		--	  DebugText = DebugText .. SearchArray[i]
		--end
		--game.print("Original: " .. DebugText)


    	local LowPos = 0
    	while SearchArray[LowPos - 1] ~= 0 do
    		LowPos = LowPos - 1
    	end

    	local HighPos = 0
    	while SearchArray[HighPos + 1] ~= 0 do
    		HighPos = HighPos + 1
    	end

		--game.print("Original Low: " .. LowPos)
    	--game.print("Original High: " .. HighPos)

    	local LargestChestFound = 1
    	for i = LowPos, HighPos do
    		if SearchArray[i] > LargestChestFound then
    			LargestChestFound = SearchArray[i]
    		end
    	end

    	local MaxNewChestSize = HighPos - LowPos + 1
    	if MaxNewChestSize >= 55 then
    		MaxNewChestSize = 55
    	elseif MaxNewChestSize >= 48 then
    		MaxNewChestSize = 48
    	elseif MaxNewChestSize >= 41 then
    		MaxNewChestSize = 41
    	elseif MaxNewChestSize >= 34 then
    		MaxNewChestSize = 34
    	elseif MaxNewChestSize >= 27 then
    		MaxNewChestSize = 27
    	elseif MaxNewChestSize >= 20 then
    		MaxNewChestSize = 20
    	elseif MaxNewChestSize >= 13 then
    		MaxNewChestSize = 13
    	elseif MaxNewChestSize >= 6 then
    		MaxNewChestSize = 6
    	else
    		MaxNewChestSize = 1
    	end

    	--game.print("Max New Chest Size: " .. MaxNewChestSize)

    	local ValidPosFound = false
    	while MaxNewChestSize >= 6 and ValidPosFound == false do

	    	if HighPos >= MaxNewChestSize then
	    		HighPos = MaxNewChestSize - 1
	    	end
	
	    	if LowPos * -(1) >= MaxNewChestSize then
	    		LowPos = (MaxNewChestSize - 1) * -(1)
	    	end
	
	    	--game.print("Iter1 Low: " .. LowPos)
	    	--game.print("Iter1 High: " .. HighPos)
	
	    	--game.print("Test1: " .. "MaxNewChestSize: " .. MaxNewChestSize .. " LowPos: " .. LowPos .. " HighPos: " .. HighPos)
	
	    	local CurrentSearchPos = 0
	
	    	while CurrentSearchPos <= HighPos do
	    		if SearchArray[CurrentSearchPos] == 1 then
	    			CurrentSearchPos = CurrentSearchPos + 1
	    		else
	    			local CurrentChestSize = SearchArray[CurrentSearchPos]
	    			local CaseNotFaulty = true
	    			for i = CurrentSearchPos, CurrentSearchPos + CurrentChestSize - 1 do
	    				if SearchArray[i] ~= CurrentChestSize or i > HighPos then
	    					HighPos = CurrentSearchPos - 1
	    					CaseNotFaulty = false
	    					break
	    				end
	    			end
	    			if CaseNotFaulty then
	    				CurrentSearchPos = CurrentSearchPos + CurrentChestSize
	    			end
	    		end
	    	end
	
	    	CurrentSearchPos = 0
	
	    	while CurrentSearchPos >= LowPos do
	    		if SearchArray[CurrentSearchPos] == 1 then
	    			CurrentSearchPos = CurrentSearchPos - 1
	    		else
	    			local CurrentChestSize = SearchArray[CurrentSearchPos]
	    			local CaseNotFaulty = true
	    			for i = CurrentSearchPos, CurrentSearchPos - CurrentChestSize + 1, -1 do
	    				if SearchArray[i] ~= CurrentChestSize or i < LowPos then
	    					LowPos = CurrentSearchPos + 1
	    					CaseNotFaulty = false
	    					break
	    				end
	    			end
	    			if CaseNotFaulty then
	    				CurrentSearchPos = CurrentSearchPos - CurrentChestSize
	    			end
	    		end
	    	end
	
	    	--game.print("Iter2 Low: " .. LowPos)
	    	--game.print("Iter2 High: " .. HighPos)
			
	    	if MaxNewChestSize <= HighPos - LowPos + 1 then
	    		--game.print("place chest called with chest size: " .. MaxNewChestSize)
	    		ValidPosFound = PlaceChest(Direction, MaxNewChestSize, SearchArray, LowPos, HighPos)
	    		--game.print(math.random(99999) .. " - ValidPosFound: " .. tostring(ValidPosFound))
	    		--game.print("Test2: " .. "MaxNewChestSize: " .. MaxNewChestSize .. " LowPos: " .. LowPos .. " HighPos: " .. HighPos)
	    		--game.print(SearchArray[-2] .. " " .. SearchArray[-1] .. " " .. SearchArray[0] .. " " .. SearchArray[1] .. " " .. SearchArray[2])
	    	end

	    	MaxNewChestSize = MaxNewChestSize - 7
	    end

	    return ValidPosFound
    end

    --"Main"--
    local NewChestPlaced = CheckTotalLengthAll("horizontal")
    if NewChestPlaced == false then
    	--game.print("Did not find horizontal chest to place, testing vertical")
    	CheckTotalLengthAll("vertical")
    end
end
    
