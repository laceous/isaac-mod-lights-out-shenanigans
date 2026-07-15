local mod = RegisterMod('Lights Out Shenanigans', 1)
local sfx = SFXManager()

-- current rule set:
--   2-state buttons, cross patterns, square boards, boards w/ and w/o edges
-- tutorials:
--   https://www.logicgamesonline.com/lightsout/tutorial.html
--   https://github.com/robert-wallis/LightsOut-6x6-Trainer
--   https://www.jaapsch.net/puzzles/lights.htm
if REPENTOGON then
  mod.rngShiftIdx = 35
  mod.square = '\u{f45c}'
  mod.diamond = '\u{f219}'
  mod.shape = mod.square
  mod.globalData = {}
  
  mod.pattern = { -- +
    topLeft = false,
    top = true,
    topRight = false,
    left = true,
    center = true,
    right = true,
    bottomLeft = false,
    bottom = true,
    bottomRight = false,
  }
  mod.squareSize = 50 -- 40, 50, 60
  mod.boardHasEdges = true
  mod.autoClear = false
  
  function mod:onModsLoaded()
    mod:setupImGui()
  end
  
  function mod:setupImGuiMenu()
    if not ImGui.ElementExists('shenanigansMenu') then
      ImGui.CreateMenu('shenanigansMenu', '\u{f6d1} Shenanigans')
    end
  end
  
  function mod:setupImGui()
    ImGui.AddElement('shenanigansMenu', 'shenanigansMenuItemLightsOut', ImGuiElement.MenuItem, '\u{f0eb} Lights Out Shenanigans')
    ImGui.CreateWindow('shenanigansWindowLightsOut', 'Lights Out Shenanigans')
    ImGui.LinkWindowToElement('shenanigansWindowLightsOut', 'shenanigansMenuItemLightsOut')
    
    ImGui.AddTabBar('shenanigansWindowLightsOut', 'shenanigansTabBarLightsOut')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut3x3', '3x3')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut4x4', '4x4')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut5x5', '5x5')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut6x6', '6x6')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut7x7', '7x7')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut8x8', '8x8')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut9x9', '9x9')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOutSettings', 'Settings')
    
    mod:setupBoard(3, 3)
    mod:setupBoard(4, 4)
    mod:setupBoard(5, 5)
    mod:setupBoard(6, 6)
    mod:setupBoard(7, 7)
    mod:setupBoard(8, 8)
    mod:setupBoard(9, 9)
    
    ImGui.AddElement('shenanigansTabLightsOutSettings', '', ImGuiElement.SeparatorText, 'Settings')
    ImGui.AddCombobox('shenanigansTabLightsOutSettings', 'shenanigansCmbLightsOutSettingAutoClear', 'Auto clear', function(i)
      mod.autoClear = i == 1
    end, { 'Off', 'On' }, mod.autoClear and 1 or 0, true)
    ImGui.SetHelpmarker('shenanigansCmbLightsOutSettingAutoClear', 'Automatically clear the debug console when you click the print solution or hint buttons')
    ImGui.AddCombobox('shenanigansTabLightsOutSettings', 'shenanigansCmbLightsOutSettingPattern', 'Pattern', nil, { '\u{f0fe} (default)', '\u{f0fe} (no center)', '\u{f0fe} (no edges)', '\u{f2d3} (default)', '\u{f2d3} (no center)', '\u{f2d3} (no edges)' }, 0, true)
    ImGui.AddCallback('shenanigansCmbLightsOutSettingPattern', ImGuiCallback.DeactivatedAfterEdit, function(i)
      -- the + (no center) variant causes the light chasing algorithm to auto solve every board
      if i >= 0 and i <= 2 then -- +
        mod.pattern.topLeft = false
        mod.pattern.top = true
        mod.pattern.topRight = false
        mod.pattern.left = true
        mod.pattern.center = i ~= 1
        mod.pattern.right = true
        mod.pattern.bottomLeft = false
        mod.pattern.bottom = true
        mod.pattern.bottomRight = false
        mod.shape = mod.square
        mod.boardHasEdges = i ~= 2
      else -- x
        mod.pattern.topLeft = true
        mod.pattern.top = false
        mod.pattern.topRight = true
        mod.pattern.left = false
        mod.pattern.center = i ~= 4
        mod.pattern.right = false
        mod.pattern.bottomLeft = true
        mod.pattern.bottom = false
        mod.pattern.bottomRight = true
        mod.shape = mod.diamond
        mod.boardHasEdges = i ~= 5
      end
      for _, v in ipairs({
                          { w = 3, h = 3 },
                          { w = 4, h = 4 },
                          { w = 5, h = 5 },
                          { w = 6, h = 6 },
                          { w = 7, h = 7 },
                          { w = 8, h = 8 },
                          { w = 9, h = 9 },
                        })
      do
        local s = 'LightsOut' .. v.w .. 'x' .. v.h
        mod:resetSquares(mod.globalData[s], s, v.w, v.h)
      end
    end)
    ImGui.SetHelpmarker('shenanigansCmbLightsOutSettingPattern', 'Changing this will reset your boards')
    ImGui.AddCombobox('shenanigansTabLightsOutSettings', 'shenanigansCmbLightsOutSettingSize', 'Size', nil, { 40, 50, 60 }, 1, true)
    ImGui.AddCallback('shenanigansCmbLightsOutSettingSize', ImGuiCallback.DeactivatedAfterEdit, function(_, s)
      mod.squareSize = tonumber(s)
      for _, v in ipairs({
                          { w = 3, h = 3 },
                          { w = 4, h = 4 },
                          { w = 5, h = 5 },
                          { w = 6, h = 6 },
                          { w = 7, h = 7 },
                          { w = 8, h = 8 },
                          { w = 9, h = 9 },
                        })
      do
        local s = 'LightsOut' .. v.w .. 'x' .. v.h
        for i = 1, v.w * v.h do
          ImGui.SetSize('shenanigansBtn' .. s .. '_' .. i, mod.squareSize, mod.squareSize)
        end
      end
    end)
  end
  
  function mod:setupBoard(w, h)
    local s = 'LightsOut' .. w .. 'x' .. h
    local tab = 'shenanigansTab' .. s
    
    local data = {}
    mod.globalData[s] = data
    
    local btnResetId = 'shenanigansBtn' .. s .. 'Reset'
    local btnRandomId = 'shenanigansBtn' .. s .. 'Random'
    local btnPrintId = 'shenanigansBtn' .. s .. 'Print'
    local btnHintId = 'shenanigansBtn' .. s .. 'Hint'
    
    ImGui.AddButton(tab, btnResetId, '\u{f0c8}', function()
      mod:resetSquares(data, s, w, h)
    end, false)
    ImGui.AddElement(tab, '', ImGuiElement.SameLine, '')
    ImGui.AddButton(tab, btnRandomId, '\u{f074}', function()
      -- first start with a solvable state, and then toggle squares in the same way as the player
      -- there are unsolvable configurations, this makes sure that we are always in a solvable state
      local rand = Random()
      local rng = RNG(rand <= 0 and 1 or rand, mod.rngShiftIdx)
      mod:resetSquares(data, s, w, h) -- we could also start with all empty squares
      repeat
        for i = 1, w * h do
          if rng:RandomFloat() < 0.5 then
            mod:toggleSquares(data, i, s, w, h)
          end
        end
      until not mod:isSuccess(data)
    end, false)
    ImGui.AddElement(tab, '', ImGuiElement.SameLine, '')
    ImGui.AddButton(tab, btnPrintId, '\u{f02f}', function()
      mod:printSolution(data, w, h, false)
    end, false)
    ImGui.AddElement(tab, '', ImGuiElement.SameLine, '')
    ImGui.AddButton(tab, btnHintId, '\u{f059}', function()
      mod:printSolution(data, w, h, true)
    end, false)
    ImGui.AddElement(tab, 'shenanigansSep' .. s, ImGuiElement.Separator, '')
    
    local i = 0
    for iH = 1, h do
      for iW = 1, w do
        i = i + 1
        local iLocal = i
        local btnId = 'shenanigansBtn' .. s .. '_' .. iLocal
        ImGui.AddButton(tab, btnId, mod.shape, function()
          mod:toggleSquares(data, iLocal, s, w, h)
          if mod:isSuccess(data) then
            ImGui.PushNotification('You win!', ImGuiNotificationType.SUCCESS, 5000)
            sfx:Play(SoundEffect.SOUND_MOM_VOX_FILTERED_DEATH_1)
          end
        end, false)
        ImGui.SetSize(btnId, mod.squareSize, mod.squareSize)
        if iW ~= w then
          ImGui.AddElement(tab, '', ImGuiElement.SameLine, '')
        end
      end
    end
    mod:resetSquares(data, s, w, h)
  end
  
  -- we want a solvable state after calling this function
  -- depending on the pattern, we might need to do something different here
  -- not all patterns support having all squares filled in at the start
  function mod:resetSquares(data, s, w, h)
    local total = w * h
    for i = 1, total do
      if (
           -- with a + pattern on an odd NxN board, if we don't toggle the clicked square then we need to leave the center square empty
           mod.boardHasEdges and
           not mod.pattern.topLeft and mod.pattern.top and not mod.pattern.topRight and
           mod.pattern.left and not mod.pattern.center and mod.pattern.right and
           not mod.pattern.bottomLeft and mod.pattern.bottom and not mod.pattern.bottomRight and
           total % 2 == 1 and math.ceil(total / 2) == i
         ) or
         (
           -- with an x pattern on 5x5 or 9x9, if we don't toggle the clicked square then we need to leave several squares empty
           -- you can fill in two additional squares by toggling the following positions after this loop is complete:
           --   total - math.floor(total / 2) - w - 1
           --   total - math.floor(total / 2) + w + 1
           mod.boardHasEdges and
           mod.pattern.topLeft and not mod.pattern.top and mod.pattern.topRight and
           not mod.pattern.left and not mod.pattern.center and not mod.pattern.right and
           mod.pattern.bottomLeft and not mod.pattern.bottom and mod.pattern.bottomRight and
           (w - 1) % 4 == 0 and -- assumes square board
           (
             (i + math.floor(w / 2)) % w == 0 or -- center column
             (i >= total - math.floor(total / 2) - math.floor(w / 2) and i <= total - math.floor(total / 2) + math.floor(w / 2)) -- center row
           )
         )
      then
        data[i] = false
        ImGui.UpdateText('shenanigansBtn' .. s .. '_' .. i, '')
      else
        data[i] = true
        ImGui.UpdateText('shenanigansBtn' .. s .. '_' .. i, mod.shape)
      end
    end
  end
  
  function mod:toggleSquares(data, i, s, w, h)
    local squareUpLeft = mod:getSquareUpLeft(i, w, h)
    local squareUp = mod:getSquareUp(i, w, h)
    local squareUpRight = mod:getSquareUpRight(i, w, h)
    local squareLeft = mod:getSquareLeft(i, w, h)
    local squareRight = mod:getSquareRight(i, w, h)
    local squareDownLeft = mod:getSquareDownLeft(i, w, h)
    local squareDown = mod:getSquareDown(i, w, h)
    local squareDownRight = mod:getSquareDownRight(i, w, h)
    for _, v in ipairs({
                        { cond = mod.pattern.topLeft and squareUpLeft, idx = squareUpLeft },
                        { cond = mod.pattern.top and squareUp, idx = squareUp },
                        { cond = mod.pattern.topRight and squareUpRight, idx = squareUpRight },
                        { cond = mod.pattern.left and squareLeft, idx = squareLeft },
                        { cond = mod.pattern.center, idx = i },
                        { cond = mod.pattern.right and squareRight, idx = squareRight },
                        { cond = mod.pattern.bottomLeft and squareDownLeft, idx = squareDownLeft },
                        { cond = mod.pattern.bottom and squareDown, idx = squareDown },
                        { cond = mod.pattern.bottomRight and squareDownRight, idx = squareDownRight },
                      })
    do
      if v.cond then
        data[v.idx] = not data[v.idx]
        if data[v.idx] then
          ImGui.UpdateText('shenanigansBtn' .. s .. '_' .. v.idx, mod.shape)
        else
          ImGui.UpdateText('shenanigansBtn' .. s .. '_' .. v.idx, '')
        end
      end
    end
  end
  
  function mod:printSolution(data, w, h, hintOnly)
    local total = w * h
    local matrix = {}
    for i = 1, total do
      table.insert(matrix, {})
    end
    for i = 1, total do
      local squareUpLeft = mod:getSquareUpLeft(i, w, h)
      local squareUp = mod:getSquareUp(i, w, h)
      local squareUpRight = mod:getSquareUpRight(i, w, h)
      local squareLeft = mod:getSquareLeft(i, w, h)
      local squareRight = mod:getSquareRight(i, w, h)
      local squareDownLeft = mod:getSquareDownLeft(i, w, h)
      local squareDown = mod:getSquareDown(i, w, h)
      local squareDownRight = mod:getSquareDownRight(i, w, h)
      for j = 1, total do
        if (mod.pattern.topLeft and j == squareUpLeft) or
           (mod.pattern.top and j == squareUp) or
           (mod.pattern.topRight and j == squareUpRight) or
           (mod.pattern.left and j == squareLeft) or
           (mod.pattern.center and j == i) or
           (mod.pattern.right and j == squareRight) or
           (mod.pattern.bottomLeft and j == squareDownLeft) or
           (mod.pattern.bottom and j == squareDown) or
           (mod.pattern.bottomRight and j == squareDownRight)
        then
          matrix[i][j] = 1
        else
          matrix[i][j] = 0
        end
      end
    end
    for i = 1, total do
      table.insert(matrix[i], data[i] and 1 or 0)
    end
    
    mod:doGaussJordanEliminationMod2(matrix)
    --[[
    for i = 1, #matrix do
      print(table.concat(matrix[i], ' '))
    end
    --]]
    
    if mod.autoClear then
      Isaac.ExecuteCommand('clear')
    end
    
    local solution = {}
    for i = 1, total do
      table.insert(solution, matrix[i][total + 1])
    end
    if hintOnly then
      local hints = {}
      for i, v in ipairs(solution) do
        if v ~= 0 then
          table.insert(hints, i)
        end
      end
      if #hints > 0 then
        local rand = Random()
        local rng = RNG(rand <= 0 and 1 or rand, mod.rngShiftIdx)
        local hint = hints[rng:RandomInt(#hints) + 1]
        for i = 1, #solution do
          if i ~= hint then
            solution[i] = 0
          end
        end
      end
      print('Hint (may not be optimal):')
    else
      print('Solution (may not be optimal):')
    end
    for i = 1, h do
      local start = ((i - 1) * w) + 1
      print(table.concat(solution, ' ', start, start + w - 1))
    end
  end
  
  -- thanks to linear algebra youtube for turning me onto this solution
  -- thanks to chatgpt for an initial lua example
  -- this is a mod 2 system so 1+1=0
  -- you can use either:
  --   gaussian elimination to put the matrix in row echelon form, solve via back substitution
  --   gauss jordan elimination to put the matrix in reduced row echelon form, check the final column
  -- gaussian elimination is slightly faster but the timescale is ridiculously small
  -- gauss jordan elimination had simpler code so i used that
  -- 4x4/5x5/9x9 struggle to find the optimal solution using this method when you get to the final row (+ pattern)
  -- another youtube video showed solving this via network theory to find the optimal solution
  -- that would likely require pre-generating data and increasing the size of the mod
  function mod:doGaussJordanEliminationMod2(matrix)
    local numRows = #matrix
    local numCols = #matrix[1]
    
    for i = 1, numRows do
      local pivot = i
      while pivot <= numRows and matrix[pivot][i] == 0 do
        pivot = pivot + 1
      end
      if pivot <= numRows then
        if pivot ~= i then
          matrix[i], matrix[pivot] = matrix[pivot], matrix[i]
        end
        for j = 1, numRows do
          if j ~= i and matrix[j][i] == 1 then
            for k = 1, numCols do
              matrix[j][k] = (matrix[j][k] + matrix[i][k]) % 2
            end
          end
        end
      end
    end
  end
  
  function mod:isSuccess(data)
    for _, v in pairs(data) do
      if v then
        return false
      end
    end
    return true
  end
  
  function mod:getSquareLeftOffset(i, w, h)
    if mod:hasSquareLeft(i, w, h) then
      return -1
    elseif not mod.boardHasEdges then
      return w - 1
    end
    return nil
  end
  
  function mod:getSquareLeft(i, w, h)
    local offset = mod:getSquareLeftOffset(i, w, h)
    if offset then
      return i + offset
    end
    return nil
  end
  
  function mod:getSquareRightOffset(i, w, h)
    if mod:hasSquareRight(i, w, h) then
      return 1
    elseif not mod.boardHasEdges then
      return -w + 1
    end
    return nil
  end
  
  function mod:getSquareRight(i, w, h)
    local offset = mod:getSquareRightOffset(i, w, h)
    if offset then
      return i + offset
    end
    return nil
  end
  
  function mod:getSquareUpOffset(i, w, h)
    if mod:hasSquareUp(i, w, h) then
      return -w
    elseif not mod.boardHasEdges then
      return w * (h - 1)
    end
    return nil
  end
  
  function mod:getSquareUp(i, w, h)
    local offset = mod:getSquareUpOffset(i, w, h)
    if offset then
      return i + offset
    end
    return nil
  end
  
  function mod:getSquareDownOffset(i, w, h)
    if mod:hasSquareDown(i, w, h) then
      return w
    elseif not mod.boardHasEdges then
      return -(w * (h - 1))
    end
  end
  
  function mod:getSquareDown(i, w, h)
    local offset = mod:getSquareDownOffset(i, w, h)
    if offset then
      return i + offset
    end
    return nil
  end
  
  function mod:getSquareUpLeft(i, w, h)
    local offsetUp = mod:getSquareUpOffset(i, w, h)
    local offsetLeft = mod:getSquareLeftOffset(i, w, h)
    if offsetUp and offsetLeft then
      return i + offsetUp + offsetLeft
    end
    return nil
  end
  
  function mod:getSquareUpRight(i, w, h)
    local offsetUp = mod:getSquareUpOffset(i, w, h)
    local offsetRight = mod:getSquareRightOffset(i, w, h)
    if offsetUp and offsetRight then
      return i + offsetUp + offsetRight
    end
    return nil
  end
  
  function mod:getSquareDownLeft(i, w, h)
    local offsetDown = mod:getSquareDownOffset(i, w, h)
    local offsetLeft = mod:getSquareLeftOffset(i, w, h)
    if offsetDown and offsetLeft then
      return i + offsetDown + offsetLeft
    end
    return nil
  end
  
  function mod:getSquareDownRight(i, w, h)
    local offsetDown = mod:getSquareDownOffset(i, w, h)
    local offsetRight = mod:getSquareRightOffset(i, w, h)
    if offsetDown and offsetRight then
      return i + offsetDown + offsetRight
    end
    return nil
  end
  
  function mod:hasSquareLeft(i, w, h)
    return (i - 1) % w ~= 0
  end
  
  function mod:hasSquareRight(i, w, h)
    return i % w ~= 0
  end
  
  function mod:hasSquareUp(i, w, h)
    return i - w > 0
  end
  
  function mod:hasSquareDown(i, w, h)
    return i + w <= w * h
  end
  
  mod:setupImGuiMenu()
  mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, mod.onModsLoaded)
end