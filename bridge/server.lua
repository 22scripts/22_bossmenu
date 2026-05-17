Bridge = {}

local _ESX, _QB

if Config.Framework == 'esx' then
    if Config.ESXMode == 'old' then
        TriggerEvent('esx:getSharedObject', function(obj) _ESX = obj end)
    else
        _ESX = exports['es_extended']:getSharedObject()
    end
else
    _QB = exports['qb-core']:GetCoreObject()
end

function Bridge.RegisterCallback(name, cb)
    if Config.Framework == 'esx' then
        _ESX.RegisterServerCallback(name, function(source, callback, ...) cb(source, callback, ...) end)
    else
        _QB.Functions.CreateCallback(name, function(source, callback, ...) cb(source, callback, ...) end)
    end
end

function Bridge.GetIdentifier(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.identifier or nil
    else
        local p = _QB.Functions.GetPlayer(source)
        return p and p.PlayerData.citizenid or nil
    end
end

function Bridge.GetJob(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.job.name or 'unemployed'
    else
        local p = _QB.Functions.GetPlayer(source)
        return p and p.PlayerData.job.name or 'unemployed'
    end
end

function Bridge.GetJobGrade(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.job.grade or 0
    else
        local p = _QB.Functions.GetPlayer(source)
        return p and p.PlayerData.job.grade.level or 0
    end
end

function Bridge.GetJobGradeName(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.job.grade_name or ''
    else
        local p = _QB.Functions.GetPlayer(source)
        return p and p.PlayerData.job.grade.name or ''
    end
end

function Bridge.GetJobLabel(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.job.label or ''
    else
        local p = _QB.Functions.GetPlayer(source)
        return p and p.PlayerData.job.label or ''
    end
end

function Bridge.GetFullName(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.getName() or 'Unknown'
    else
        local p = _QB.Functions.GetPlayer(source)
        if not p then return 'Unknown' end
        local ci = p.PlayerData.charinfo
        return ci.firstname .. ' ' .. ci.lastname
    end
end

function Bridge.GetMoney(source)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        return p and p.getMoney() or 0
    else
        local p = _QB.Functions.GetPlayer(source)
        return p and p.Functions.GetMoney('cash') or 0
    end
end

function Bridge.RemoveMoney(source, amount)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        if p then p.removeMoney(amount) end
    else
        local p = _QB.Functions.GetPlayer(source)
        if p then p.Functions.RemoveMoney('cash', amount) end
    end
end

function Bridge.AddMoney(source, amount)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        if p then p.addMoney(amount) end
    else
        local p = _QB.Functions.GetPlayer(source)
        if p then p.Functions.AddMoney('cash', amount) end
    end
end

function Bridge.NotifyPlayer(source, msg, notifyType)
    if Config.Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', source, msg)
    elseif Config.Framework == 'qbox' then
        TriggerClientEvent('ox_lib:notify', source, { description = msg, type = notifyType or 'inform' })
    else
        TriggerClientEvent('QBCore:Notify', source, msg, notifyType or 'primary')
    end
end

-- Society account (shared between jobs)
function Bridge.GetSocietyMoney(jobName, cb)
    local account = 'society_' .. jobName
    if Config.Framework == 'esx' then
        TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
            cb(acc and acc.money or 0)
        end)
    else
        exports.oxmysql:scalar('SELECT money FROM addon_account_data WHERE account_name = ?', {account}, function(money)
            cb(money or 0)
        end)
    end
end

function Bridge.AddSocietyMoney(jobName, amount)
    local account = 'society_' .. jobName
    if Config.Framework == 'esx' then
        TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
            if acc then acc.addMoney(amount) end
        end)
    else
        exports.oxmysql:execute('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', {amount, account})
    end
end

function Bridge.RemoveSocietyMoney(jobName, amount, cb)
    local account = 'society_' .. jobName
    if Config.Framework == 'esx' then
        TriggerEvent('esx_addonaccount:getSharedAccount', account, function(acc)
            if acc and acc.money >= amount then
                acc.removeMoney(amount)
                cb(true)
            else
                cb(false)
            end
        end)
    else
        exports.oxmysql:scalar('SELECT money FROM addon_account_data WHERE account_name = ?', {account}, function(money)
            if money and money >= amount then
                exports.oxmysql:execute('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', {amount, account})
                cb(true)
            else
                cb(false)
            end
        end)
    end
end

-- Online players with a given job
function Bridge.GetPlayersWithJob(jobName)
    local result = {}
    if Config.Framework == 'esx' then
        for _, xP in pairs(_ESX.GetExtendedPlayers('job', jobName)) do
            table.insert(result, {
                source     = xP.source,
                identifier = xP.getIdentifier(),
                name       = xP.getName(),
                grade      = xP.job.grade,
                gradeName  = xP.job.grade_name
            })
        end
    else
        for _, player in pairs(_QB.Functions.GetQBPlayers()) do
            if player.PlayerData.job.name == jobName then
                local ci = player.PlayerData.charinfo
                table.insert(result, {
                    source     = player.PlayerData.source,
                    identifier = player.PlayerData.citizenid,
                    name       = ci.firstname .. ' ' .. ci.lastname,
                    grade      = player.PlayerData.job.grade.level,
                    gradeName  = player.PlayerData.job.grade.name
                })
            end
        end
    end
    return result
end

function Bridge.GetPlayerFromIdentifier(identifier)
    if Config.Framework == 'esx' then
        local xP = _ESX.GetPlayerFromIdentifier(identifier)
        return xP and xP.source or nil
    else
        for _, player in pairs(_QB.Functions.GetQBPlayers()) do
            if player.PlayerData.citizenid == identifier then
                return player.PlayerData.source
            end
        end
        return nil
    end
end

function Bridge.SetJob(source, jobName, grade)
    if Config.Framework == 'esx' then
        local p = _ESX.GetPlayerFromId(source)
        if p then p.setJob(jobName, grade or 0) end
    else
        local p = _QB.Functions.GetPlayer(source)
        if p then p.Functions.SetJob(jobName, grade or 0) end
    end
end

-- Employee count from DB
function Bridge.GetEmployeeCount(jobName, cb)
    if Config.Framework == 'esx' then
        exports.oxmysql:scalar('SELECT COUNT(*) FROM users WHERE job = ?', {jobName}, cb)
    else
        exports.oxmysql:scalar("SELECT COUNT(*) FROM players WHERE JSON_EXTRACT(job, '$.name') = ?", {jobName}, cb)
    end
end

-- All employees from DB (for offline list)
function Bridge.GetAllOfflineEmployees(jobName, cb)
    if Config.Framework == 'esx' then
        exports.oxmysql:execute(
            'SELECT firstname, lastname, identifier, job_grade FROM users WHERE job = ?',
            {jobName}, function(results)
                cb(results or {})
            end
        )
    else
        exports.oxmysql:execute(
            "SELECT citizenid, charinfo, job FROM players WHERE JSON_EXTRACT(job, '$.name') = ?",
            {jobName}, function(results)
                local employees = {}
                for _, row in ipairs(results or {}) do
                    local ci  = json.decode(row.charinfo) or {}
                    local job = json.decode(row.job) or {}
                    table.insert(employees, {
                        identifier = row.citizenid,
                        firstname  = ci.firstname or '',
                        lastname   = ci.lastname or '',
                        job_grade  = job.grade and job.grade.level or 0
                    })
                end
                cb(employees)
            end
        )
    end
end

-- Job grades (for salary/grade UI)
function Bridge.GetJobGrades(jobName, cb)
    if Config.Framework == 'esx' then
        exports.oxmysql:execute(
            'SELECT grade, label, salary FROM job_grades WHERE job_name = ? ORDER BY grade ASC',
            {jobName}, function(results)
                local grades = {}
                for _, row in ipairs(results or {}) do
                    table.insert(grades, { grade = row.grade, label = row.label, salary = row.salary })
                end
                cb(grades)
            end
        )
    else
        local grades = {}
        local sharedJob = _QB.Shared.Jobs[jobName]
        if sharedJob and sharedJob.grades then
            for level, data in pairs(sharedJob.grades) do
                table.insert(grades, { grade = tonumber(level), label = data.name, salary = data.payment or 0 })
            end
            table.sort(grades, function(a, b) return a.grade < b.grade end)
        end
        cb(grades)
    end
end

-- Fire employee (DB + online player)
function Bridge.FireEmployee(actorSrc, identifier, cb)
    if Config.Framework == 'esx' then
        exports.oxmysql:execute(
            'UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?',
            {'unemployed', 0, identifier}, function(info)
                local ok = info and info.affectedRows and info.affectedRows > 0
                if ok then
                    local targetSrc = Bridge.GetPlayerFromIdentifier(identifier)
                    if targetSrc then Bridge.SetJob(targetSrc, 'unemployed', 0) end
                end
                cb(ok)
            end
        )
    else
        exports.oxmysql:execute(
            "UPDATE players SET job = JSON_SET(job, '$.name', ?, '$.grade', JSON_OBJECT('level', 0, 'name', 'unemployed')) WHERE citizenid = ?",
            {'unemployed', identifier}, function(info)
                local ok = info and info.affectedRows and info.affectedRows > 0
                if ok then
                    local targetSrc = Bridge.GetPlayerFromIdentifier(identifier)
                    if targetSrc then Bridge.SetJob(targetSrc, 'unemployed', 0) end
                end
                cb(ok)
            end
        )
    end
end

-- Update employee grade (DB + online player)
function Bridge.UpdateEmployeeGrade(actorSrc, identifier, jobName, grade, cb)
    if Config.Framework == 'esx' then
        exports.oxmysql:execute(
            'UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?',
            {grade, identifier, jobName}, function(info)
                local ok = info and info.affectedRows and info.affectedRows > 0
                if ok then
                    local targetSrc = Bridge.GetPlayerFromIdentifier(identifier)
                    if targetSrc then Bridge.SetJob(targetSrc, jobName, grade) end
                end
                cb(ok)
            end
        )
    else
        local gradeName = ''
        if _QB.Shared.Jobs[jobName] and _QB.Shared.Jobs[jobName].grades[grade] then
            gradeName = _QB.Shared.Jobs[jobName].grades[grade].name or ''
        end
        exports.oxmysql:execute(
            "UPDATE players SET job = JSON_SET(job, '$.grade', JSON_OBJECT('level', ?, 'name', ?)) WHERE citizenid = ? AND JSON_EXTRACT(job, '$.name') = ?",
            {grade, gradeName, identifier, jobName}, function(info)
                local ok = info and info.affectedRows and info.affectedRows > 0
                if ok then
                    local targetSrc = Bridge.GetPlayerFromIdentifier(identifier)
                    if targetSrc then Bridge.SetJob(targetSrc, jobName, grade) end
                end
                cb(ok)
            end
        )
    end
end

-- Update salary (ESX: DB; QB: runtime only)
function Bridge.UpdateSalary(jobName, grade, salary, cb)
    if Config.Framework == 'esx' then
        exports.oxmysql:execute(
            'UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?',
            {salary, jobName, grade}, function(info)
                cb(info and info.affectedRows and info.affectedRows > 0)
            end
        )
    else
        if _QB.Shared.Jobs[jobName] and _QB.Shared.Jobs[jobName].grades[grade] then
            _QB.Shared.Jobs[jobName].grades[grade].payment = salary
        end
        cb(true)
    end
end

-- Job vehicles
function Bridge.GetJobVehicles(jobName, cb)
    local tbl = Config.Framework == 'esx' and 'owned_vehicles' or 'player_vehicles'
    exports.oxmysql:execute('SELECT plate, vehicle, type FROM ' .. tbl .. ' WHERE job = ?', {jobName}, function(results)
        local vehicles = {}
        for _, row in ipairs(results or {}) do
            local vData = row.vehicle and json.decode(row.vehicle) or {}
            table.insert(vehicles, { plate = row.plate, model = vData.model, type = row.type })
        end
        cb(vehicles)
    end)
end

-- Sell a job vehicle
function Bridge.SellVehicle(plate, jobName, sellPrice, cb)
    local tbl = Config.Framework == 'esx' and 'owned_vehicles' or 'player_vehicles'
    exports.oxmysql:execute(
        'DELETE FROM ' .. tbl .. ' WHERE plate = ? AND job = ?',
        {plate, jobName}, function(info)
            if info and info.affectedRows and info.affectedRows > 0 then
                Bridge.AddSocietyMoney(jobName, sellPrice)
                cb(true, 'Véhicule vendu avec succès !')
            else
                cb(false, 'Impossible de supprimer ce véhicule.')
            end
        end
    )
end
