local Speakers, isNotInRadio, neearSpeaker = {}, true, nil
if Config.UseEsx then
    ESX = nil
    
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
    end)
    AddEventHandler('onResourceStart', function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
        return
        end
        Citizen.Wait(500)
        ESX.TriggerServerCallback('gacha_speaker:getArray', function(array)
            Speakers = array
        end)
    end)
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function()
        ESX.TriggerServerCallback('gacha_speaker:getArray', function(array)
            Speakers = array
        end)
    end)

    RegisterNetEvent('gacha_speaker:updateArray')
    AddEventHandler('gacha_speaker:updateArray', function(data)
        table.insert(Speakers, data)
    end)

    RegisterNetEvent('gacha_speaker:updateSpeakerArray')
    AddEventHandler('gacha_speaker:updateSpeakerArray', function(data, index)
        Speakers[index].url = data.url
        Speakers[index].time = data.time
        Speakers[index].isPlaying = false
    end)

    RegisterNetEvent('gacha_speaker:stopSong')
    AddEventHandler('gacha_speaker:stopSong', function(index)
        Speakers[index].time = 0
        Speakers[index].isPlaying = false
    end)

    RegisterNetEvent('gacha_speaker:deleteSpeaker')
    AddEventHandler('gacha_speaker:deleteSpeaker', function(index)
        Speakers[index].time = 0
        Speakers[index].isPlaying = false
        Wait(100)
        table.remove(Speakers, index)
    end)

    RegisterNetEvent('gacha_speaker:placeSpeaker')
    AddEventHandler('gacha_speaker:placeSpeaker', function()
        local otherSpeakerNear
        for k,v in pairs(Speakers) do
            local distance = #(GetEntityCoords(PlayerPedId()) - vector3(v.coords.x, v.coords.y, v.coords.z))
            if distance <= Config.MaxDistance + 5.0 then
                otherSpeakerNear = true
            else
                otherSpeakerNear = false
            end
        end
        if otherSpeakerNear then
            ESX.ShowNotification('You cant place an speaker here beceause other speaker is near')
        else
            local playerPed = PlayerPedId()
            local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
            local objectCoords = (coords + forward * 1.0)
            local array = {coords = objectCoords, url = false, time = 0, isPlaying = false, default = false}
            SpawnObject()
            TriggerServerEvent('gacha_speaker:playSong', array)
        end
    end)

    RegisterNUICallback('exit', function()
        isNotInRadio = true
        SetNuiFocus(false, false)
    end)

    RegisterNUICallback('stopMusic', function()
        TriggerServerEvent('gacha_speaker:stopSong', neearSpeaker)
    end)

    RegisterNUICallback('playMusic', function(data)
        local array = {url = data.url, time = data.time, isPlaying = false}
        TriggerServerEvent('gacha_speaker:updateSong', array, neearSpeaker)
    end)

    Citizen.CreateThread(function()
        while true do
            local sleep = 500
            local playerCoords = GetEntityCoords(PlayerPedId())

            for k,v in pairs(Speakers) do
                if v.coords then
                    local distance = #(playerCoords - vector3(v.coords.x, v.coords.y, v.coords.z))
                    if distance < Config.MaxDistance then
                        sleep = 5
                        if v.isPlaying == false and v.url then
                            SendNUIMessage(
                                {
                                    play = true,
                                    song = v.url,
                                    time = v.time
                                }
                            )
                        end
                        SendNUIMessage(
                            {
                                volume = 100 - (distance * 100 / Config.MaxDistance)
                            }
                        )
                        if v.default and distance < 10 then
                            DrawMarker(20, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 10, 10, 10, 255, false, false, false, true, false, false, false)
                        end
                        v.isPlaying = true
                        if distance < 1.5 then
                            neearSpeaker = k
                            if v.default == false then
                                ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para acceder a la radio o BackSpace para recogerla")
                            else
                                ESX.ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para acceder a la radio")
                            end
                            if IsControlJustPressed(0, 38) then
                                isNotInRadio = false
                                SetNuiFocus(true, true)
                                SendNUIMessage({
                                    open = true
                                })
                            end
                            if IsControlJustPressed(0, 177) and isNotInRadio and v.default == false then
                                local object = GetClosestObjectOfType(playerCoords, 3.0, GetHashKey('prop_boombox_01'), false, false, false)
                                SetEntityAsMissionEntity(object, false, true)
                                DeleteObject(object)
                                TriggerServerEvent('gacha_speaker:deleteSpeaker', k)
                            end
                        end
                    elseif distance > Config.MaxDistance and v.isPlaying then
                        v.isPlaying = false
                        SendNUIMessage(
                            {
                                stop = true
                            }
                        )
                    end
                end
            end

            Citizen.Wait(sleep)
        end
    end)

    SpawnObject = function()
        if not HasAnimDictLoaded('anim@heists@money_grab@briefcase') then
            RequestAnimDict('anim@heists@money_grab@briefcase')

            while not HasAnimDictLoaded('anim@heists@money_grab@briefcase') do
                Citizen.Wait(1)
            end
        end
        TaskPlayAnim(PlayerPedId(), 'anim@heists@money_grab@briefcase', 'put_down_case', 8.0, -8.0, -1, 1, 0, false, false, false)
        Citizen.Wait(1000)
        ClearPedTasks(PlayerPedId())
        local model, modelHash = 'prop_boombox_01', GetHashKey('prop_boombox_01')
        if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
            RequestModel(modelHash)

            while not HasModelLoaded(modelHash) do
                Citizen.Wait(1)
            end
        end
        local playerPed = PlayerPedId()
        local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        local objectCoords = (coords + forward * 1.0)
        local obj = CreateObject(model, objectCoords, true, false, true)
        SetModelAsNoLongerNeeded(model)
        SetEntityHeading(obj, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(obj)
    end
else
    AddEventHandler('onResourceStart', function(resourceName)
        if (GetCurrentResourceName() ~= resourceName) then
        return
        end
        Citizen.Wait(500)
        QBCore.Functions.TriggerCallback('gacha_speaker:getArray', function(array)
            Speakers = array
        end)
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        QBCore.Functions.TriggerCallback('gacha_speaker:getArray', function(array)
            Speakers = array
        end)
    end)

    RegisterNetEvent('gacha_speaker:updateArray')
    AddEventHandler('gacha_speaker:updateArray', function(data)
        table.insert(Speakers, data)
    end)

    RegisterNetEvent('gacha_speaker:updateSpeakerArray')
    AddEventHandler('gacha_speaker:updateSpeakerArray', function(data, index)
        Speakers[index].url = data.url
        Speakers[index].time = data.time
        Speakers[index].isPlaying = false
    end)

    RegisterNetEvent('gacha_speaker:stopSong')
    AddEventHandler('gacha_speaker:stopSong', function(index)
        Speakers[index].time = 0
        Speakers[index].isPlaying = false
    end)

    RegisterNetEvent('gacha_speaker:deleteSpeaker')
    AddEventHandler('gacha_speaker:deleteSpeaker', function(index)
        Speakers[index].time = 0
        Speakers[index].isPlaying = false
        Wait(100)
        table.remove(Speakers, index)
    end)

    RegisterNetEvent('gacha_speaker:placeSpeaker')
    AddEventHandler('gacha_speaker:placeSpeaker', function()
        local otherSpeakerNear
        for k,v in pairs(Speakers) do
            local distance = #(GetEntityCoords(PlayerPedId()) - vector3(v.coords.x, v.coords.y, v.coords.z))
            if distance <= Config.MaxDistance + 5.0 then
                otherSpeakerNear = true
            else
                otherSpeakerNear = false
            end
        end
        if otherSpeakerNear then
            QBCore.Functions.Notify('You cant place an speaker here beceause other speaker is near')
        else
            local playerPed = PlayerPedId()
            local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
            local objectCoords = (coords + forward * 1.0)
            local array = {coords = objectCoords, url = false, time = 0, isPlaying = false, default = false}
            SpawnObject()
            TriggerServerEvent('gacha_speaker:playSong', array)
        end
    end)

    RegisterNUICallback('exit', function()
        isNotInRadio = true
        SetNuiFocus(false, false)
    end)

    RegisterNUICallback('stopMusic', function()
        TriggerServerEvent('gacha_speaker:stopSong', neearSpeaker)
    end)

    RegisterNUICallback('playMusic', function(data)
        local array = {url = data.url, time = data.time, isPlaying = false}
        TriggerServerEvent('gacha_speaker:updateSong', array, neearSpeaker)
    end)

    Citizen.CreateThread(function()
        while true do
            local sleep = 500
            local playerCoords = GetEntityCoords(PlayerPedId())

            for k,v in pairs(Speakers) do
                if v.coords then
                    local distance = #(playerCoords - vector3(v.coords.x, v.coords.y, v.coords.z))
                    if distance < Config.MaxDistance then
                        sleep = 5
                        if v.isPlaying == false and v.url then
                            SendNUIMessage(
                                {
                                    play = true,
                                    song = v.url,
                                    time = v.time
                                }
                            )
                        end
                        SendNUIMessage(
                            {
                                volume = 100 - (distance * 100 / Config.MaxDistance)
                            }
                        )
                        if v.default and distance < 10 then
                            DrawMarker(20, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 10, 10, 10, 255, false, false, false, true, false, false, false)
                        end
                        v.isPlaying = true
                        if distance < 1.5 then
                            neearSpeaker = k
                            if v.default == false then
                                QBCore.Functions.HelpNotify("Presiona ~INPUT_CONTEXT~ para acceder a la radio o BackSpace para recogerla")
                            else
                                QBCore.Functions.HelpNotify("Presiona ~INPUT_CONTEXT~ para acceder a la radio")
                            end
                            if IsControlJustPressed(0, 38) then
                                isNotInRadio = false
                                SetNuiFocus(true, true)
                                SendNUIMessage({
                                    open = true
                                })
                            end
                            if IsControlJustPressed(0, 177) and isNotInRadio and v.default == false then
                                local object = GetClosestObjectOfType(playerCoords, 3.0, GetHashKey('prop_boombox_01'), false, false, false)
                                SetEntityAsMissionEntity(object, false, true)
                                DeleteObject(object)
                                TriggerServerEvent('gacha_speaker:deleteSpeaker', k)
                            end
                        end
                    elseif distance > Config.MaxDistance and v.isPlaying then
                        v.isPlaying = false
                        SendNUIMessage(
                            {
                                stop = true
                            }
                        )
                    end
                end
            end

            Citizen.Wait(sleep)
        end
    end)

    SpawnObject = function()
        if not HasAnimDictLoaded('anim@heists@money_grab@briefcase') then
            RequestAnimDict('anim@heists@money_grab@briefcase')

            while not HasAnimDictLoaded('anim@heists@money_grab@briefcase') do
                Citizen.Wait(1)
            end
        end
        TaskPlayAnim(PlayerPedId(), 'anim@heists@money_grab@briefcase', 'put_down_case', 8.0, -8.0, -1, 1, 0, false, false, false)
        Citizen.Wait(1000)
        ClearPedTasks(PlayerPedId())
        local model, modelHash = 'prop_boombox_01', GetHashKey('prop_boombox_01')
        if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
            RequestModel(modelHash)

            while not HasModelLoaded(modelHash) do
                Citizen.Wait(1)
            end
        end
        local playerPed = PlayerPedId()
        local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        local objectCoords = (coords + forward * 1.0)
        local obj = CreateObject(model, objectCoords, true, false, true)
        SetModelAsNoLongerNeeded(model)
        SetEntityHeading(obj, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(obj)
    end
end