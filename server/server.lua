ESX               = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterUsableItem('radio', function(source)

	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('gembul-radio:use', source)

end)


ESX.RegisterServerCallback('bz:itemkontrol', function(source, cb)
local src = source
local xPlayer = ESX.GetPlayerFromId(src)
local xRadyo = xPlayer.getInventoryItem('radio').count
cb(xRadyo, xRadyo2)
end)