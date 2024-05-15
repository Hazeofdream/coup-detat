local Coup = false
local Cooldown = false
local CooldownTime = nil
local CoupUsers = {}

util.AddNetworkString("notify_coup_success")
util.AddNetworkString("notify_coup_failure")

CreateConVar("sv_coup_chance_multiplier", 30, {FCVAR_NOTIFY}, "The multiplier added to the amount of users participating in a coup")
CreateConVar("sv_coup_cooldown", 10, {FCVAR_NOTIFY}, "The delay before initiating another coup d'etat (In minutes)")

-- reset the cooldown without requiring a command input automatically
if Cooldown then
    local NextCoup = CooldownTime + (GetConVar("sv_coup_cooldown"):GetInt() * 60)

    if CurTime() > CooldownTime + (GetConVar("sv_coup_cooldown"):GetInt() * 60) then
        Cooldown = false
        CooldownTime = nil
    end
end

local function VoteCoup(ply)
    -- store locally
    local mayors = {}
    local chiefs = {}

    -- cycle players and add the mayor
    for key, ply in pairs(player.GetAll()) do
        if ply:isMayor() then
            table.insert(mayors, ply)
        end
    end

    -- cycle players and add the mayor
    for key, ply in ipairs(player.GetAll()) do
        if ply:isChief() then
            table.insert(chiefs, ply)
        end
    end

    -- dont bother if a mayor doesn't exist
    if table.IsEmpty(mayors) then -- dont bother if a mayor doesn't exist
        DarkRP.notify(ply, 0, 4, "You can't initiate a coup against a non-existent leader!")
    return end

    -- can't initiate against yourself
    for key, mayor in pairs(mayors) do
        if ply == mayor then
            DarkRP.notify(ply, 0, 4, "You can't initiate a coup against yourself!")
            return ""
        end
     end

    -- only chiefs can initiate a coup
    if not ply:isChief() then
        DarkRP.notify(ply, 0, 4, "Only Chiefs can initate a coup!")
        return ""
   end

    -- cant initiate a coup in progress
    if Coup then
        DarkRP.notify(ply, 0, 4, "A coup is already in progress!")
        return ""
    end

    -- can't initiate before cooldown is complete
    if Cooldown then
        local NextCoup = CooldownTime + (GetConVar("sv_coup_cooldown"):GetInt() * 60)
        local GetTime = math.Round(NextCoup - CurTime())

        if CurTime() < NextCoup then
            DarkRP.notify(ply, 0, 6, string.format("You need to wait %s seconds before starting a coup!", GetTime))
        end

        return ""
    end

    local Mayor = mayors[1]

    Coup = true 
    CoupUsers = {ply}

    DarkRP.notify(ply, 0, 4, "You have started a coup d'etat")

    for k, chief in pairs(chiefs) do
        if chief ~= ply then
            local phrase = string.format("A coup was initiated against %s\nWould you like to participate?", Mayor:Nick())
            DarkRP.createQuestion(phrase, "coup_" .. tostring(k), chief, 30, function(choice) 

                if not IsValid(Mayor) then
                    DarkRP.notify(ply, 0, 4, "The Mayor has left the Server!")
                    Coup = false 
                    CoupUsers = {}
                return end

                local conv = tobool(choice)
                
                -- enter the user as a coup participant
                if conv then 
                    table.insert(CoupUsers, chief)
                    DarkRP.notify(chief, 0, 4, "You have entered the coup d'etat")
                end

                if not conv then
                    DarkRP.notify(chief, 0, 4, "You have not entered the coup d'etat")
                end
            end, ply, nil)
        end
    end

    timer.Create("coup_final_results", 30, 1, function()
        chance = #CoupUsers * GetConVar("sv_coup_chance_multiplier"):GetInt()

        Coup = false
        Cooldown = true
        CooldownTime = CurTime()

        local CoupLeader = CoupUsers[1]

        local num = math.random(1, 100)
        if num <= chance then -- vote passed
            CoupLeader:changeTeam(Mayor:Team(), true)

            Mayor:teamBan()
            Mayor:changeTeam(GAMEMODE.DefaultTeam, true)

            net.Start("notify_coup_success")
                net.WriteEntity(ply)
            net.Broadcast()
        else -- vote failed
            for k, chief in pairs(CoupUsers) do
                chief:teamBan()
                chief:changeTeam(GAMEMODE.DefaultTeam, true)

                timer.Simple(0.1, function() chief:wanted(nil, "Attempted a coup d'etat!", math.huge - 1) end)
            end

            net.Start("notify_coup_failure")
            net.Broadcast() 
        end
    end)

    return ""
end
DarkRP.defineChatCommand("coup", VoteCoup)