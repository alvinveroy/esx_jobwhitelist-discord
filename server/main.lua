ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
local Token = "Bot "..Config.DiscordToken

function discordRequest(method, endpoint, jsondata)
    local data = nil
    PerformHttpRequest("https://discordapp.com/api/"..endpoint, function(errorCode, resultData, resultHeaders)
		data = {data=resultData, code=errorCode, headers=resultHeaders}
    end, method, #jsondata > 0 and json.encode(jsondata) or "", {["Content-Type"] = "application/json", ["Authorization"] = Token})

    while data == nil do
        Citizen.Wait(0)
    end
	
    return data
end

function checkRoles(user)
	local discordId = nil
	for _, id in ipairs(GetPlayerIdentifiers(user)) do
		if string.match(id, "discord:") then
			discordId = string.gsub(id, "discord:", "")
			print("Encontrado discord id: "..discordId)
			break
        end

    if discordId then
	    local endpoint = ("guilds/%s/members/%s"):format(Config.GuildId, discordId)
	    local member = discordRequest("GET", endpoint, {})
            if member.code == 200 then
		        local data = json.decode(member.data)
		        local roles = data.roles
		        local found = true
		        return roles
	        else
		        print("Please check if user exist in our discord server Error: "..member.data)
		        return false
	        end
	else
	    print("Please link your discord to your FiveM client.")
		return false
	end
end

function checkJob(name, grade, label)
    local whitelistedJobs = Config.whitelistedjobs
    local listedRoles = Config.Roles

    for _, v in ipairs(whitelistedJobs) do
        if v == label then
            --[[ check job name and grade ]]
            for index, value in pairs(listedRoles) do
                if value.job == name and value.grade == grade then
                    return value.id
                end
            end
        end
    end
    return nil    
end

function assignment(discordRoles)
    local listedRoles = Config.Roles
    for _job, v in pairs(listedRoles) do
        for index, value in ipairs(discordRoles) do
            if value == v.id then
                return _job
            end
        end
    end
    return nil
end

RegisterNetEvent('esx_jobwhitelist-discord:assignRoles')
AddEventHandler('esx_jobwhitelist-discord:assignRoles', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local whitelistedJobs = Config.whitelistedjobs
    local listedRoles = Config.Roles
    local designation = nil
    local targetJob = nil
    local doSetJob = nil
    targetJob = checkJob(xPlayer.job.name, xPlayer.job.grade, xPlayer.job.label)
    designation = checkRoles(source)
    doSetJob = assignment(designation)

    if doSetJob ~= nil then
        if listedRoles[doSetJob].job ~= xPlayer.job.name and listedRoles[doSetJob].grade ~= xPlayer.job.grade then
            xPlayer.setJob(listedRoles[doSetJob].job, listedRoles[doSetJob].grade)
        end
    else
        if targetJob ~= nil then
            xPlayer.setJob("unemployed", 0)
        end
    end

end)