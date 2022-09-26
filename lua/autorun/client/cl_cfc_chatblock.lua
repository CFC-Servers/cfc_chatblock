local blockedPlayers = {}
local blockList

gameevent.Listen( "player_disconnect" )

if file.Exists( "cfc_chat_blocked_players.json", "DATA" ) then
    local fileContent = file.Read( "cfc_chat_blocked_players.json", "DATA" )
    blockedPlayers = util.JSONToTable( fileContent )
end

local function nameToSteamID( string )
    for _, ply in ipairs( player.GetAll() ) do
        if ply:GetName() == string then
            return ply:SteamID()
        end
    end
end

local function addLines( ply )
    if ply == LocalPlayer() then return end

    local name = ply:GetName()
    local steamID = nameToSteamID( name )

    if blockedPlayers[steamID] then
        blockList:AddLine( name, "true" )
    else
        blockList:AddLine( name, "false" )
    end
end

local function updateBlockList()
    if not blockList then return end
    blockList:Clear()

    for _, ply in ipairs( player.GetHumans() ) do
        addLines( ply )
    end
end

local function updateFile()
    local jsonTableSave = util.TableToJSON( blockedPlayers, true )
    file.Write( "cfc_chat_blocked_players.json", jsonTableSave )
end

hook.Add( "OnPlayerChat", "CFC_ChatBlock_CheckPlayer", function( ply )
    if not IsValid( ply ) or not ply:IsPlayer() then return end
    if blockedPlayers[ply:SteamID()] then
        return true
    end
end )

hook.Add( "AddToolMenuCategories", "CFC_ChatBlock_AddToolMenuCategories", function()
    spawnmenu.AddToolCategory( "Options", "CFC", "#CFC" )
end )

hook.Add( "PopulateToolMenu", "CFC_ChatBlock_PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption( "Options", "CFC", "cfc_chatblock", "#Block list", "", "", function( panel )
        panel:Help( "Blocked players:" )

        blockList = vgui.Create( "DListView", f )
        blockList:SetTall( 250 )
        blockList:SetMultiSelect( false )
        blockList:AddColumn( "Name" )
        blockList:AddColumn( "Blocked" )

        updateBlockList()

        panel:AddItem( blockList )
        blockList:SelectFirstItem()

        local toggleButton = vgui.Create( "DButton" )
        toggleButton:SetText( "Block / Unblock selected player" )
        toggleButton.DoClick = function()
            local line = blockList:GetLine( blockList:GetSelectedLine() )
            if not line then return end

            local ply
            for _, temp in ipairs( player.GetAll() ) do
                if temp:GetName() == line.Columns[1]:GetValue() then
                    ply = temp
                end
            end

            if not ply then return end

            local steamId = ply:SteamID()
            if line.Columns[2]:GetValue() == "true" then
                line:SetColumnText( 2, "false" )
                blockedPlayers[steamId] = nil
            else
                line:SetColumnText( 2, "true" )
                blockedPlayers[steamId] = "true"
            end
            updateFile()
        end
        panel:AddItem( toggleButton )
    end )
end )

hook.Add( "PlayerConnect", "CFC_ChatBlock_PlayerConnect", updateBlockList )
hook.Add( "player_disconnect", "player_disconnect_example", updateBlockList )
