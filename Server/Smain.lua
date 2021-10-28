local Array = {}

if Config.UseEsx then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.CreateThread(function()
        Citizen.Wait(100)
        for k,v in pairs(Config.DefaultSpeakers) do
            table.insert(Array, v)
        end
    end)

    RegisterNetEvent('gacha_speaker:playSong', function(data)
        local xPlayer = ESX.GetPlayerFromId(source)
        local playerItem = xPlayer.getInventoryItem('speaker').count
        if playerItem ~= nil then
            if playerItem >= 1 then
                table.insert(Array, data)
                xPlayer.removeInventoryItem('speaker', 1)
                TriggerClientEvent('gacha_speaker:updateArray', -1, data)
            else
                xPlayer.showNotification('You need a speaker')
            end
        else
            xPlayer.showNotification('You need a speaker')
        end
    end)

    RegisterNetEvent('gacha_speaker:updateSong', function(data, index)
        TriggerClientEvent('gacha_speaker:updateSpeakerArray', -1, data, index)
    end)

    RegisterNetEvent('gacha_speaker:stopSong', function(index)
        Array[index].time = 0
        TriggerClientEvent('gacha_speaker:stopSong', -1, index)
    end)

    RegisterNetEvent('gacha_speaker:deleteSpeaker', function(index)
        local xPlayer = ESX.GetPlayerFromId(source)
        table.remove(Array, index)
        TriggerClientEvent('gacha_speaker:deleteSpeaker', -1, index)
        xPlayer.addInventoryItem('speaker', 1)
    end)

    ESX.RegisterServerCallback('gacha_speaker:getArray', function(source, cb)
        cb(Array)
    end)

    ESX.RegisterUsableItem('speaker', function(source)
        TriggerClientEvent('gacha_speaker:placeSpeaker', source)
    end)
else
    Citizen.CreateThread(function()
        Citizen.Wait(100)
        for k,v in pairs(Config.DefaultSpeakers) do
            table.insert(Array, v)
        end
    end)
    
    RegisterNetEvent('gacha_speaker:playSong', function(data)
        local Player = QBCore.Functions.GetPlayer(source)
        local playerItem = Player.Functions.GetItemByName("speaker")
        if playerItem ~= nil then
            if playerItem.amount >= 1 then
                table.insert(Array, data)
                Player.Functions.RemoveItem('speaker', 1)
                TriggerClientEvent('gacha_speaker:updateArray', -1, data)
            end
        else
            TriggerClientEvent("QBCore:Notify", source, "Necesitas un altavoz")
        end
    end)
    
    RegisterNetEvent('gacha_speaker:updateSong', function(data, index)
        TriggerClientEvent('gacha_speaker:updateSpeakerArray', -1, data, index)
    end)
    
    RegisterNetEvent('gacha_speaker:stopSong', function(index)
        Array[index].time = 0
        TriggerClientEvent('gacha_speaker:stopSong', -1, index)
    end)
    
    RegisterNetEvent('gacha_speaker:deleteSpeaker', function(index)
        local Player = QBCore.Functions.GetPlayer(source)
        table.remove(Array, index)
        TriggerClientEvent('gacha_speaker:deleteSpeaker', -1, index)
        Player.Functions.AddItem('speaker', 1)
    end)
    
    QBCore.Functions.CreateCallback('gacha_speaker:getArray', function(source, cb)
        cb(Array)
    end)
    
    QBCore.Functions.CreateUseableItem('speaker', function(source)
        TriggerClientEvent('gacha_speaker:placeSpeaker', source)
    end)
end