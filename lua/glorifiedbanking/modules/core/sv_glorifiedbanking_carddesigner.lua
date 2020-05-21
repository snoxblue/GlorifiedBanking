
local defaultDesign = {
    imgur = "Filf1VB",
    namePos = { .042, .73 },
    nameAlign = TEXT_ALIGN_LEFT,
    idPos = { .042, .85 },
    idAlign = TEXT_ALIGN_LEFT
}

local cardDesign

function GlorifiedBanking.GetCardDesign()
    return cardDesign
end

function GlorifiedBanking.SetCardDesign( imgurId, nameX, nameY, nameAlign, idX, idY, idAlign )
    cardDesign = {
        imgur = imgurId,
        namePos = {nameX, nameY},
        nameAlign = nameAlign,
        idPos = {idX, idY},
        idAlign = idAlign
    }

    cookie.Set( "GlorifiedBanking.CardDesign", util.TableToJSON( cardDesign ) )
end

function GlorifiedBanking.SendCardDesign( recipients )
    net.Start( "GlorifiedBanking.CardDesigner.SendDesignInfo" )
     net.WriteString( cardDesign.imgur )
     net.WriteFloat( cardDesign.namePos[1] )
     net.WriteFloat( cardDesign.namePos[2] )
     net.WriteUInt( cardDesign.nameAlign, 2)
     net.WriteFloat( cardDesign.idPos[1] )
     net.WriteFloat( cardDesign.idPos[2] )
     net.WriteUInt( cardDesign.idAlign, 2 )
    net.Send( recipients )
end

hook.Add( "PlayerInitialSpawn", "GlorifiedBanking.CardDesigner.PlayerInitialSpawn", function( ply )
    hook.Add( "SetupMove", "GlorifiedBanking.CardDesigner.FullLoad." .. ply:UserID(), function( ply2, _, cmd )
        if ply == ply2 and not cmd:IsForced() then
            GlorifiedBanking.SendCardDesign( ply )
            hook.Remove( "SetupMove", "GlorifiedBanking.CardDesigner.FullLoad." .. ply:UserID() )
        end
    end )
end )

hook.Add( "PlayerDisconnected", "GlorifiedBanking.CardDesigner.PlayerDisconnected", function( ply )
    hook.Remove( "SetupMove", "GlorifiedBanking.CardDesigner.FullLoad." .. ply:UserID() )
end )

cardDesign = util.JSONToTable(cookie.GetString( "GlorifiedBanking.Theme", false )) or table.Copy(defaultDesign)
