Bridge = {}

local PlayerData = {}
local _ESX, _QB

if Config.Framework == 'esx' then
    if Config.ESXMode == 'old' then
        TriggerEvent('esx:getSharedObject', function(obj) _ESX = obj end)
    else
        _ESX = exports['es_extended']:getSharedObject()
    end

    CreateThread(function()
        while _ESX == nil do Wait(50) end
        local data = _ESX.GetPlayerData()
        while not data or not data.job do Wait(50); data = _ESX.GetPlayerData() end
        PlayerData = data
    end)

    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(data) PlayerData = data end)
    AddEventHandler('esx:setJob',       function(job)  PlayerData.job = job end)
else
    _QB = exports['qb-core']:GetCoreObject()

    CreateThread(function() PlayerData = _QB.Functions.GetPlayerData() or {} end)
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = _QB.Functions.GetPlayerData() or {}
    end)
    AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
        PlayerData.job = job
    end)
end

function Bridge.GetJobName()
    return PlayerData.job and PlayerData.job.name or 'unemployed'
end

function Bridge.GetJobGrade()
    if Config.Framework == 'esx' then
        return PlayerData.job and PlayerData.job.grade or 0
    else
        return PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.level or 0
    end
end

function Bridge.GetJobGradeName()
    if Config.Framework == 'esx' then
        return PlayerData.job and PlayerData.job.grade_name or ''
    else
        return PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.name or ''
    end
end

function Bridge.GetJobLabel()
    return PlayerData.job and PlayerData.job.label or ''
end

function Bridge.Notify(msg, notifyType)
    if Config.Framework == 'esx' then
        _ESX.ShowNotification(msg)
    elseif Config.Framework == 'qbox' then
        exports.ox_lib:notify({ description = msg, type = notifyType or 'inform' })
    else
        _QB.Functions.Notify(msg, notifyType or 'primary')
    end
end

function Bridge.ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function Bridge.TriggerCallback(name, cb, ...)
    if Config.Framework == 'esx' then
        _ESX.TriggerServerCallback(name, cb, ...)
    else
        _QB.Functions.TriggerCallback(name, cb, ...)
    end
end
