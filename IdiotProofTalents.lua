IdiotProofTalents = {}
IdiotProofTalents.version = { major = 1, minor = 0, build = 1, codename = "(Megalicious Multe) "}
IdiotProofTalents.options = {
    resetOnClose = true,
    resetOnSwappingTab = true,
}
IdiotProofTalents.applyQueue = {}
local defaultQueue = function(queue) if not queue then return IdiotProofTalents.applyQueue end return queue end
VirtualTalentTree = {}

function VirtualTalentTree:GetTalentInfo(virtual, tab, id)
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(tab, id);
    rank = rank + IdiotProofTalents:GetQueueTotal(virtual, tab, id)
    return name, iconTexture, tier, column, rank, maxRank, isExceptional, available
end

function VirtualTalentTree:PatchTalentButtonIfNeeded(name, parent)
    local virtualRank = _G[name]
    if not virtualRank then
        local fs = IdiotProofTalents.frame:CreateFontString("FontString", name, parent)
        fs:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
        fs:SetPoint("CENTER",parent:GetName(),"BOTTOMRIGHT", 0, 0)
        virtualRank = fs
    end
    return virtualRank
end

function VirtualTalentTree:PatchTalentButtons()
    for i = 1, MAX_NUM_TALENTS do
        local buttonName = "TalentFrameTalent" .. i
        local button = _G[buttonName]
        if button then
            local virtualRank = self:PatchTalentButtonIfNeeded(buttonName .. "VirtualRank" .. i, button)
        else
            IdiotProofTalents:Print("Could not find " .. buttonName)
        end
    end
end

function getAsNumber(x, defaultValue)
    if type(x) == "number" then return x end
    if not defaultValue then defaultValue = 0 end
    return tonumber(x) or getAsNumber(defaultValue)
end

function VirtualTalentTree:SetVirtualTalentRank(virtual, index)
    virtual = defaultQueue(virtual)
    local rankName = "TalentFrameTalent" .. index .. "Rank"
    local fontString = _G[rankName]
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = self:GetTalentInfo(virtual, PanelTemplates_GetSelectedTab(TalentFrame), index)
    -- IdiotProofTalents:Print("Setting " .. rankName .. " to " .. rank)
    
    if fontString and rank <= 0 then
        fontString:Hide()
        local border = _G[fontString:GetName().."Border"]
        if border then border:Hide() end
    elseif maxRank > 0 and fontString then
        fontString:SetText(rank)
        fontString:Show()
        local border = _G[fontString:GetName().."Border"]
        if border then border:Show() end
        if rank >= maxRank then
            fontString:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
        else
            fontString:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
        end
    end
end

function VirtualTalentTree:UpdateTalentTab(virtual, tab)
    for i = 1, MAX_NUM_TALENTS do
        local talentButton = _G["TalentFrameTalent" .. i]
        if talentButton then 
            _, _, maxRank = GetTalentInfo(tab, talentButton:GetID())
        end
        if type(maxRank) == "number" then 
            VirtualTalentTree:SetVirtualTalentRank(virtual, i)
        end
    end
end

IdiotProofTalents.learningEnabled = true
IdiotProofTalents.hooks = {}
IdiotProofTalents.frame = CreateFrame("Frame")

IdiotProofTalents.Apply = function(queue)
    local talentPoints = UnitCharacterPoints("player");
    queue = defaultQueue(queue)
    if (talentPoints >= 0 or IdiotProofTalents.learningEnabled ) and #queue > 0 then
        local entry = table.remove(queue, 1)
        local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(entry[1], entry[2]);
        local nameRankStr = name
        if(maxRank > 1) then nameRankStr = nameRankStr .. " (" .. (rank+1) .. "/" .. maxRank .. ")" end
        if rank >= maxRank or not available then
            IdiotProofTalents:Print("Attempting to learn " .. nameRankStr .. " but I don't think it'll work...")
        else
            IdiotProofTalents:Print("Attempting to learn " .. nameRankStr)
        end
        if IdiotProofTalents.learningEnabled then 
            LearnTalent(entry[1], entry[2])
            local _, _, _, _, newRank = GetTalentInfo(entry[1], entry[2]);
            if newRank > rank then
                local extra = ""
                if maxRank > 1 then
                    extra = extra .. string.format(" (%d / %d)", newRank, maxRank)
                end
                IdiotProofTalents:Print("Learnt " .. nameRankStr .. extra)
            end
        end
    end
end

IdiotProofTalents.Dump = function(what, level)
    if not level then level = 1 end
    if type(what) ~= "table" then IdiotProofTalents:Print("not a table") return end
    for k, v in pairs(what) do
        IdiotProofTalents:Print( tostring(k) .. "  => " .. tostring(v) )
        if type(v) == "table" then 
            -- IdiotProofTalents.Dump(v, level + 1)
        end
    end
end

IdiotProofTalents.Reset = function(queue)
    queue = defaultQueue(queue)
    while(#queue > 0) do table.remove(queue, 1) end
    IdiotProofTalents:UpdateState(queue)
    IdiotProofTalents:Print("Resetted talent planning.")
end

function IdiotProofTalents:CreateButton(n, text, x, onClick)
    local applyButton = _G[n] or CreateFrame("Button", n, TalentFrame, "UIPanelButtonTemplate")
    applyButton:SetText(text)
    --applyButton:SetFrameStrata("NORMAL")
    applyButton:SetWidth(60)
    applyButton:SetHeight(18)
    applyButton:SetScript("OnClick", onClick)
    applyButton:SetPoint("CENTER","TalentFrame","TOPLEFT", x, -420)
end


function IdiotProofTalents:CreateApplyButton()
    return self:CreateButton("TalentFrameApplyButton", "Apply", 45, IdiotProofTalents.Apply)
end

function IdiotProofTalents:CreateResetButton()
    return self:CreateButton("TalentFrameResetButton", "Reset", 105, function() IdiotProofTalents.Reset() end)
end

function IdiotProofTalents:UpdateButtons(queue)
    local buttons = { _G["TalentFrameResetButton"], _G["TalentFrameApplyButton"] }
    for k, v in pairs(buttons) do
        v:SetEnabled(#queue > 0)
    end
end

function IdiotProofTalents:GetQueueTotal(queue, talentTab, talentId)
    local matches = 0
    local highestMatch = -1
    for k, v in ipairs(queue) do
        if(v[1] == talentTab and v[2] == talentId) then
            if k > highestMatch then highestMatch = k end
            matches = matches + 1
        end
    end
    return matches, highestMatch
end

function IdiotProofTalents:TalentTabQueueTotal(queue, talentTab)
    local queuedPoints = 0
    for k, v in ipairs(queue) do
        if(v[1] == talentTab) then
            queuedPoints = queuedPoints + 1
        end
    end
    return queuedPoints
end

function IdiotProofTalents:TalentTabAllocatedTotal(queue, talentTab)
    local allocatedPoints = 0
    for i = 1, 20 do
        local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(talentTab, i);
        allocatedPoints = allocatedPoints + rank
    end
    return allocatedPoints
end

function IdiotProofTalents:TalentTabTotal(queue, talentTab)
    local allocated = self:TalentTabAllocatedTotal(queue, talentTab)
    local queued = self:TalentTabQueueTotal(queue, talentTab)
    return allocated + queued, allocated, queued
end

function IdiotProofTalents:TalentQueueTotal(talentTab, talentId)
    local queue = defaultQueue(queue)
    local queued = self:GetQueueTotal(queue, talentTab, talentId)
    
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(talentTab, talentId);
    
    return queued, rank, maxRank
end

function IdiotProofTalents:Colourize(text, colour)
    local colourText = colour
    if colour == "RED" then colourText = "FFEF1212" end
    if colour == "GREEN" then colourText = "FF12EF12" end
    if colour == "BLUE" then colourText = "FF1212EF" end
    if colour == "LIGHTBLUE" then colourText = "FF5252EF" end
    if colour == "RB" then colourText = "FFEF12EF" end
    if colour == "YELLOW" then colourText = "FFEFEF12" end
    if colour == "CYAN" then colourText = "FF12EFEF" end
    if colour == "WHITE" then colourText = "FFFFFFEF" end
    return "|c" .. colourText .. text .. "|r"
end

function IdiotProofTalents:Print(msg)
    ChatFrame1:AddMessage(self:Colourize("TCS", "GREEN") .. ": " .. tostring(msg), 1, 1, 0)
end

function IdiotProofTalents:CanItBeQueued(queue, talentTab, talentId)
    -- Check prerequisites
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(talentTab, talentId)
    local totalPoints = self:TalentTabTotal(queue, talentTab)
    local pointsNeeded = (tier - 1) * 5 
    if totalPoints < pointsNeeded then
        return false, "need to invest more in lower talents - currently have " .. totalPoints .. " and need " .. pointsNeeded
    end
    local tier, column = GetTalentPrereqs(talentTab, talentId)    
    if tier and column then 
        local prereqId = TALENT_BRANCH_ARRAY[tier][column].id
        local queued, rank, maxRank = self:TalentQueueTotal(talentTab, prereqId)
        
        if queued + rank < maxRank then
            local prereqName = GetTalentInfo(talentTab, prereqId)
            return false, "need to invest in prerequisite talent " .. prereqName
        end
    end
    return true, ""
end

function IdiotProofTalents:UpdateState(queue, talentTab)
    VirtualTalentTree:UpdateTalentTab(queue, PanelTemplates_GetSelectedTab(TalentFrame))
    self:UpdateButtons(queue)
end


function IdiotProofTalents:AttemptToQueue(talentTab, talentId)
    local queue = IdiotProofTalents.applyQueue
    local canDo, message = self:CanItBeQueued(queue, talentTab, talentId)
    if not canDo then
        self:Print("You " ..  message)
        return false
    end
    local queued, rank, maxRank = self:TalentQueueTotal(talentTab, talentId)
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(talentTab, talentId);
    local maxStr = ""
    local adjustedQueued = queued + 1
    if queued + rank >= maxRank then
        adjustedQueued = maxRank - rank
    end
    if maxRank > 1 then
        maxStr = maxStr .. "(" .. self:Colourize(rank, "GREEN") .. "/" .. self:Colourize(adjustedQueued, "CYAN") .. "/" .. self:Colourize(maxRank, "YELLOW") .. ")"
    else
        if adjustedQueued > 0 then
            maxStr = "a pending point"
        else
            maxStr = "an allocated point"
        end
    end
    if queued + rank >= maxRank then
        IdiotProofTalents:Print("You already have the maximum ".. maxStr .. " in " .. name)
        return false
    end
    IdiotProofTalents:Print("You have allocated ".. maxStr .. " in " .. name)
    table.insert(queue, { talentTab, talentId })
    self:UpdateState(queue, talentTab)
    return true
end
function IdiotProofTalents:AttemptToDequeue(talentTab, talentId)
    local queue = IdiotProofTalents.applyQueue
    local _, highestMatch = IdiotProofTalents:GetQueueTotal(queue, talentTab, talentId)
    local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(talentTab, talentId);
    if highestMatch > -1 then
        -- TODO: verify that talents "above" remain valid
        -- TODO: replace spending on same or lower tier that is "above" in queue
        table.remove(IdiotProofTalents.applyQueue, highestMatch)
        IdiotProofTalents:Print("You have removed a point from " .. name)
        self:UpdateState(queue, talentTab)
        return true
    end
    return false
end

dumpValue = function(str, level)
    if type(str) ~= "table" then return str end
    if type(level) ~= "number" then level = 1 end
    local q = ""
    for i = 1, level do q = q .. "{" end
    for k, v in ipairs(str) do
        q = q .. tostring(k) .. " => " .. dumpValue(v, level + 1) .. "\n"
    end
    for i = 1, level do q = q .. "}" end
    return q
end


IdiotProofTalents.frame:SetScript("OnEvent", function(...)
    local parameters = { ... }
    local event = parameters[2]
    
    -- IdiotProofTalents:Print("DATA " .. dumpValue(parameters))
    
    if type(event) == "table" then parameters = event; event = parameters[1] end
    -- IdiotProofTalents:Print("Received event " .. event)
    if (type(IdiotProofTalents[event]) == "function") then
        table.remove(parameters, 1)
        table.remove(parameters, 1)
        IdiotProofTalents[event](unpack(parameters))
    end
end)
function IdiotProofTalents:RegisterEvent(event, func)
    IdiotProofTalents[event] = func
    IdiotProofTalents.frame:RegisterEvent(event)
end


IdiotProofTalents.funcs = {}

IdiotProofTalents.funcs.TalentUILoaded = function(queue)
    queue = defaultQueue(queue)
    IdiotProofTalents:Print("TalentUI loaded. Applying careful spending patch...")
    for i = 1, 20 do 
        local b = _G["TalentFrameTalent"..i] 
        b:SetScript("OnClick", IdiotProofTalents.TalentFrameTalent_OnClick)
    end
    IdiotProofTalents:CreateApplyButton()
    IdiotProofTalents:CreateResetButton()
    IdiotProofTalents:UpdateState(queue, PanelTemplates_GetSelectedTab(TalentFrame))
    VirtualTalentTree:PatchTalentButtons()
    for i = 1, 3 do
        _G["TalentFrameTab" .. i]:SetScript("OnClick", IdiotProofTalents.TalentFrameTab_OnClick)
    end
    TalentFrame:SetScript("OnShow", IdiotProofTalents.TalentFrame_OnShow)
    TalentFrame:SetScript("OnHide", IdiotProofTalents.TalentFrame_OnHide)
end
IdiotProofTalents.funcs.CHARACTER_POINTS_CHANGED = function()
    if TalentFrame and PanelTemplates_GetSelectedTab then
        IdiotProofTalents:UpdateState(IdiotProofTalents.applyQueue, PanelTemplates_GetSelectedTab(TalentFrame))
    end
end
IdiotProofTalents.funcs.ADDON_LOADED = function(addon)
    if(addon == "Blizzard_TalentUI") then
        IdiotProofTalents.funcs.TalentUILoaded()
    end
end

IdiotProofTalents.TalentFrameTab_OnClick = function(self)
    local old = _G["TalentFrameTab_OnClick"]
    if type(old) == "function" then old(self) end
    if IdiotProofTalents.options.resetOnSwappingTab then
        IdiotProofTalents.Reset(IdiotProofTalents.applyQueue)
    end
    IdiotProofTalents:UpdateState(IdiotProofTalents.applyQueue, PanelTemplates_GetSelectedTab(TalentFrame))
end

IdiotProofTalents.TalentFrame_OnShow = function()
    local old = _G["TalentFrame_OnShow"]
    if type(old) == "function" then old() end
    IdiotProofTalents:UpdateState(IdiotProofTalents.applyQueue, PanelTemplates_GetSelectedTab(TalentFrame))
end

IdiotProofTalents.TalentFrame_OnHide = function()
    local old = _G["TalentFrame_OnHide"]
    if type(old) == "function" then old() end
    if IdiotProofTalents.options.resetOnClose then
        IdiotProofTalents.Reset()
    end
end

if TalentFrameTalent_OnClick then 
    IdiotProofTalents.funcs.TalentUILoaded()
end

IdiotProofTalents:RegisterEvent("ADDON_LOADED", IdiotProofTalents.funcs.ADDON_LOADED)
IdiotProofTalents:RegisterEvent("CHARACTER_POINTS_CHANGED", IdiotProofTalents.funcs.CHARACTER_POINTS_CHANGED)

IdiotProofTalents.TalentFrameTalent_OnClick = function(self, mouseButton)
    local old = _G["TalentFrameTalent_OnClick"]
    
    local talentTab = PanelTemplates_GetSelectedTab(TalentFrame)
    local talentId = self:GetID()
    
    -- Check if shift is held and de-queue if held?

    if (mouseButton == "LeftButton") then 
        IdiotProofTalents:AttemptToQueue(talentTab, talentId)
    elseif (mouseButton == "RightButton") then 
        IdiotProofTalents:AttemptToDequeue(talentTab, talentId)
    end    
end


local v = IdiotProofTalents.version
IdiotProofTalents:Print(string.format("IdiotProofTalents version %d.%d [%d] %sloaded", v.major, v.minor, v.build, v.codename or ""))




