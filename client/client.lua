Locales = Locales or {}
local Locale = Config.Locale or 'fr'

local function _U(key, ...)
    local locale = Locales[Locale] or Locales['fr']
    if locale and locale[key] then
        return string.format(locale[key], ...)
    end
    return 'Translation [' .. Locale .. '][' .. key .. '] not found'
end

local isUIOpen = false

local function OpenBossMenu()
    isUIOpen = true
    SetNuiFocus(true, true)

    local jobColors = Config.JobColors[Bridge.GetJobName()] or {
        primary = "#2c3e50", secondary = "#34495e",
        button = "#27ae60", buttonHover = "#2ecc71",
    }

    local translations = {}
    local locale = Locales[Locale] or Locales['fr']
    for k, v in pairs(locale) do translations[k] = v end

    SendNUIMessage({
        action = 'open',
        job    = Bridge.GetJobName(),
        colors = jobColors,
        locale = translations
    })
end

local function CloseBossMenu()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

CreateThread(function()
    while true do
        local time = 750
        local playerPos = GetEntityCoords(PlayerPedId())

        if not isUIOpen and Bridge.GetJobGradeName() == 'boss' then
            for jobName, coords in pairs(Config.BossLocations) do
                local dist = #(playerPos - vector3(coords.x, coords.y, coords.z))
                if dist <= 10 and Bridge.GetJobName() == jobName then
                    time = 1
                    DrawMarker(25, coords.x, coords.y, coords.z - 0.98,
                        0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5,
                        0, 0, 255, 80, false, true, 2, false, false, false, false)
                    if dist <= 1.5 then
                        Bridge.ShowHelpNotification(_U('help_open_menu'))
                        if IsControlJustPressed(0, 51) then
                            OpenBossMenu()
                        end
                    end
                end
            end
        else
            Wait(1000)
        end

        Wait(time)
    end
end)

RegisterNUICallback('closeUI', function(data, cb)
    CloseBossMenu()
    cb('ok')
end)

RegisterNUICallback('getDashboardData', function(data, cb)
    Bridge.TriggerCallback('menuboss:getDashboardData', function(dashboardData)
        cb(dashboardData)
    end, Bridge.GetJobName())
end)

RegisterNUICallback('depositMoney', function(data, cb)
    local amount = tonumber(data.amount)
    if amount and amount > 0 then
        Bridge.TriggerCallback('menuboss:depositMoney', function(success, message)
            cb({ success = success, message = message })
        end, amount)
    else
        cb({ success = false, message = 'Montant invalide.' })
    end
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    local amount = tonumber(data.amount)
    if amount and amount > 0 then
        Bridge.TriggerCallback('menuboss:withdrawMoney', function(success, message)
            cb({ success = success, message = message })
        end, amount)
    else
        cb({ success = false, message = 'Montant invalide.' })
    end
end)

RegisterNUICallback('getEmployees', function(data, cb)
    Bridge.TriggerCallback('menuboss:getEmployees', function(employees)
        cb(employees)
    end, Bridge.GetJobName())
end)

RegisterNUICallback('getInvoices', function(data, cb)
    Bridge.TriggerCallback('menuboss:getInvoices', function(invoices)
        cb(invoices)
    end, Bridge.GetJobName())
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    if data.identifier then
        TriggerServerEvent('menuboss:fireEmployee', data.identifier)
        cb({ success = true })
    else
        cb({ success = false, message = 'Employé invalide.' })
    end
end)

RegisterNUICallback('getJobGrades', function(data, cb)
    Bridge.TriggerCallback('menuboss:getJobGrades', function(grades)
        cb(grades)
    end, Bridge.GetJobName())
end)

RegisterNUICallback('updateSalary', function(data, cb)
    local grade  = tonumber(data.grade)
    local salary = tonumber(data.salary)
    if grade and salary then
        TriggerServerEvent('menuboss:updateSalary', grade, salary)
        cb({ success = true })
    else
        cb({ success = false, message = 'Données invalides.' })
    end
end)

RegisterNUICallback('updateEmployeeGrade', function(data, cb)
    local grade = tonumber(data.grade)
    if data.identifier and grade then
        TriggerServerEvent('menuboss:updateEmployeeGrade', data.identifier, grade)
        cb({ success = true })
    else
        cb({ success = false, message = 'Données invalides.' })
    end
end)

RegisterNUICallback('getVehicles', function(data, cb)
    Bridge.TriggerCallback('menuboss:getVehicles', function(vehicles)
        cb(vehicles)
    end, Bridge.GetJobName())
end)

RegisterNUICallback('sellVehicle', function(data, cb)
    if data.plate then
        Bridge.TriggerCallback('menuboss:sellVehicle', function(success, message)
            cb({ success = success, message = message })
        end, data.plate, Bridge.GetJobName())
    else
        cb({ success = false, message = 'Véhicule invalide.' })
    end
end)

RegisterNUICallback('getVehicleLabel', function(data, cb)
    local model = data.model
    if type(model) == 'string' then model = GetHashKey(model) end
    local display = GetDisplayNameFromVehicleModel(model)
    local label   = GetLabelText(display)
    if not label or label == 'NULL' or label == display then label = display end
    cb(label)
end)
