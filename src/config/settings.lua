-- Settings loader/saver for RobCoOS
local settings = {
    location = "VAULT 101",
    activeMenuOptions = {}
}

function settings:load()
    if fs.exists("/robco_settings") then
        local h = fs.open("/robco_settings", "r")
        local data = textutils.unserialize(h.readAll())
        h.close()
        if data then
            for k, v in pairs(data) do self[k] = v end
        end
    end
end

function settings:save()
    local data = {}
    for k, v in pairs(self) do
        if type(v) ~= "function" then
            data[k] = v
        end
    end
    local h = fs.open("/robco_settings", "w")
    h.write(textutils.serialize(data))
    h.close()
end

return settings
