-- Version 1.6.3.0
-- Special thanks to Cap. Zeen, Tarres and Splash for all the help
-- with getting the radio information :)
-- Add (without the --) To the END OF your Export.lua to enable Simple Radio Standalone :

--      local dcsSr=require('lfs');dofile(dcsSr.writedir()..[[Scripts\DCS-SimpleRadioStandalone.lua]])

-- 
-- Make sure you COPY this file to the same location as the Export.lua as well.
-- If an Export.lua doesn't exist, just create one add add the single line in
local SR = {}

SR.LOS_RECEIVE_PORT = 9086
SR.LOS_SEND_TO_PORT = 9085
SR.RADIO_SEND_TO_PORT = 9084

SR.LOS_HEIGHT_OFFSET = 10.0 -- sets the line of sight offset to simulate radio waves bending
SR.LOS_HEIGHT_OFFSET_MAX = 80.0 -- max amount of "bend"
SR.LOS_HEIGHT_OFFSET_STEP = 10.0 -- Interval to "bend" in

SR.unicast = true --DONT CHANGE THIS

SR.lastKnownPos = { x = 0, y = 0, z = 0 }

SR.logFile = io.open(lfs.writedir() .. [[Logs\DCS-SimpleRadioStandalone.log]], "w")
function SR.log(str)
    if SR.logFile then
        SR.logFile:write(str .. "\n")
        SR.logFile:flush()
    end
end

package.path = package.path .. ";.\\LuaSocket\\?.lua;"
package.cpath = package.cpath .. ";.\\LuaSocket\\?.dll;"

---- DCS Search Paths - So we can load Terrain!
local guiBindPath = './dxgui/bind/?.lua;' ..
        './dxgui/loader/?.lua;' ..
        './dxgui/skins/skinME/?.lua;' ..
        './dxgui/skins/common/?.lua;'

package.path = package.path .. ";"
        .. guiBindPath
        .. './MissionEditor/?.lua;'
        .. './MissionEditor/themes/main/?.lua;'
        .. './MissionEditor/modules/?.lua;'
        .. './Scripts/?.lua;'
        .. './LuaSocket/?.lua;'
        .. './Scripts/UI/?.lua;'
        .. './Scripts/UI/Multiplayer/?.lua;'
        .. './Scripts/DemoScenes/?.lua;'

local socket = require("socket")

local JSON = loadfile("Scripts\\JSON.lua")()
SR.JSON = JSON

SR.UDPSendSocket = socket.udp()
SR.UDPLosReceiveSocket = socket.udp()

--bind for listening for LOS info
SR.UDPLosReceiveSocket:setsockname("*", SR.LOS_RECEIVE_PORT)
SR.UDPLosReceiveSocket:settimeout(0) --receive timer was 0001

local terrain = require('terrain')

if terrain ~= nil then
    SR.log("Loaded Terrain - SimpleRadio Standalone!")
end

-- Prev Export functions.
local _prevExport = {}
_prevExport.LuaExportActivityNextEvent = LuaExportActivityNextEvent
_prevExport.LuaExportBeforeNextFrame = LuaExportBeforeNextFrame

local _send = false

local _lastUnitId = "" -- used for a10c volume

LuaExportActivityNextEvent = function(tCurrent)
    local tNext = tCurrent + 0.1 -- for helios support
    -- we only want to send once every 0.2 seconds 
    -- but helios (and other exports) require data to come much faster
    -- so we just flip a boolean every run through to reduce to 0.2 rather than 0.1 seconds
    if _send then

        _send = false

        local _status, _result = pcall(function()

            local _update = nil

            local _data = LoGetSelfData()

            if _data ~= nil then

                _update = {
                    name = "",
                    unit = "",
                    selected = 1,
                    unitId = 0,
                    ptt = false,
                    radios = {
                        -- Radio 1 is always Intercom
                        { name = "", freq = 100, modulation = 3, volume = 1.0, secFreq = 0, freqMin = 1, freqMax = 1, encKey = 0, enc = false, encMode = 0, freqMode = 0, volMode = 0, expansion = false },
                        { name = "", freq = 0, modulation = 3, volume = 1.0, secFreq = 0, freqMin = 1, freqMax = 1, encKey = 0, enc = false, encMode = 0, freqMode = 0, volMode = 0, expansion = false }, -- enc means encrypted
                        { name = "", freq = 0, modulation = 3, volume = 1.0, secFreq = 0, freqMin = 1, freqMax = 1, encKey = 0, enc = false, encMode = 0, freqMode = 0, volMode = 0, expansion = false },
                        { name = "", freq = 0, modulation = 3, volume = 1.0, secFreq = 0, freqMin = 1, freqMax = 1, encKey = 0, enc = false, encMode = 0, freqMode = 0, volMode = 0, expansion = false },
                    },
                    control = 0, -- HOTAS
                }

                _update.name = _data.UnitName
                _update.unit = _data.Name
                _update.unitId = LoGetPlayerPlaneId()
                _update.pos = SR.exportPlayerLocation(_data)

                SR.lastKnownPos = _update.pos

                --SR.log(_update.unit.."\n\n")


                if _update.unit == "UH-1H" then
                    _update = SR.exportRadioUH1H(_update)
                elseif string.find(_update.unit, "SA342") then
                    _update = SR.exportRadioSA342(_update)
                elseif _update.unit == "Ka-50" then
                    _update = SR.exportRadioKA50(_update)
                elseif _update.unit == "Mi-8MT" then
                    _update = SR.exportRadioMI8(_update)
                elseif string.find(_update.unit, "L-39") then
                    _update = SR.exportRadioL39(_update)
                elseif _update.unit == "Yak-52" then
                    _update = SR.exportRadioYak52(_update)
                elseif _update.unit == "A-10C" then
                    _update = SR.exportRadioA10C(_update)
                elseif _update.unit == "FA-18C_hornet" then
                    _update = SR.exportRadioFA18C(_update)
                elseif string.find(_update.unit, "F-14") then
                    _update = SR.exportRadioF14(_update)
                elseif _update.unit == "F-86F Sabre" then
                    _update = SR.exportRadioF86Sabre(_update)
                elseif _update.unit == "MiG-15bis" then
                    _update = SR.exportRadioMIG15(_update)
                elseif _update.unit == "MiG-19P" then
                    _update = SR.exportRadioMIG19(_update)
                elseif _update.unit == "MiG-21Bis" then
                    _update = SR.exportRadioMIG21(_update)
                elseif _update.unit == "F-5E-3" then
                    _update = SR.exportRadioF5E(_update)
                elseif _update.unit == "P-51D" or _update.unit == "P-51D-30-NA" or _update.unit == "TF-51D" then
                    _update = SR.exportRadioP51(_update)
                elseif _update.unit == "FW-190D9" or _update.unit == "FW-190A8" then
                    _update = SR.exportRadioFW190(_update)
                elseif _update.unit == "Bf-109K-4" then
                    _update = SR.exportRadioBF109(_update)
                elseif string.find(_update.unit, "SpitfireLFMkIX") then
                    _update = SR.exportRadioSpitfireLFMkIX(_update)
                elseif _update.unit == "C-101EB" then
                    _update = SR.exportRadioC101EB(_update)
                elseif _update.unit == "C-101CC" then
                    _update = SR.exportRadioC101CC(_update)
                elseif _update.unit == "Hawk" then
                    _update = SR.exportRadioHawk(_update)
                elseif _update.unit == "Christen Eagle II" then
                    _update = SR.exportRadioEagleII(_update)
                elseif _update.unit == "M-2000C" then
                    _update = SR.exportRadioM2000C(_update)
                elseif _update.unit == "AV8BNA" then
                    _update = SR.exportRadioAV8BNA(_update)
                elseif _update.unit == "AJS37" then
                    _update = SR.exportRadioAJS37(_update)
                elseif _update.unit == "A-10A" then
                    _update = SR.exportRadioA10A(_update)
                elseif _update.unit == "A-4E-C" then
                    _update = SR.exportRadioA4E(_update)
                elseif _update.unit == "F-15C" then
                    _update = SR.exportRadioF15C(_update)
                elseif _update.unit == "MiG-29A" or _update.unit == "MiG-29S" or _update.unit == "MiG-29G" then
                    _update = SR.exportRadioMiG29(_update)
                elseif _update.unit == "Su-27" or _update.unit == "Su-33" then
                    _update = SR.exportRadioSU27(_update)
                elseif _update.unit == "Su-25" or _update.unit == "Su-25T" then
                    _update = SR.exportRadioSU25(_update)
                elseif _update.unit == "F-16C_50" then
                    _update = SR.exportRadioF16C(_update)
                else
                    -- FC 3
                    _update.radios[2].name = "FC3 VHF"
                    _update.radios[2].freq = 124.8 * 1000000 --116,00-151,975 MHz
                    _update.radios[2].modulation = 0
                    _update.radios[2].secFreq = 121.5 * 1000000
                    _update.radios[2].volume = 1.0
                    _update.radios[2].freqMin = 116 * 1000000
                    _update.radios[2].freqMax = 151.975 * 1000000
                    _update.radios[2].volMode = 1
                    _update.radios[2].freqMode = 1

                    _update.radios[3].name = "FC3 UHF"
                    _update.radios[3].freq = 251.0 * 1000000 --225-399.975 MHZ
                    _update.radios[3].modulation = 0
                    _update.radios[3].secFreq = 243.0 * 1000000
                    _update.radios[3].volume = 1.0
                    _update.radios[3].freqMin = 225 * 1000000
                    _update.radios[3].freqMax = 399.975 * 1000000
                    _update.radios[3].volMode = 1
                    _update.radios[3].freqMode = 1

                    _update.radios[3].encKey = 1
                    _update.radios[3].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

                    _update.radios[4].name = "FC3 FM"
                    _update.radios[4].freq = 30.0 * 1000000 --VHF/FM opera entre 30.000 y 76.000 MHz.
                    _update.radios[4].modulation = 1
                    _update.radios[4].volume = 1.0
                    _update.radios[4].freqMin = 30 * 1000000
                    _update.radios[4].freqMax = 76 * 1000000
                    _update.radios[4].volMode = 1
                    _update.radios[4].freqMode = 1

                    _update.radios[4].encKey = 1
                    _update.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

                    _update.control = 0;
                    _update.selected = 1
                end

                _lastUnitId = _update.unitId
            else


                -- save last pos
                SR.lastKnownPos = { x = 0, y = 0, z = 0 }

                --Ground Commander or spectator
                _update = {
                    name = "Unknown",
                    unit = "CA",
                    selected = 1,
                    ptt = false,
                    pos = { x = 0, y = 0, z = 0 },
                    unitId = 100000001, -- pass through starting unit id here
                    radios = {
                        --- Radio 0 is always intercom now -- disabled if AWACS panel isnt open
                        { name = "SATCOM", freq = 100, modulation = 2, volume = 1.0, secFreq = 0, freqMin = 100, freqMax = 100, encKey = 0, enc = false, encMode = 0, freqMode = 0, volMode = 1, expansion = false },
                        { name = "UHF Guard", freq = 251.0 * 1000000, modulation = 0, volume = 1.0, secFreq = 243.0 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 1, enc = false, encMode = 1, freqMode = 1, volMode = 1, expansion = false },
                        { name = "UHF Guard", freq = 251.0 * 1000000, modulation = 0, volume = 1.0, secFreq = 243.0 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 1, enc = false, encMode = 1, freqMode = 1, volMode = 1, expansion = false },
                        { name = "VHF FM", freq = 30.0 * 1000000, modulation = 1, volume = 1.0, secFreq = 1, freqMin = 1 * 1000000, freqMax = 76 * 1000000, encKey = 1, enc = false, encMode = 1, freqMode = 1, volMode = 1, expansion = false },
                        { name = "UHF Guard", freq = 251.0 * 1000000, modulation = 0, volume = 1.0, secFreq = 243.0 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 1, enc = false, encMode = 1, freqMode = 1, volMode = 1, expansion = false },
                        { name = "UHF Guard", freq = 251.0 * 1000000, modulation = 0, volume = 1.0, secFreq = 243.0 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 1, enc = false, encMode = 1, freqMode = 1, volMode = 1, expansion = false },
                        { name = "VHF Guard", freq = 124.8 * 1000000, modulation = 0, volume = 1.0, secFreq = 121.5 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 0, enc = false, encMode = 0, freqMode = 1, volMode = 1, expansion = false },
                        { name = "VHF Guard", freq = 124.8 * 1000000, modulation = 0, volume = 1.0, secFreq = 121.5 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 0, enc = false, encMode = 0, freqMode = 1, volMode = 1, expansion = false },
                        { name = "VHF FM", freq = 30.0 * 1000000, modulation = 1, volume = 1.0, secFreq = 1, freqMin = 1 * 1000000, freqMax = 76 * 1000000, encKey = 1, enc = false, encMode = 1, freqMode = 1, volMode = 1, expansion = false },
                        { name = "VHF Guard", freq = 124.8 * 1000000, modulation = 0, volume = 1.0, secFreq = 121.5 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 0, enc = false, encMode = 0, freqMode = 1, volMode = 1, expansion = false },
                        { name = "VHF Guard", freq = 124.8 * 1000000, modulation = 0, volume = 1.0, secFreq = 121.5 * 1000000, freqMin = 1 * 1000000, freqMax = 400 * 1000000, encKey = 0, enc = false, encMode = 0, freqMode = 1, volMode = 1, expansion = false },
                    },
                    radioType = 3
                }

                _lastUnitId = ""
            end

            if SR.unicast then
                socket.try(SR.UDPSendSocket:sendto(SR.JSON:encode(_update) .. " \n", "127.0.0.1", SR.RADIO_SEND_TO_PORT))
            else
                socket.try(SR.UDPSendSocket:sendto(SR.JSON:encode(_update) .. " \n", "127.255.255.255", SR.RADIO_SEND_TO_PORT))
            end

        end)

        if not _status then
            SR.log('ERROR: ' .. _result)
        end

    else
        _send = true
    end


    -- call
    local _status, _result = pcall(function()
        -- Call original function if it exists
        if _prevExport.LuaExportActivityNextEvent then
            _prevExport.LuaExportActivityNextEvent(tCurrent)
        end

    end)

    if not _status then
        SR.log('ERROR Calling other LuaExportActivityNextEvent from another script: ' .. _result)
    end

    if terrain == nil then
        SR.log("Terrain Export is not working")
        --SR.log("EXPORT CHECK "..tostring(terrain.isVisible(1,100,1,1,100,1)))
        --SR.log("EXPORT CHECK "..tostring(terrain.isVisible(1,1,1,1,-100,-100)))
    end

    return tNext
end

local _lastCheck = 0;

LuaExportBeforeNextFrame = function()

    -- read from socket
    local _status, _result = pcall(function()

        -- Receive buffer is 8192 in LUA Socket
        -- will contain 10 clients for LOS
        local _received = SR.UDPLosReceiveSocket:receive()

        if _received then
            local _decoded = SR.JSON:decode(_received)

            if _decoded then

                local _losList = SR.checkLOS(_decoded)

                --DEBUG
                -- SR.log('LOS check ' .. SR.JSON:encode(_losList))
                if SR.unicast then
                    socket.try(SR.UDPSendSocket:sendto(SR.JSON:encode(_losList) .. " \n", "127.0.0.1", SR.LOS_SEND_TO_PORT))
                else
                    socket.try(SR.UDPSendSocket:sendto(SR.JSON:encode(_losList) .. " \n", "127.255.255.255", SR.LOS_SEND_TO_PORT))
                end
            end

        end
    end)

    if not _status then
        SR.log('ERROR LuaExportBeforeNextFrame SRS: ' .. _result)
    end

    -- call original
    _status, _result = pcall(function()
        -- Call original function if it exists
        if _prevExport.LuaExportBeforeNextFrame then
            _prevExport.LuaExportBeforeNextFrame()
        end
    end)

    if not _status then
        SR.log('ERROR Calling other LuaExportBeforeNextFrame from another script: ' .. _result)
    end

end

function SR.checkLOS(_clientsList)

    local _result = {}
    for _, _client in pairs(_clientsList) do
        -- add 10 meter tolerance


        local _los = 1.0 -- 1.0 is NO line of sight as in full signal loss - 0.0 is full signal, NO Loss

        local _hasLos = terrain.isVisible(SR.lastKnownPos.x, SR.lastKnownPos.y + SR.LOS_HEIGHT_OFFSET, SR.lastKnownPos.z, _client.x, _client.y + SR.LOS_HEIGHT_OFFSET, _client.z)

        if _hasLos then
            table.insert(_result, { id = _client.id, los = 0.0 })
        else
            --check from 10 - 60 in incremenents of 10 if there is Line of sight

            -- check Max
            _hasLos = terrain.isVisible(SR.lastKnownPos.x, SR.lastKnownPos.y + SR.LOS_HEIGHT_OFFSET_MAX, SR.lastKnownPos.z, _client.x, _client.y + SR.LOS_HEIGHT_OFFSET, _client.z)

            if _hasLos then
                table.insert(_result, { id = _client.id, los = (SR.LOS_HEIGHT_OFFSET_MAX / 100.0) })
            end

            -- now check all the values that arent MAX offset and MIN offset

            for _losOffset = SR.LOS_HEIGHT_OFFSET + SR.LOS_HEIGHT_OFFSET_STEP, SR.LOS_HEIGHT_OFFSET_MAX - SR.LOS_HEIGHT_OFFSET_STEP, SR.LOS_HEIGHT_OFFSET_STEP do

                _hasLos = terrain.isVisible(SR.lastKnownPos.x, SR.lastKnownPos.y + _losOffset, SR.lastKnownPos.z, _client.x, _client.y + SR.LOS_HEIGHT_OFFSET, _client.z)

                if _hasLos then
                    table.insert(_result, { id = _client.id, los = (_losOffset / 100.0) })
                    break ;
                end
            end

            if not _hasLos then
                table.insert(_result, { id = _client.id, los = 1.0 }) -- 1.0 Being NO line of sight - FULL signal loss
            end
        end

    end
    return _result
end

function SR.exportPlayerLocation(_data)

    if _data ~= nil and _data.Position ~= nil then
        return _data.Position
    else
        return { x = 0, y = 0, z = 0 }
    end
end

function SR.exportRadioA10A(_data)

    _data.radios[2].name = "AN/ARC-186(V)"
    _data.radios[2].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[2].modulation = 0
    _data.radios[2].secFreq = 121.5 * 1000000
    _data.radios[2].volume = 1.0
    _data.radios[2].freqMin = 116 * 1000000
    _data.radios[2].freqMax = 151.975 * 1000000
    _data.radios[2].volMode = 1
    _data.radios[2].freqMode = 1

    _data.radios[3].name = "AN/ARC-164 UHF"
    _data.radios[3].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 243.0 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 225 * 1000000
    _data.radios[3].freqMax = 399.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1

    _data.radios[3].encKey = 1
    _data.radios[3].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.radios[4].name = "AN/ARC-186(V)FM"
    _data.radios[4].freq = 30.0 * 1000000 --VHF/FM opera entre 30.000 y 76.000 MHz.
    _data.radios[4].modulation = 1
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 30 * 1000000
    _data.radios[4].freqMax = 76 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1

    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.exportRadioMiG29(_data)

    _data.radios[2].name = "R-862"
    _data.radios[2].freq = 251.0 * 1000000 --V/UHF, frequencies are: VHF range of 100 to 149.975 MHz and UHF range of 220 to 399.975 MHz
    _data.radios[2].modulation = 0
    _data.radios[2].secFreq = 121.5 * 1000000
    _data.radios[2].volume = 1.0
    _data.radios[2].freqMin = 100 * 1000000
    _data.radios[2].freqMax = 399.975 * 1000000
    _data.radios[2].volMode = 1
    _data.radios[2].freqMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].expansion = true
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].expansion = true
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.exportRadioSU25(_data)

    _data.radios[2].name = "R-862"
    _data.radios[2].freq = 251.0 * 1000000 --V/UHF, frequencies are: VHF range of 100 to 149.975 MHz and UHF range of 220 to 399.975 MHz
    _data.radios[2].modulation = 0
    _data.radios[2].secFreq = 121.5 * 1000000
    _data.radios[2].volume = 1.0
    _data.radios[2].freqMin = 100 * 1000000
    _data.radios[2].freqMax = 399.975 * 1000000
    _data.radios[2].volMode = 1
    _data.radios[2].freqMode = 1

    _data.radios[3].name = "R-828"
    _data.radios[3].freq = 30.0 * 1000000 --20 - 60 MHz.
    _data.radios[3].modulation = 1
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 20 * 1000000
    _data.radios[3].freqMax = 59.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].expansion = true
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.exportRadioSU27(_data)

    _data.radios[2].name = "R-800"
    _data.radios[2].freq = 251.0 * 1000000 --V/UHF, frequencies are: VHF range of 100 to 149.975 MHz and UHF range of 220 to 399.975 MHz
    _data.radios[2].modulation = 0
    _data.radios[2].secFreq = 121.5 * 1000000
    _data.radios[2].volume = 1.0
    _data.radios[2].freqMin = 100 * 1000000
    _data.radios[2].freqMax = 399.975 * 1000000
    _data.radios[2].volMode = 1
    _data.radios[2].freqMode = 1

    _data.radios[3].name = "R-864"
    _data.radios[3].freq = 3.5 * 1000000 --HF frequencies in the 3-10Mhz, like the Jadro
    _data.radios[3].modulation = 0
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 3 * 1000000
    _data.radios[3].freqMax = 10 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.exportRadioA4E(_data)

    _data.radios[2].name = "AN/ARC-27A"
    _data.radios[2].freq = 251.0 * 1000000 --225 to 399.975MHZ
    _data.radios[2].modulation = 0
    _data.radios[2].secFreq = 243.0 * 1000000
    _data.radios[2].volume = 1.0
    _data.radios[2].freqMin = 225 * 1000000
    _data.radios[2].freqMax = 399.975 * 1000000
    _data.radios[2].volMode = 1
    _data.radios[2].freqMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].expansion = true
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-186(V)FM"
    _data.radios[4].freq = 30.0 * 1000000 --VHF/FM opera entre 30.000 y 76.000 MHz.
    _data.radios[4].modulation = 1
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 30 * 1000000
    _data.radios[4].freqMax = 76 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.exportRadioF15C(_data)

    _data.radios[2].name = "AN/ARC-164 UHF-1"
    _data.radios[2].freq = 251.0 * 1000000 --225 to 399.975MHZ
    _data.radios[2].modulation = 0
    _data.radios[2].secFreq = 243.0 * 1000000
    _data.radios[2].volume = 1.0
    _data.radios[2].freqMin = 225 * 1000000
    _data.radios[2].freqMax = 399.975 * 1000000
    _data.radios[2].volMode = 1
    _data.radios[2].freqMode = 1

    _data.radios[2].encKey = 1
    _data.radios[2].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.radios[3].name = "AN/ARC-164 UHF-2"
    _data.radios[3].freq = 231.0 * 1000000 --225 to 399.975MHZ
    _data.radios[3].modulation = 0
    _data.radios[3].freqMin = 225 * 1000000
    _data.radios[3].freqMax = 399.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1

    _data.radios[3].encKey = 1
    _data.radios[3].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting


    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-186(V)"
    _data.radios[4].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 121.5 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 116 * 1000000
    _data.radios[4].freqMax = 151.975 * 1000000
    _data.radios[4].expansion = true
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.exportRadioUH1H(_data)

    _data.radios[2].name = "AN/ARC-131"
    _data.radios[2].freq = SR.getRadioFrequency(23)
    _data.radios[2].modulation = 1
    _data.radios[2].volume = SR.getRadioVolume(0, 37, { 0.3, 1.0 }, true) * SR.getRadioVolume(0, 29, { 0.3, 1.0 }, true)

    _data.radios[3].name = "AN/ARC-51BX - UHF"
    _data.radios[3].freq = SR.getRadioFrequency(22)
    _data.radios[3].modulation = 0
    _data.radios[3].volume = SR.getRadioVolume(0, 21, { 0.0, 1.0 }, true) * SR.getRadioVolume(0, 29, { 0.3, 1.0 }, true)

    -- get channel selector
    local _selector = SR.getSelectorPosition(15, 0.1)

    if _selector < 1 then
        _data.radios[3].channel = SR.getSelectorPosition(16, 0.05) + 1 --add 1 as channel 0 is channel 1 
    end

    _data.radios[4].name = "AN/ARC-134"
    _data.radios[4].freq = SR.getRadioFrequency(20)
    _data.radios[4].modulation = 0
    _data.radios[4].volume = SR.getRadioVolume(0, 9, { 0.0, 0.60 }, false) * SR.getRadioVolume(0, 29, { 0.3, 1.0 }, true)

    --_device:get_argument_value(_arg)
    --guard mode for UHF Radio
    local uhfModeKnob = SR.getSelectorPosition(17, 0.1)
    if uhfModeKnob == 2 and _data.radios[3].freq > 1000 then
        _data.radios[3].secFreq = 243.0 * 1000000
    end

    local _panel = GetDevice(0)

    local switch = _panel:get_argument_value(30)

    if SR.nearlyEqual(switch, 0.2, 0.03) then
        _data.selected = 1
    elseif SR.nearlyEqual(switch, 0.3, 0.03) then
        _data.selected = 2
    elseif SR.nearlyEqual(switch, 0.4, 0.03) then
        _data.selected = 3
    else
        _data.selected = -1
    end

    if SR.getButtonPosition(194) >= 0.1 then
        _data.ptt = true
    end

    _data.control = 1; -- Full Radio

    return _data

end

function SR.exportRadioSA342(_data)

    _data.radios[1].name = "Intercom"
    _data.radios[1].freq = 100.0
    _data.radios[1].modulation = 2 --Special intercom modulation
    _data.radios[1].volume = 1.0
    _data.radios[1].volMode = 1

    _data.radios[2].name = "TRAP 138A"
    _data.radios[2].freq = SR.getRadioFrequency(5)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 68, { 1.0, 0.0 }, true)

    _data.radios[3].name = "UHF TRA 6031"

    -- deal with odd radio tune & rounding issue... BUG you cannot set frequency 243.000 ever again
    local freq = SR.getRadioFrequency(31, 500)
    freq = (math.floor(freq / 1000) * 1000)

    _data.radios[3].freq = freq

    _data.radios[3].modulation = 0
    _data.radios[3].volume = SR.getRadioVolume(0, 69, { 0.0, 1.0 }, false)

    _data.radios[3].encKey = 1
    _data.radios[3].encMode = 3 -- 3 is Incockpit toggle + Gui Enc Key setting

    _data.radios[4].name = "TRC 9600 PR4G"
    _data.radios[4].freq = SR.getRadioFrequency(28)
    _data.radios[4].modulation = 1
    _data.radios[4].volume = SR.getRadioVolume(0, 70, { 0.0, 1.0 }, false)

    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 3 -- Variable Enc key but turned on by sim

    --- is UHF ON?
    if SR.getSelectorPosition(383, 0.167) == 0 then
        _data.radios[3].freq = 1
    elseif SR.getSelectorPosition(383, 0.167) == 2 then
        --check UHF encryption
        _data.radios[3].enc = true
    end


    --guard mode for UHF Radio
    local uhfModeKnob = SR.getSelectorPosition(383, 0.167)
    if uhfModeKnob == 5 and _data.radios[3].freq > 1000 then
        _data.radios[3].secFreq = 243.0 * 1000000
    end

    --- is FM ON?
    if SR.getSelectorPosition(272, 0.25) == 0 then
        _data.radios[4].freq = 1
    elseif SR.getSelectorPosition(272, 0.25) == 2 then
        --check FM encryption
        _data.radios[4].enc = true
    end

    _data.control = 0; -- HOTAS Controls

    return _data

end

function SR.exportRadioKA50(_data)

    local _panel = GetDevice(0)

    _data.radios[2].name = "R-800L14 VHF/UHF"
    _data.radios[2].freq = SR.getRadioFrequency(48)

    -- Get modulation mode
    local switch = _panel:get_argument_value(417)
    if SR.nearlyEqual(switch, 0.0, 0.03) then
        _data.radios[2].modulation = 1
    else
        _data.radios[2].modulation = 0
    end
    _data.radios[2].volume = SR.getRadioVolume(0, 353, { 0.0, 1.0 }, false) -- using ADF knob for now 

    _data.radios[3].name = "R-828"
    _data.radios[3].freq = SR.getRadioFrequency(49, 50000)
    _data.radios[3].modulation = 1
    _data.radios[3].volume = SR.getRadioVolume(0, 372, { 0.0, 1.0 }, false)
    _data.radios[3].channel = SR.getSelectorPosition(371, 0.1) + 1

    --expansion radios
    _data.radios[4].name = "SPU-9 SW"
    _data.radios[4].freq = 5.0 * 1000000
    _data.radios[4].freqMin = 1.0 * 1000000
    _data.radios[4].freqMax = 10.0 * 1000000
    _data.radios[4].modulation = 0
    _data.radios[4].volume = 1.0
    _data.radios[4].expansion = true
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1

    local switch = _panel:get_argument_value(428)

    if SR.nearlyEqual(switch, 0.0, 0.03) then
        _data.selected = 1
    elseif SR.nearlyEqual(switch, 0.1, 0.03) then
        _data.selected = 2
    elseif SR.nearlyEqual(switch, 0.2, 0.03) then
        _data.selected = 3
    else
        _data.selected = -1
    end

    _data.control = 1;

    return _data

end
function SR.exportRadioMI8(_data)

    -- Doesnt work but might as well allow selection
    _data.radios[1].name = "Intercom"
    _data.radios[1].freq = 100.0
    _data.radios[1].modulation = 2 --Special intercom modulation
    _data.radios[1].volume = 1.0

    _data.radios[2].name = "R-863"
    _data.radios[2].freq = SR.getRadioFrequency(38)

    local _modulation = GetDevice(0):get_argument_value(369)
    if _modulation > 0.5 then
        _data.radios[2].modulation = 1
    else
        _data.radios[2].modulation = 0
    end

    -- get channel selector
    local _selector = GetDevice(0):get_argument_value(132)

    if _selector > 0.5 then
        _data.radios[2].channel = SR.getSelectorPosition(370, 0.05) + 1 --add 1 as channel 0 is channel 1 
    end

    _data.radios[2].volume = SR.getRadioVolume(0, 156, { 0.0, 1.0 }, false)

    _data.radios[3].name = "JADRO-1A"
    _data.radios[3].freq = SR.getRadioFrequency(37, 500)
    _data.radios[3].modulation = 0
    _data.radios[3].volume = SR.getRadioVolume(0, 743, { 0.0, 1.0 }, false)

    _data.radios[4].name = "R-828"
    _data.radios[4].freq = SR.getRadioFrequency(39, 50000)
    _data.radios[4].modulation = 1
    _data.radios[4].volume = SR.getRadioVolume(0, 737, { 0.0, 1.0 }, false)

    --guard mode for R-863 Radio
    local uhfModeKnob = SR.getSelectorPosition(153, 1)
    if uhfModeKnob == 1 and _data.radios[2].freq > 1000 then
        _data.radios[2].secFreq = 121.5 * 1000000
    end

    -- Get selected radio from SPU-9
    local _switch = SR.getSelectorPosition(550, 0.1)

    if _switch == 0 then
        _data.selected = 1
    elseif _switch == 1 then
        _data.selected = 2
    elseif _switch == 2 then
        _data.selected = 3
    else
        _data.selected = -1
    end

    if SR.getButtonPosition(182) >= 0.5 or SR.getButtonPosition(225) >= 0.5 then
        _data.ptt = true
    end


    -- Radio / ICS Switch
    if SR.getButtonPosition(553) > 0.5 then
        _data.selected = 0
    end

    _data.control = 1; -- full radio

    return _data

end

function SR.exportRadioL39(_data)

    _data.radios[1].name = "Intercom"
    _data.radios[1].freq = 100.0
    _data.radios[1].modulation = 2 --Special intercom modulation
    _data.radios[1].volume = SR.getRadioVolume(0, 288, { 0.0, 0.8 }, false)

    _data.radios[2].name = "R-832M"
    _data.radios[2].freq = SR.getRadioFrequency(19)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 289, { 0.0, 0.8 }, false)

    -- Intercom button depressed
    if (SR.getButtonPosition(133) > 0.5 or SR.getButtonPosition(546) > 0.5) then
        _data.selected = 0
        _data.ptt = true
    elseif (SR.getButtonPosition(134) > 0.5 or SR.getButtonPosition(547) > 0.5) then
        _data.selected = 1
        _data.ptt = true
    else
        _data.selected = 1
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 1; -- full radio - for expansion radios - DCS controls must be disabled

    _data.control = 1; -- full radio

    return _data
end

function SR.exportRadioEagleII(_data)

    _data.radios[1].name = "Intercom"
    _data.radios[1].freq = 100.0
    _data.radios[1].modulation = 2 --Special intercom modulation
    _data.radios[1].volume = 1--SR.getRadioVolume(0, 288,{0.0,0.8},false)

    _data.radios[2].name = "KY-197A"
    _data.radios[2].freq = SR.getRadioFrequency(5)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 364, { 0.1, 1.0 }, false)

    if _data.radios[2].volume < 0 then
        _data.radios[2].volume = 0
    end


    -- Intercom button depressed
    -- if(SR.getButtonPosition(133) > 0.5 or SR.getButtonPosition(546) > 0.5) then
    --     _data.selected = 0
    --     _data.ptt = true
    -- elseif (SR.getButtonPosition(134) > 0.5 or SR.getButtonPosition(547) > 0.5) then
    --     _data.selected= 1
    --     _data.ptt = true
    -- else
    --     _data.selected= 1
    --      _data.ptt = false
    -- end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- HOTAS

    return _data
end

function SR.exportRadioYak52(_data)

    _data.radios[1].name = "Intercom"
    _data.radios[1].freq = 100.0
    _data.radios[1].modulation = 2 --Special intercom modulation
    _data.radios[1].volume = 1.0
    _data.radios[1].volMode = 1

    _data.radios[2].name = "Baklan 5"
    _data.radios[2].freq = SR.getRadioFrequency(24)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 90, { 0.0, 1.0 }, false)

    -- Intercom button depressed
    if (SR.getButtonPosition(192) > 0.5 or SR.getButtonPosition(196) > 0.5) then
        _data.selected = 1
        _data.ptt = true
    elseif (SR.getButtonPosition(194) > 0.5 or SR.getButtonPosition(197) > 0.5) then
        _data.selected = 0
        _data.ptt = true
    else
        _data.selected = 1
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 1; -- full radio - for expansion radios - DCS controls must be disabled

    return _data
end

--for A10C
function SR.exportRadioA10C(_data)

    -- Check if player is in a new aircraft
    if _lastUnitId ~= _data.unitId then
        -- New aircraft; Reset volumes to 100%
        local _device = GetDevice(0)

        if _device then
            _device:set_argument_value(133, 1.0) -- VHF AM
            _device:set_argument_value(171, 1.0) -- UHF
            _device:set_argument_value(147, 1.0) -- VHF FM
        end
    end


    -- VHF AM
    -- Set radio data
    _data.radios[2].name = "AN/ARC-186(V) AM"
    _data.radios[2].freq = SR.getRadioFrequency(55)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 133, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 238, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 225, { 0.0, 1.0 }, false) * SR.getButtonPosition(226)


    -- UHF
    -- Set radio data
    _data.radios[3].name = "AN/ARC-164 UHF"
    _data.radios[3].freq = SR.getRadioFrequency(54)
    _data.radios[3].modulation = 0
    _data.radios[3].volume = SR.getRadioVolume(0, 171, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 238, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 227, { 0.0, 1.0 }, false) * SR.getButtonPosition(228)
    _data.radios[3].encMode = 2 -- Mode 2 is set by aircraft

    -- Check UHF frequency mode (0 = MNL, 1 = PRESET, 2 = GRD)
    local _selector = SR.getSelectorPosition(167, 0.1)
    if _selector == 1 then
        -- Using UHF preset channels
        local _channel = SR.getSelectorPosition(161, 0.05) + 1 --add 1 as channel 0 is channel 1
        _data.radios[3].channel = _channel
    end

    -- Check UHF function mode (0 = OFF, 1 = MAIN, 2 = BOTH, 3 = ADF)
    local uhfModeKnob = SR.getSelectorPosition(168, 0.1)
    if uhfModeKnob == 2 and _data.radios[3].freq > 1000 then
        -- Function dial set to BOTH
        -- Listen to Guard as well as designated frequency
        _data.radios[3].secFreq = 243.0 * 1000000
    else
        -- Function dial set to OFF, MAIN, or ADF
        -- Not listening to Guard secondarily
        _data.radios[3].secFreq = 0
    end


    -- VHF FM
    -- Set radio data
    _data.radios[4].name = "AN/ARC-186(V)FM"
    _data.radios[4].freq = SR.getRadioFrequency(56)
    _data.radios[4].modulation = 1
    _data.radios[4].volume = SR.getRadioVolume(0, 147, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 238, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 223, { 0.0, 1.0 }, false) * SR.getButtonPosition(224)
    _data.radios[4].encMode = 2 -- mode 2 enc is set by aircraft & turned on by aircraft


    -- KY-58 Radio Encryption
    -- Check if encryption is being used
    local _ky58Power = SR.getButtonPosition(784)
    if _ky58Power > 0.5 and SR.getButtonPosition(783) == 0 then
        -- mode switch set to OP and powered on
        -- Power on!

        local _radio = nil
        if SR.round(SR.getButtonPosition(781), 0.1) == 0.2 then
            --crad/2 vhf - FM
            _radio = _data.radios[4]
        elseif SR.getButtonPosition(781) == 0 then
            --crad/1 uhf
            _radio = _data.radios[3]
        end

        -- Get encryption key
        local _channel = SR.getSelectorPosition(782, 0.1) + 1

        if _radio ~= nil and _channel ~= nil then
            -- Set encryption key for selected radio
            _radio.encKey = _channel
            _radio.enc = true
        end
    end


    -- Mic Switch Radio Select and Transmit - by Dyram  
    -- Check Mic Switch position (UP: 751 1.0, DOWN: 751 -1.0, FWD: 752 1.0, AFT: 752 -1.0)
    if SR.getButtonPosition(752) == 1 then
        -- Mic Switch FWD pressed
        -- Check Intercom panel Rotary Selector Dial (0: INT, 1: FM, 2: VHF, 3: HF, 4: "")
        if SR.getSelectorPosition(239, 0.1) == 2 then
            -- Intercom panel set to VHF
            _data.selected = 1 -- radios[2] VHF AM
            _data.ptt = true
        elseif SR.getSelectorPosition(239, 0.1) == 0 then
            -- Intercom panel set to INT
            -- Intercom not functional, but select it anyway to be proper
            _data.selected = 0 -- radios[1] Intercom
        else
            _data.selected = -1
        end
    elseif SR.getButtonPosition(751) == -1 then
        -- Mic Switch DOWN pressed
        _data.selected = 2 -- radios[3] UHF
        _data.ptt = true
    elseif SR.getButtonPosition(752) == -1 then
        -- Mic Switch AFT pressed
        _data.selected = 3 -- radios[4] VHF FM
        _data.ptt = true
    else
        -- Mic Switch released
        _data.selected = -1
        _data.ptt = false
    end

    _data.control = 0 -- HOTAS Controls - set to 1 for DCS PTT & Select controls

    return _data
end

function SR.exportRadioFA18C(_data)

    -- VHF AM
    -- Set radio data
    _data.radios[2].name = "AN/ARC-210 - 1"
    _data.radios[2].freq = SR.getRadioFrequency(38)
    _data.radios[2].modulation = SR.getRadioModulation(38)
    _data.radios[2].volume = SR.getRadioVolume(0, 108, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 362, { 0.0, 1.0 }, false)
    -- _data.radios[2].encMode = 2 -- Mode 2 is set by aircraft

    -- UHF
    -- Set radio data
    _data.radios[3].name = "AN/ARC-210 - 2"
    _data.radios[3].freq = SR.getRadioFrequency(39)
    _data.radios[3].modulation = SR.getRadioModulation(39)
    _data.radios[3].volume = SR.getRadioVolume(0, 123, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 361, { 0.0, 1.0 }, false)
    _data.radios[3].encMode = 2 -- Mode 2 is set by aircraft


    -- KY-58 Radio Encryption
    local _ky58Power = SR.round(SR.getButtonPosition(447), 0.1)
    if _ky58Power == 0.1 and SR.round(SR.getButtonPosition(444), 0.1) == 0.1 then
        -- mode switch set to C and powered on
        -- Power on!

        -- Get encryption key
        local _channel = SR.getSelectorPosition(446, 0.1) + 1
        if _channel > 6 then
            _channel = 6 -- has two other options - lock to 6
        end

        -- _data.radios[2].encKey = _channel
        -- _data.radios[2].enc = true

        _data.radios[3].encKey = _channel
        _data.radios[3].enc = true

    end

    _data.control = 0; -- SRS Hotas Controls

    return _data
end

function SR.exportRadioF16C(_data)

    -- UHF
    _data.radios[2].name = "AN/ARC-164"
    _data.radios[2].freq = SR.getRadioFrequency(36)
    _data.radios[2].modulation = SR.getRadioModulation(36)
    _data.radios[2].volume = SR.getRadioVolume(0, 430, { 0.0, 1.0 }, false)
    _data.radios[2].encMode = 2

    -- C&I Backup/UFC by Raffson, aka Stoner
    local _cni = SR.getButtonPosition(542)
    if _cni == 0 then
        local _buhf_func = SR.getSelectorPosition(417, 0.1)
        if _buhf_func == 2 then
            -- Function set to BOTH --> also listen to guard
            _data.radios[2].secFreq = 243.0 * 1000000
        else
            _data.radios[2].secFreq = 0
        end
        _data.radios[2].volume = SR.getRadioVolume(0, 420, { 0.0, 1.0 }, false)

        -- Check UHF frequency mode (0 = MNL, 1 = PRESET, 2 = GRD)
        local _selector = SR.getSelectorPosition(416, 0.1)
        if _selector == 1 then
            -- Using UHF preset channels
            local _channel = SR.getSelectorPosition(410, 0.05) + 1 --add 1 as channel 0 is channel 1
            _data.radios[2].channel = _channel
        end
    end

    -- VHF
    _data.radios[3].name = "AN/ARC-222"
    _data.radios[3].freq = SR.getRadioFrequency(38)
    _data.radios[3].modulation = SR.getRadioModulation(38)
    _data.radios[3].volume = SR.getRadioVolume(0, 431, { 0.0, 1.0 }, false)
    _data.radios[3].encMode = 2

    -- KY-58 Radio Encryption
    local _ky58Power = SR.round(SR.getButtonPosition(707), 0.1)

    if _ky58Power == 0.5 and SR.round(SR.getButtonPosition(705), 0.1) == 0.1 then
        -- mode switch set to C and powered on
        -- Power on and correct mode selected
        -- Get encryption key
        local _channel = SR.getSelectorPosition(706, 0.1)

        local _cipherSwitch = SR.round(SR.getButtonPosition(701), 1)
        local _radio = nil
        if _cipherSwitch > 0.5 then
            -- CRAD1 (UHF)
            _radio = _data.radios[2]
        elseif _cipherSwitch < -0.5 then
            -- CRAD2 (VHF)
            _radio = _data.radios[3]
        end
        if _radio ~= nil and _channel > 0 and _channel < 7 then
            _radio.encKey = _channel
            _radio.enc = true
            _radio.volume = SR.getRadioVolume(0, 708, { 0.0, 1.0 }, false) * SR.getRadioVolume(0, 432, { 0.0, 1.0 }, false)--User KY-58 volume if chiper is used
        end
    end

    _data.control = 0; -- SRS Hotas Controls

    return _data
end

function SR.exportRadioF86Sabre(_data)

    _data.radios[2].name = "AN/ARC-27"
    _data.radios[2].freq = SR.getRadioFrequency(26)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 806, { 0.1, 0.9 }, false)

    -- get channel selector
    local _channel = SR.getSelectorPosition(807, 0.01)

    if _channel >= 1 then
        _data.radios[2].channel = _channel
    end

    _data.selected = 1

    --guard mode for UHF Radio
    local uhfModeKnob = SR.getSelectorPosition(805, 0.1)
    if uhfModeKnob == 2 and _data.radios[2].freq > 1000 then
        _data.radios[2].secFreq = 243.0 * 1000000
    end

    -- Check PTT
    if (SR.getButtonPosition(213)) > 0.5 then
        _data.ptt = true
    else
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- Hotas Controls

    return _data;
end

function SR.exportRadioMIG15(_data)

    _data.radios[2].name = "RSI-6K"
    _data.radios[2].freq = SR.getRadioFrequency(30)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 126, { 0.1, 0.9 }, false)

    _data.selected = 1

    -- Check PTT
    if (SR.getButtonPosition(202)) > 0.5 then
        _data.ptt = true
    else
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- Hotas Controls radio

    return _data;
end

function SR.exportRadioMIG19(_data)

    _data.radios[2].name = "RSIU-4V"
    _data.radios[2].freq = SR.getRadioFrequency(17)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 327, { 0.0, 1.0 }, false)

    _data.selected = 1



    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- Hotas Controls radio

    return _data;
end

function SR.exportRadioMIG21(_data)

    _data.radios[2].name = "R-832"
    _data.radios[2].freq = SR.getRadioFrequency(22)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 210, { 0.0, 1.0 }, false)

    _data.radios[2].channel = SR.getSelectorPosition(211, 0.05)

    _data.selected = 1

    if (SR.getButtonPosition(315)) > 0.5 then
        _data.ptt = true
    else
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- hotas radio

    return _data;
end

function SR.exportRadioF5E(_data)
    _data.radios[2].name = "AN/ARC-164"
    _data.radios[2].freq = SR.getRadioFrequency(23)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 309, { 0.1, 0.9 }, false)

    -- get channel selector
    local _selector = SR.getSelectorPosition(307, 0.1)

    if _selector == 1 then
        _data.radios[2].channel = SR.getSelectorPosition(300, 0.05) + 1 --add 1 as channel 0 is channel 1 
    end

    _data.selected = 1

    --guard mode for UHF Radio
    local uhfModeKnob = SR.getSelectorPosition(311, 0.1)

    if uhfModeKnob == 2 and _data.radios[2].freq > 1000 then
        _data.radios[2].secFreq = 243.0 * 1000000
    end

    -- Check PTT - By Tarres!
    --NWS works as PTT when wheels up
    if (SR.getButtonPosition(135) > 0.5 or (SR.getButtonPosition(131) > 0.5 and SR.getButtonPosition(83) > 0.5)) then
        _data.ptt = true
    else
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- hotas radio

    return _data;
end

function SR.exportRadioP51(_data)

    _data.radios[2].name = "SCR522A"
    _data.radios[2].freq = SR.getRadioFrequency(24)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 116, { 0.0, 1.0 }, false)

    _data.selected = 1

    if (SR.getButtonPosition(44)) > 0.5 then
        _data.ptt = true
    else
        _data.ptt = false
    end

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- hotas radio

    return _data;
end

function SR.exportRadioFW190(_data)

    _data.radios[2].name = "FuG 16ZY"
    _data.radios[2].freq = SR.getRadioFrequency(15)
    _data.radios[2].modulation = 0
    _data.radios[2].volMode = 1
    _data.radios[2].volume = 1.0  --SR.getRadioVolume(0, 83,{0.0,1.0},true) Volume knob is not behaving..

    _data.selected = 1


    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- hotas radio

    return _data;
end

function SR.exportRadioBF109(_data)

    _data.radios[2].name = "FuG 16ZY"
    _data.radios[2].freq = SR.getRadioFrequency(14)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 130, { 0.0, 1.0 }, false)

    _data.selected = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- hotas radio

    return _data;
end

function SR.exportRadioSpitfireLFMkIX (_data)
    _data.radios[2].name = "A.R.I. 1063" --minimal bug in the ME GUI and in the LUA. SRC5222 is the P-51 radio.
    _data.radios[2].freq = SR.getRadioFrequency(15)
    _data.radios[2].modulation = 0
    _data.radios[2].volMode = 1
    _data.radios[2].volume = 1.0 --no volume control

    _data.selected = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[3].name = "AN/ARC-186(V)"
    _data.radios[3].freq = 124.8 * 1000000 --116,00-151,975 MHz
    _data.radios[3].modulation = 0
    _data.radios[3].secFreq = 121.5 * 1000000
    _data.radios[3].volume = 1.0
    _data.radios[3].freqMin = 116 * 1000000
    _data.radios[3].freqMax = 151.975 * 1000000
    _data.radios[3].volMode = 1
    _data.radios[3].freqMode = 1
    _data.radios[3].expansion = true

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].expansion = true
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0; -- no ptt, same as the FW and 109. No connector.

    return _data;
end

function SR.exportRadioC101EB(_data)

    _data.radios[1].name = "INTERCOM"
    _data.radios[1].freq = 100
    _data.radios[1].modulation = 2
    _data.radios[1].volume = SR.getRadioVolume(0, 403, { 0.0, 1.0 }, false)

    _data.radios[2].name = "AN/ARC-164 UHF"
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 234, { 0.0, 1.0 }, false)

    local _selector = SR.getSelectorPosition(232, 0.25)

    if _selector ~= 0 then
        _data.radios[2].freq = SR.getRadioFrequency(10)
    else
        _data.radios[2].freq = 1
    end

    -- UHF Guard
    if _selector == 2 then
        _data.radios[2].secFreq = 243.0 * 1000000
    end

    _data.radios[3].name = "AN/ARC-134"
    _data.radios[3].modulation = 0
    _data.radios[3].volume = SR.getRadioVolume(0, 412, { 0.0, 1.0 }, false)

    _data.radios[3].freq = SR.getRadioFrequency(9)

    local _selector = SR.getSelectorPosition(404, 0.5)

    if _selector == 1 then
        _data.selected = 1
    elseif _selector == 2 then
        _data.selected = 2
    else
        _data.selected = 0
    end

    --TODO figure our which cockpit you're in? So we can have controls working in the rear?

    _data.control = 1; -- full radio

    return _data;
end

function SR.exportRadioC101CC(_data)

    -- TODO - figure out channels.... it saves state??
    -- figure out volume
    _data.radios[1].name = "INTERCOM"
    _data.radios[1].freq = 100
    _data.radios[1].modulation = 2
    _data.radios[1].volume = SR.getRadioVolume(0, 403, { 0.0, 1.0 }, false)

    _data.radios[2].name = "V/TVU-740"
    _data.radios[2].freq = SR.getRadioFrequency(10)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = 1.0--SR.getRadioVolume(0, 234,{0.0,1.0},false)
    _data.radios[2].volMode = 1

    local _channel = SR.getButtonPosition(231)

    -- SR.log("Channel SELECTOR: ".. SR.getButtonPosition(231).."\n")

    local uhfModeKnob = SR.getSelectorPosition(232, 0.1)
    if uhfModeKnob == 2 and _data.radios[2].freq > 1000 then
        -- Function dial set to BOTH
        -- Listen to Guard as well as designated frequency
        _data.radios[2].secFreq = 243.0 * 1000000
    else
        -- Function dial set to OFF, MAIN, or ADF
        -- Not listening to Guard secondarily
        _data.radios[2].secFreq = 0
    end

    _data.radios[3].name = "VHF-20B"
    _data.radios[3].modulation = 0
    _data.radios[3].volume = 1.0 --SR.getRadioVolume(0, 412,{0.0,1.0},false)
    _data.radios[3].volMode = 1

    --local _vhfPower = SR.getSelectorPosition(413,1.0)
    --
    --if _vhfPower == 1 then
    _data.radios[3].freq = SR.getRadioFrequency(9)
    --else
    --    _data.radios[3].freq = 1
    --end
    --
    local _selector = SR.getSelectorPosition(404, 0.05)

    if _selector == 0 then
        _data.selected = 0
    elseif _selector == 2 then
        _data.selected = 2
    elseif _selector == 12 then
        _data.selected = 1
    else
        _data.selected = -1
    end

    --TODO figure our which cockpit you're in? So we can have controls working in the rear?

    _data.control = 1;

    return _data;
end

function SR.exportRadioHawk(_data)

    local MHZ = 1000000

    _data.radios[2].name = "AN/ARC-164 UHF"

    local _selector = SR.getSelectorPosition(221, 0.25)

    if _selector == 1 or _selector == 2 then

        local _hundreds = SR.getSelectorPosition(226, 0.25) * 100 * MHZ
        local _tens = SR.round(SR.getKnobPosition(0, 227, { 0.0, 0.9 }, { 0, 9 }), 0.1) * 10 * MHZ
        local _ones = SR.round(SR.getKnobPosition(0, 228, { 0.0, 0.9 }, { 0, 9 }), 0.1) * MHZ
        local _tenth = SR.round(SR.getKnobPosition(0, 229, { 0.0, 0.9 }, { 0, 9 }), 0.1) * 100000
        local _hundreth = SR.round(SR.getKnobPosition(0, 230, { 0.0, 0.3 }, { 0, 3 }), 0.1) * 10000

        _data.radios[2].freq = _hundreds + _tens + _ones + _tenth + _hundreth
    else
        _data.radios[2].freq = 1
    end
    _data.radios[2].modulation = 0
    _data.radios[2].volume = 1

    _data.radios[3].name = "ARI 23259/1"
    _data.radios[3].freq = SR.getRadioFrequency(7)
    _data.radios[3].modulation = 0
    _data.radios[3].volume = 1

    --guard mode for UHF Radio
    local _uhfKnob = SR.getSelectorPosition(221, 0.25)
    if _uhfKnob == 2 and _data.radios[2].freq > 1000 then
        _data.radios[2].secFreq = 243.0 * 1000000
    end

    --- is VHF ON?
    if SR.getSelectorPosition(391, 0.2) == 0 then
        _data.radios[3].freq = 1
    end
    --guard mode for VHF Radio
    local _vhfKnob = SR.getSelectorPosition(391, 0.2)
    if _vhfKnob == 2 and _data.radios[3].freq > 1000 then
        _data.radios[3].secFreq = 121.5 * 1000000
    end

    -- Radio Select Switch
    if (SR.getButtonPosition(265)) > 0.5 then
        _data.selected = 2
    else
        _data.selected = 1
    end

    _data.control = 1; -- full radio

    return _data;
end

local _mirageEncStatus = false
local _previousEncState = 0
function SR.exportRadioM2000C(_data)

    _data.radios[2].name = "TRT ERA 7000 V/UHF"
    _data.radios[2].freq = SR.getRadioFrequency(19)
    _data.radios[2].modulation = 0
    _data.radios[2].volume = SR.getRadioVolume(0, 707, { 0.0, 1.0 }, false)

    -- get channel selector
    local _selector = SR.getSelectorPosition(448, 0.50)

    if _selector == 1 then
        _data.radios[2].channel = SR.getSelectorPosition(445, 0.05)  --add 1 as channel 0 is channel 1 
    end

    _data.radios[3].name = "TRT ERA 7200 UHF"
    _data.radios[3].freq = SR.getRadioFrequency(20)
    _data.radios[3].modulation = 0
    _data.radios[3].volume = SR.getRadioVolume(0, 706, { 0.0, 1.0 }, false)

    _data.radios[3].encKey = 1
    _data.radios[3].encMode = 3 -- 3 is Incockpit toggle + Gui Enc Key setting

    --  local _switch = SR.getButtonPosition(700) -- remmed, the connectors are being coded, maybe soon will be a full radio.

    --    if _switch == 1 then
    --      _data.selected = 0
    --  else
    --     _data.selected = 1
    -- end

    --guard mode for V/UHF Radio
    local uhfModeKnob = SR.getSelectorPosition(446, 0.25) -- TODO!
    if uhfModeKnob == 2 and _data.radios[2].freq > 1000 then
        _data.radios[2].secFreq = 243.0 * 1000000
    end

    -- reset state on aircraft switch
    if _lastUnitId ~= _data.unitId then
        _mirageEncStatus = false
        _previousEncState = 0
    end

    -- handle the button no longer toggling...
    if SR.getButtonPosition(432) > 0.5 and _previousEncState < 0.5 then
        --431

        if _mirageEncStatus then
            _mirageEncStatus = false
        else
            _mirageEncStatus = true
        end
    end

    _data.radios[3].enc = _mirageEncStatus

    _previousEncState = SR.getButtonPosition(432)

    _data.control = 0; -- partial radio, allows hotkeys

    return _data
end

function SR.exportRadioAV8BNA(_data)

    _data.radios[2].name = "ARC-210 COM 1"
    _data.radios[2].freq = SR.getRadioFrequency(2)
    _data.radios[2].modulation = SR.getRadioModulation(2)
    _data.radios[2].volume = SR.getRadioVolume(0, 298, { 0.0, 1.0 }, false)

    -- get channel selector
    --  local _selector  = SR.getSelectorPosition(448,0.50)

    --if _selector == 1 then
    --_data.radios[2].channel =  SR.getSelectorPosition(178,0.01)  --add 1 as channel 0 is channel 1 
    --end

    _data.radios[3].name = "ARC-210 COM 2"
    _data.radios[3].freq = SR.getRadioFrequency(3)
    _data.radios[3].modulation = SR.getRadioModulation(3)
    _data.radios[3].volume = SR.getRadioVolume(0, 299, { 0.0, 1.0 }, false)

    --https://en.wikipedia.org/wiki/AN/ARC-210

    -- EXTRA Radio - temporary extra radio
    --https://en.wikipedia.org/wiki/AN/ARC-210
    --_data.radios[4].name = "ARC-210 COM 3"
    --_data.radios[4].freq = 251.0*1000000 --225-399.975 MHZ
    --_data.radios[4].modulation = 0
    --_data.radios[4].secFreq = 243.0*1000000
    --_data.radios[4].volume = 1.0
    --_data.radios[4].freqMin = 108*1000000
    --_data.radios[4].freqMax = 512*1000000
    --_data.radios[4].expansion = false
    --_data.radios[4].volMode = 1
    --_data.radios[4].freqMode = 1
    --_data.radios[4].encKey = 1
    --_data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting


    _data.selected = 1
    _data.control = 0; -- partial radio, allows hotkeys

    return _data
end

--for F-14
function SR.exportRadioF14(_data)
    local ics_devid = 2
    local arc159_devid = 3
    local arc182_devid = 4

    local ICS_device = GetDevice(ics_devid)
    local ARC159_device = GetDevice(arc159_devid)
    local ARC182_device = GetDevice(arc182_devid)

    local intercom_transmit = ICS_device:intercom_transmit()
    local ARC159_ptt = ARC159_device:is_ptt_pressed()
    local ARC182_ptt = ARC182_device:is_ptt_pressed()

    _data.radios[1].name = "Intercom"
    _data.radios[1].freq = 100.0
    _data.radios[1].modulation = 2 --Special intercom modulation
    _data.radios[1].volume = ICS_device:get_volume()

    _data.radios[2].name = "AN/ARC-159(V)"
    _data.radios[2].freq = ARC159_device:is_on() and SR.round(ARC159_device:get_frequency(), 5000) or 1
    _data.radios[2].modulation = ARC159_device:get_modulation()
    _data.radios[2].volume = ARC159_device:get_volume()
    if ARC159_device:is_guard_enabled() then
        _data.radios[2].secFreq = 243.0 * 1000000
    else
        _data.radios[2].secFreq = 0
    end
    _data.radios[2].freqMin = 225 * 1000000
    _data.radios[2].freqMax = 399.975 * 1000000
    _data.radios[2].encKey = ICS_device:get_ky28_key()
    _data.radios[2].enc = ICS_device:is_arc159_encrypted()
    _data.radios[2].encMode = 2

    _data.radios[3].name = "AN/ARC-182(V)"
    _data.radios[3].freq = ARC182_device:is_on() and SR.round(ARC182_device:get_frequency(), 5000) or 1
    _data.radios[3].modulation = ARC182_device:get_modulation()
    _data.radios[3].volume = ARC182_device:get_volume()
    if ARC182_device:is_guard_enabled() then
        _data.radios[3].secFreq = SR.round(ARC182_device:get_guard_freq(), 5000)
    else
        _data.radios[3].secFreq = 0
    end
    _data.radios[3].freqMin = 30 * 1000000
    _data.radios[3].freqMax = 399.975 * 1000000
    _data.radios[3].encKey = ICS_device:get_ky28_key()
    _data.radios[3].enc = ICS_device:is_arc182_encrypted()
    _data.radios[3].encMode = 2

    if (ARC182_ptt) then
        _data.selected = 2 -- radios[3] ARC-182
        _data.ptt = true
    elseif (ARC159_ptt) then
        _data.selected = 1 -- radios[2] ARC-159
        _data.ptt = true
    elseif (intercom_transmit) then
        _data.selected = 0 -- radios[1] intercom
        _data.ptt = true
    else
        _data.selected = -1
        _data.ptt = false
    end

    _data.control = 1 -- full radio

    return _data
end

function SR.exportRadioAJS37(_data)


    _data.radios[2].name = "FR 22"
    _data.radios[2].freq = SR.getRadioFrequency(31)
    _data.radios[2].modulation = SR.getRadioModulation(31)

    --   local _modulation =SR.getButtonPosition(3008)

    --   if _modulation > 0.5 then
    --       _data.radios[3].modulation = 1
    --   else
    --       _data.radios[3].modulation = 0
    --   end

    _data.radios[2].volume = 1.0
    _data.radios[2].volMode = 1

    _data.radios[3].name = "FR 24"
    _data.radios[3].freq = SR.getRadioFrequency(30)
    _data.radios[3].modulation = SR.getRadioModulation(30)
    _data.radios[3].volume = 1.0-- SR.getRadioVolume(0, 3112,{0.00001,1.0},false) volume not working yet
    _data.radios[3].volMode = 1

    -- Expansion Radio - Server Side Controlled
    _data.radios[4].name = "AN/ARC-164 UHF"
    _data.radios[4].freq = 251.0 * 1000000 --225-399.975 MHZ
    _data.radios[4].modulation = 0
    _data.radios[4].secFreq = 243.0 * 1000000
    _data.radios[4].volume = 1.0
    _data.radios[4].freqMin = 225 * 1000000
    _data.radios[4].freqMax = 399.975 * 1000000
    _data.radios[4].expansion = true
    _data.radios[4].volMode = 1
    _data.radios[4].freqMode = 1
    _data.radios[4].encKey = 1
    _data.radios[4].encMode = 1 -- FC3 Gui Toggle + Gui Enc key setting

    _data.control = 0;
    _data.selected = 1

    return _data
end

function SR.getRadioVolume(_deviceId, _arg, _minMax, _invert)

    local _device = GetDevice(_deviceId)

    if not _minMax then
        _minMax = { 0.0, 1.0 }
    end

    if _device then
        local _val = tonumber(_device:get_argument_value(_arg))
        local _reRanged = SR.rerange(_val, _minMax, { 0.0, 1.0 })  --re range to give 0.0 - 1.0

        if _invert then
            return SR.round(math.abs(1.0 - _reRanged), 0.005)
        else
            return SR.round(_reRanged, 0.005);
        end
    end
    return 1.0
end

function SR.getKnobPosition(_deviceId, _arg, _minMax, _mapMinMax)

    local _device = GetDevice(_deviceId)

    if _device then
        local _val = tonumber(_device:get_argument_value(_arg))
        local _reRanged = SR.rerange(_val, _minMax, _mapMinMax)

        return _reRanged
    end
    return -1
end

function SR.getSelectorPosition(_args, _step)
    local _value = GetDevice(0):get_argument_value(_args)
    local _num = math.abs(tonumber(string.format("%.0f", (_value) / _step)))

    return _num

end

function SR.getButtonPosition(_args)
    local _value = GetDevice(0):get_argument_value(_args)

    return _value

end

function SR.getRadioFrequency(_deviceId, _roundTo)
    local _device = GetDevice(_deviceId)

    if not _roundTo then
        _roundTo = 5000
    end

    if _device then
        if _device:is_on() then
            -- round as the numbers arent exact
            return SR.round(_device:get_frequency(), _roundTo)
        end
    end
    return 1
end

function SR.getRadioModulation(_deviceId)
    local _device = GetDevice(_deviceId)

    local _modulation = 0

    if _device then

        pcall(function()
            _modulation = _device:get_modulation()
        end)

    end
    return _modulation
end

function SR.rerange(_val, _minMax, _limitMinMax)
    return ((_limitMinMax[2] - _limitMinMax[1]) * (_val - _minMax[1]) / (_minMax[2] - _minMax[1])) + _limitMinMax[1];

end

function SR.round(number, step)
    if number == 0 then
        return 0
    else
        return math.floor((number + step / 2) / step) * step
    end
end

function SR.nearlyEqual(a, b, diff)
    return math.abs(a - b) < diff
end

SR.log("Loaded SimpleRadio Standalone Export version:1.6.3.0")