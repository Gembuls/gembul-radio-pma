ESX = nil
local PlayerData                = {}
local kanalnumara = {}

local myPedId = nil

local phoneProp = 0
local phoneModel = "prop_cs_hand_radio"

local currentStatus = 'out'
local lastDict = nil
local lastAnim = nil
local lastIsFreeze = false

local ANIMS = {
	['cellphone@'] = {
		['out'] = {
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_call_listen_base',
		},
		['text'] = {
			['out'] = 'cellphone_text_out',
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_text_to_call',
		},
		['call'] = {
			['out'] = 'cellphone_call_out',
			['text'] = 'cellphone_call_to_text',
			['call'] = 'cellphone_text_to_call',
		}
	},
	['anim@cellphone@in_car@ps'] = {
		['out'] = {
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_call_in',
		},
		['text'] = {
			['out'] = 'cellphone_text_out',
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_text_to_call',
		},
		['call'] = {
			['out'] = 'cellphone_horizontal_exit',
			['text'] = 'cellphone_call_to_text',
			['call'] = 'cellphone_text_to_call',
		}
	}
}

function newPhoneProp()
	deletePhone()
	RequestModel(phoneModel)
	while not HasModelLoaded(phoneModel) do
		Citizen.Wait(1)
	end
	phoneProp = CreateObject(phoneModel, 1.0, 1.0, 1.0, 1, 1, 0)
	local bone = GetPedBoneIndex(myPedId, 28422)
	AttachEntityToEntity(phoneProp, myPedId, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
end

function deletePhone ()
	Citizen.InvokeNative(0xAE3CBE5BF394C9C9 , Citizen.PointerValueIntInitialized(phoneProp))
end

function PhonePlayAnim (status, freeze, force)
	if currentStatus == status and force ~= true then
		return
	end

	myPedId = PlayerPedId()
	local freeze = freeze or false

	local dict = "cellphone@"
	if IsPedInAnyVehicle(myPedId, false) then
		dict = "anim@cellphone@in_car@ps"
	end
	loadAnimDict(dict)

	local anim = ANIMS[dict][currentStatus][status]
	if currentStatus ~= 'out' then
		StopAnimTask(myPedId, lastDict, lastAnim, 1.0)
		deletePhone()
	end
	local flag = 50
	if freeze == true then
		flag = 14
	end
	TaskPlayAnim(myPedId, dict, anim, 3.0, -1, -1, flag, 0, false, false, false)

	if status ~= 'out' and currentStatus == 'out' then
		Citizen.Wait(380)
		newPhoneProp()
	end

	lastDict = dict
	lastAnim = anim
	lastIsFreeze = freeze
	currentStatus = status

	if status == 'out' then
		Citizen.Wait(180)
		deletePhone()
		StopAnimTask(myPedId, lastDict, lastAnim, 1.0)
	end

end

function PhonePlayOut ()
	PhonePlayAnim('out')
end

function PhonePlayText ()
	PhonePlayAnim('text')
end

function PhonePlayCall (freeze)
	PhonePlayAnim('call', freeze)
end

function PhonePlayIn () 
	if currentStatus == 'out' then
		PhonePlayText()
	end
end

function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(1)
	end
end

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)


local radioMenu = false

function PrintChatMessage(text)
    TriggerEvent('chatMessage', "system", { 255, 0, 0 }, text)
end



function enableRadio(enable)

  SetNuiFocus(true, true)
  radioMenu = enable

  SendNUIMessage({

    type = "enableui",
    enable = enable

  })

  PhonePlayText()

end

RegisterNUICallback('joinRadio', function(data, cb)
    local _source       = source
    local PlayerData    = ESX.GetPlayerData(_source)
    local playerName    = GetPlayerName(PlayerId())

    if tonumber(data.channel) <= Config.RestrictedChannels then
        if (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance' or PlayerData.job.name == 'mechanic') then
            exports["pma-voice"]:SetRadioChannel(0)
            exports["pma-voice"]:SetRadioChannel(tonumber(data.channel))
            exports["pma-voice"]:SetMumbleProperty("radioEnabled", true)

            exports['mythic_notify']:SendAlert('inform', Config.messages['joined_to_radio'] .. data.channel .. '.00 MHz </b>')
        elseif not (PlayerData.job.name == 'police' or PlayerData.job.name == 'ambulance' or PlayerData.job.name == 'fire') then
            exports['mythic_notify']:SendAlert('error', Config.messages['restricted_channel_error'])
        end
    elseif tonumber(data.channel) > Config.RestrictedChannels then
        exports["pma-voice"]:SetRadioChannel(0)
        exports["pma-voice"]:SetRadioChannel(tonumber(data.channel))
        exports["pma-voice"]:SetMumbleProperty("radioEnabled", true)

        exports['mythic_notify']:SendAlert('inform', Config.messages['joined_to_radio'] .. data.channel .. '.00 MHz </b>')
    end

    cb('ok')
end)

RegisterNetEvent('radyokapat')
AddEventHandler('radyokapat', function(source)
	exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)

    cb('ok')
end)

RegisterNUICallback('leaveRadio', function(data, cb)
    exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)

    cb('ok')
end)

-- RegisterNUICallback('leaveRadio', function(data, cb)
--    local playerName = GetPlayerName(PlayerId())
--    local getPlayerRadioChannel = exports.saltychat:GetRadioChannel(true)

--     if getPlayerRadioChannel == "nil" then
--       TriggerEvent('notification', Config.messages['not_on_radio'], 2)
--         else
--           exports.saltychat:SetRadioChannel('', true)
--           TriggerEvent('notification', Config.messages['you_leave'] .. getPlayerRadioChannel .. ' MHz </b>', 2)
--     end

--    cb('ok')

-- end)

RegisterNUICallback('seskis', function(data, cb) 
    exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)

    cb('ok')
	TriggerEvent('notification', 'Telsiz Sesi Kısıldı.', 1)
end)

RegisterNUICallback('sesac', function(data, cb)
    exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)

    cb('ok')
	TriggerEvent('notification', 'Telsiz Sesi Açıldı.', 1)
end)

RegisterNUICallback('escape', function(data, cb)

    enableRadio(false)
    SetNuiFocus(false, false)
    SetNuiFocus(false)


    cb('ok')

    PhonePlayOut()
	  DeleteObject(phoneModel)
end)

-- net eventy
function radioyokla()
while true do
Citizen.Wait(1)
ESX.TriggerServerCallback('bz:itemkontrol', function(xRadyo, xRadyo2)
if xRadyo == 0 and xRadyo2 == 0 then
TriggerEvent('radyokapat')
end
end)
Citizen.Wait(5000)
end
end


RegisterNetEvent('tgds-radio:use')
AddEventHandler('tgds-radio:use', function()
  enableRadio(true)
  radioyokla()
end)

Citizen.CreateThread(function()
    while true do
        if radioMenu then
            DisableControlAction(0, 1, guiEnabled) -- LookLeftRight
            DisableControlAction(0, 2, guiEnabled) -- LookUpDown

            DisableControlAction(0, 142, guiEnabled) -- MeleeAttackAlternate

            DisableControlAction(0, 106, guiEnabled) -- VehicleMouseControlOverride

            if IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
                SendNUIMessage({
                    type = "click"
                })
            end
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('tgds-radio:close-radio')
AddEventHandler('tgds-radio:close-radio', function(player)
	exports["pma-voice"]:SetRadioChannel(0)
    exports["pma-voice"]:SetMumbleProperty("radioEnabled", false)

    cb('ok')

    if getPlayerRadioChannel ~= "nil" then
        exports["pma-voice"]:SetRadioChannel('', true)
        TriggerEvent('notification', Config.messages['you_leave'] .. getPlayerRadioChannel .. '.00 MHz </b>', 1)
    end
end)
