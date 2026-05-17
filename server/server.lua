Locales = Locales or {}
local Locale = Config.Locale or 'fr'

local function _U(key, ...)
    local locale = Locales[Locale] or Locales['fr']
    if locale and locale[key] then
        return string.format(locale[key], ...)
    end
    return 'Translation [' .. Locale .. '][' .. key .. '] not found'
end

Bridge.RegisterCallback('menuboss:getDashboardData', function(source, cb, jobName)
    if Bridge.GetJob(source) ~= jobName or Bridge.GetJobGradeName(source) ~= 'boss' then
        cb(nil) return
    end
    Bridge.GetSocietyMoney(jobName, function(money)
        Bridge.GetEmployeeCount(jobName, function(count)
            cb({ money = money or 0, employeeCount = count or 0, companyName = Bridge.GetJobLabel(source) })
        end)
    end)
end)

Bridge.RegisterCallback('menuboss:depositMoney', function(source, cb, amount)
    if Bridge.GetMoney(source) >= amount then
        Bridge.RemoveMoney(source, amount)
        Bridge.AddSocietyMoney(Bridge.GetJob(source), amount)
        cb(true, 'Vous avez déposé $' .. amount)
    else
        cb(false, 'Vous n\'avez pas assez d\'argent.')
    end
end)

Bridge.RegisterCallback('menuboss:withdrawMoney', function(source, cb, amount)
    Bridge.RemoveSocietyMoney(Bridge.GetJob(source), amount, function(ok)
        if ok then
            Bridge.AddMoney(source, amount)
            cb(true, 'Vous avez retiré $' .. amount)
        else
            cb(false, 'La société n\'a pas assez d\'argent.')
        end
    end)
end)

Bridge.RegisterCallback('menuboss:getEmployees', function(source, cb, jobName)
    local onlinePlayers = Bridge.GetPlayersWithJob(jobName)
    local onlineIds     = {}
    local employees     = {}

    for _, p in ipairs(onlinePlayers) do
        onlineIds[p.identifier] = true
        table.insert(employees, { name = p.name, identifier = p.identifier, grade = p.gradeName, online = true })
    end

    Bridge.GetAllOfflineEmployees(jobName, function(results)
        for _, row in ipairs(results) do
            if not onlineIds[row.identifier] then
                table.insert(employees, {
                    name       = (row.firstname or '') .. ' ' .. (row.lastname or ''),
                    identifier = row.identifier,
                    grade      = tostring(row.job_grade),
                    online     = false
                })
            end
        end
        cb(employees)
    end)
end)

RegisterNetEvent('menuboss:fireEmployee')
AddEventHandler('menuboss:fireEmployee', function(identifier)
    local src = source
    if Bridge.GetJobGradeName(src) ~= 'boss' then return end
    Bridge.FireEmployee(src, identifier, function(ok)
        if ok then
            Bridge.NotifyPlayer(src, _U('employees_fired'), 'success')
            local targetSrc = Bridge.GetPlayerFromIdentifier(identifier)
            if targetSrc then Bridge.NotifyPlayer(targetSrc, _U('server_employee_fired_you'), 'error') end
        else
            Bridge.NotifyPlayer(src, _U('server_error_fire'), 'error')
        end
    end)
end)

RegisterNetEvent('menuboss:updateEmployeeGrade')
AddEventHandler('menuboss:updateEmployeeGrade', function(identifier, grade)
    local src     = source
    local jobName = Bridge.GetJob(src)
    if Bridge.GetJobGradeName(src) ~= 'boss' then return end
    Bridge.UpdateEmployeeGrade(src, identifier, jobName, grade, function(ok)
        if ok then
            Bridge.NotifyPlayer(src, _U('employees_grade_updated'), 'success')
            local targetSrc = Bridge.GetPlayerFromIdentifier(identifier)
            if targetSrc then Bridge.NotifyPlayer(targetSrc, _U('employees_grade_updated'), 'inform') end
        else
            Bridge.NotifyPlayer(src, _U('server_error_update_grade'), 'error')
        end
    end)
end)

Bridge.RegisterCallback('menuboss:getJobGrades', function(source, cb, jobName)
    Bridge.GetJobGrades(jobName, cb)
end)

RegisterNetEvent('menuboss:updateSalary')
AddEventHandler('menuboss:updateSalary', function(grade, salary)
    local src = source
    if Bridge.GetJobGradeName(src) ~= 'boss' then
        print(('menuboss: %s attempted to change salary without permission!'):format(tostring(Bridge.GetIdentifier(src))))
        return
    end
    if not grade or not salary then return end
    if salary < 50 then
        Bridge.NotifyPlayer(src, _U('grades_salary_min'), 'error') return
    end
    if salary > 250 then
        Bridge.NotifyPlayer(src, _U('grades_salary_max'), 'error') return
    end
    Bridge.UpdateSalary(Bridge.GetJob(src), grade, salary, function(ok)
        if not ok then Bridge.NotifyPlayer(src, _U('server_error_update_salary'), 'error') end
    end)
end)

Bridge.RegisterCallback('menuboss:getVehicles', function(source, cb, jobName)
    if Bridge.GetJob(source) ~= jobName or Bridge.GetJobGradeName(source) ~= 'boss' then
        cb({}) return
    end
    Bridge.GetJobVehicles(jobName, cb)
end)

Bridge.RegisterCallback('menuboss:sellVehicle', function(source, cb, plate, jobName)
    if Bridge.GetJob(source) ~= jobName or Bridge.GetJobGradeName(source) ~= 'boss' then
        cb(false, 'Action non autorisée.') return
    end
    Bridge.SellVehicle(plate, jobName, 10000, cb)
end)

Bridge.RegisterCallback('menuboss:getInvoices', function(source, cb, jobName)
    if Bridge.GetJob(source) ~= jobName or Bridge.GetJobGradeName(source) ~= 'boss' then
        cb({}) return
    end
    exports.oxmysql:execute('SELECT * FROM billing WHERE emitter = ? ORDER BY date DESC', {jobName}, function(invoices)
        cb(invoices or {})
    end)
end)
