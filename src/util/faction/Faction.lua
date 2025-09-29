-- Faction class for Fallout universe
local Faction = {}
Faction.__index = Faction

function Faction:new(args)
    args = args or {}
    local obj = {
        name = args.name or "Vault-Tec",
        longName = args.longName,
        abbreviation = args.abbreviation,
        leader = args.leader,
        motto = args.motto,
        foundedYear = args.foundedYear,
        headquarters = args.headquarters,
        rivalFactions = args.rivalFactions,
    }
    setmetatable(obj, self)
    return obj
end
function Faction:getMotto()
    if not self.motto or #self.motto == 0 then
        return "CORRUPTED DATA"
    end
    if type(self.motto) == "table" then
        if #self.motto == 1 then
            return self.motto[1]
        else
            local idx = math.random(1, #self.motto)
            return self.motto[idx]
        end
    end
    return self.motto
end

function Faction:getFoundedYear()
    return self.foundedYear or "CORRUPTED DATA"
end

function Faction:getHeadquarters()
    return self.headquarters or "CORRUPTED DATA"
end

function Faction:getRivalFactions()
    return self.rivalFactions or {"CORRUPTED DATA"}
end

function Faction:getSymbol()
    return self.symbol or "CORRUPTED DATA"
end

function Faction:getName()
    return self.name
end

function Faction:getLongName()
    return self.longName or "CORRUPTED DATA"
end

function Faction:getAbbreviation()
    return self.abbreviation or "CORRUPTED DATA"
end

function Faction:getLeader()
    return self.leader or "CORRUPTED DATA"
end

return Faction
