-- Admin class for RobCo OS
local Admin = {}
Admin.__index = Admin

function Admin:new(isAdmin)
    local obj = {
        isAdmin = isAdmin or false
    }
    setmetatable(obj, self)
    return obj
end

function Admin:grant()
    self.isAdmin = true
end

function Admin:revoke()
    self.isAdmin = false
end

function Admin:isAdminUser()
    return self.isAdmin
end

return Admin
