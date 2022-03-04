function checkOverwrites(char)
    local rev = nil
    -- if char.jail then
    --     rev = "jail"
    -- end
    return rev
end

RegisterServerEvent("character:loadspawns")
AddEventHandler("character:loadspawns", function()
    print("Load Spawns ESX", json.encode(ESX.Items))
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local char =  xPlayer.getIdentifier()
    local cid = tonumber(char)

    MySQL.Async.fetchAll("SELECT ho.*, cm.cid, cm.building_type, hp.level, hp.illness, hp.time FROM users_motel cm LEFT JOIN users_housing ho on ho.cid = cm.cid LEFT JOIN users_hospital_patients hp on hp.cid = cm.cid WHERE cm.cid = @cid ",{
        ["cid"] = cid
    },function(housingMotels)
        MySQL.Async.fetchAll("SELECT housing_id FROM users_housing_keys WHERE cid = @cid",{
            ["cid"] = cid
        },function(housing_keys)
            if housingMotels[1] then
                local spawnData = {
                    ["overwrites"] = checkOverwrites(char),
                    ["hospital"] = {
                        ["illness"] = housingMotels[1].illness,
                        ["level"] = housingMotels[1].level,
                        ["time"] = housingMotels[1].time,
                    },
                    ["motelRoom"] = {
                        ["roomType"] = housingMotels[1].building_type,
                        ["cid"] = housingMotels[1].cid,
                    },
                    ["houses"] = {},
                    ["keys"] = {},
                }

                for k,v in pairs(housingMotels) do
                    if v.housing_id ~= nil then
                        spawnData["houses"][v.housing_id] = true
                    end
                end

                for k,v in pairs(housing_keys) do
                    if v.housing_id ~= nil then
                        spawnData["keys"][v.housing_id] = true
                    end
                end
                TriggerClientEvent("spawn:clientSpawnData",src,spawnData)
            else
                --This assumes a New Character
                MySQL.Async.execute("INSERT INTO users_motel (cid) VALUES (@cid)",{
                    ["cid"] = cid
                })
                MySQL.Async.execute("INSERT INTO users_hospital_patients (cid,level,illness,time) VALUES (@cid,@level,@illness,@time)",{
                    ["cid"] = cid,
                    ["level"] = 0,
                    ["illness"] = "none",
                    ["time"] = 0
                })

                local spawnData = {
                    ["overwrites"] = "new",
                    ["hospital"] = {
                        ["illness"] = "none",
                        ["level"] = 0,
                        ["time"] = 0,
                    },
                    ["motelRoom"] = {
                        ["roomType"] = 1,
                        ["cid"] = cid,
                    },
                    ["houses"] = {},
                    ["keys"] = {},
                }
                TriggerClientEvent("spawn:clientSpawnData",src,spawnData)
            end
        end)
    end)
end)