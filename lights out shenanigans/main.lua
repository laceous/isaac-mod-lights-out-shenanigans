local mod = RegisterMod('Lights Out Shenanigans', 1)
local sfx = SFXManager()

-- tutorials:
-- https://www.logicgamesonline.com/lightsout/tutorial.html
-- https://github.com/robert-wallis/LightsOut-6x6-Trainer
if REPENTOGON then
  mod.rngShiftIdx = 35
  mod.square = '\u{f45c}'
  mod.diamond = '\u{f219}'
  mod.shape = mod.square
  mod.globalData = {}
  
  mod.pattern = {
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
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut2x2', '2x2')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut3x3', '3x3')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut4x4', '4x4')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut5x5', '5x5')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut6x6', '6x6')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut7x7', '7x7')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut8x8', '8x8')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOut9x9', '9x9')
    ImGui.AddTab('shenanigansTabBarLightsOut', 'shenanigansTabLightsOutSettings', 'Settings')
    
    mod:setupBoard(2, 2)
    mod:setupBoard(3, 3)
    mod:setupBoard(4, 4)
    mod:setupBoard(5, 5)
    mod:setupBoard(6, 6)
    mod:setupBoard(7, 7)
    mod:setupBoard(8, 8)
    mod:setupBoard(9, 9)
    
    ImGui.AddElement('shenanigansTabLightsOutSettings', '', ImGuiElement.SeparatorText, 'Settings')
    ImGui.AddCombobox('shenanigansTabLightsOutSettings', 'shenanigansCmbLightsOutSettingPattern', 'Pattern', nil, { '+', 'x' }, 0, true)
    ImGui.AddCallback('shenanigansCmbLightsOutSettingPattern', ImGuiCallback.DeactivatedAfterEdit, function(_, s)
      if s == '+' then
        mod.pattern.topLeft = false
        mod.pattern.top = true
        mod.pattern.topRight = false
        mod.pattern.left = true
        mod.pattern.center = true
        mod.pattern.right = true
        mod.pattern.bottomLeft = false
        mod.pattern.bottom = true
        mod.pattern.bottomRight = false
        mod.shape = mod.square
      else -- x
        mod.pattern.topLeft = true
        mod.pattern.top = false
        mod.pattern.topRight = true
        mod.pattern.left = false
        mod.pattern.center = true
        mod.pattern.right = false
        mod.pattern.bottomLeft = true
        mod.pattern.bottom = false
        mod.pattern.bottomRight = true
        mod.shape = mod.diamond
      end
      for _, v in ipairs({
                          { w = 2, h = 2 },
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
                          { w = 2, h = 2 },
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
    
    ImGui.AddButton(tab, btnResetId, '\u{f0c8}', function()
      mod:resetSquares(data, s, w, h)
    end, false)
    ImGui.AddElement(tab, '', ImGuiElement.SameLine, '')
    ImGui.AddButton(tab, btnRandomId, '\u{f074}', function()
      -- first start with a solvable state, and then toggle squares in the same way as the player
      -- there are unsolvable configurations, this makes sure that we are always in a solvable state
      local rand = Random()
      local rng = RNG(rand <= 0 and 1 or rand, mod.rngShiftIdx)
      mod:resetSquares(data, s, w, h)
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
      mod:printSolution(data, w, h)
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
  -- e.g. with a + pattern on an odd NxN board, if we don't toggle the clicked square then we need to leave the board's center square empty
  function mod:resetSquares(data, s, w, h)
    local total = w * h
    for i = 1, total do
      data[i] = true
      ImGui.UpdateText('shenanigansBtn' .. s .. '_' .. i, mod.shape)
    end
  end
  
  function mod:toggleSquares(data, i, s, w, h)
    local hasSquareLeft = mod:hasSquareLeft(i, w, h)
    local hasSquareRight = mod:hasSquareRight(i, w, h)
    local hasSquareUp = mod:hasSquareUp(i, w, h)
    local hasSquareDown = mod:hasSquareDown(i, w, h)
    for _, v in ipairs({
                        { cond = mod.pattern.topLeft and hasSquareUp and hasSquareLeft, idx = i - w - 1 },
                        { cond = mod.pattern.top and hasSquareUp, idx = i - w },
                        { cond = mod.pattern.topRight and hasSquareUp and hasSquareRight, idx = i - w + 1 },
                        { cond = mod.pattern.left and hasSquareLeft, idx = i - 1 },
                        { cond = mod.pattern.center, idx = i },
                        { cond = mod.pattern.right and hasSquareRight, idx = i + 1 },
                        { cond = mod.pattern.bottomLeft and hasSquareDown and hasSquareLeft, idx = i + w - 1 },
                        { cond = mod.pattern.bottom and hasSquareDown, idx = i + w },
                        { cond = mod.pattern.bottomRight and hasSquareDown and hasSquareRight, idx = i + w + 1 },
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
  
  function mod:printSolution(data, w, h)
    local total = w * h
    local matrix = {}
    for i = 1, total do
      table.insert(matrix, {})
    end
    for i = 1, total do
      local hasSquareLeft = mod:hasSquareLeft(i, w, h)
      local hasSquareRight = mod:hasSquareRight(i, w, h)
      local hasSquareUp = mod:hasSquareUp(i, w, h)
      local hasSquareDown = mod:hasSquareDown(i, w, h)
      for j = 1, total do
        if (mod.pattern.topLeft and hasSquareUp and hasSquareLeft and j == i - w - 1) or
           (mod.pattern.top and hasSquareUp and j == i - w) or
           (mod.pattern.topRight and hasSquareUp and hasSquareRight and j == i - w + 1) or
           (mod.pattern.left and hasSquareLeft and j == i - 1) or
           (mod.pattern.center and j == i) or
           (mod.pattern.right and hasSquareRight and j == i + 1) or
           (mod.pattern.bottomLeft and hasSquareDown and hasSquareLeft and j == i + w - 1) or
           (mod.pattern.bottom and hasSquareDown and j == i + w) or
           (mod.pattern.bottomRight and hasSquareDown and hasSquareRight and j == i + w + 1)
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
    
    print('Solution (may not be optimal):')
    local solution = {}
    for i = 1, total do
      table.insert(solution, matrix[i][total + 1])
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
  -- 4x4/5x5/9x9 struggle to find the optimal solution using this method when you get to the final row
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