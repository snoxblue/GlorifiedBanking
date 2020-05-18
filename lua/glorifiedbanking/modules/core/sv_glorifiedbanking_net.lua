
--[[
    This file contains a lot of validation and authentication checks.
    Some of them may seem unnecessary, but it's never worth taking chances with an addon based purely around the server's economy.
    Extra validation checks are held on the actual player meta functions in the sv_glorifiedbanking_playermeta.lua file.
]]--

util.AddNetworkString( "GlorifiedBanking.WithdrawalRequested" )
util.AddNetworkString( "GlorifiedBanking.DepositRequested" )
util.AddNetworkString( "GlorifiedBanking.TransferRequested" )

util.AddNetworkString( "GlorifiedBanking.SendAnimation" )
util.AddNetworkString( "GlorifiedBanking.CardInserted" )
util.AddNetworkString( "GlorifiedBanking.Logout" )
util.AddNetworkString( "GlorifiedBanking.ChangeScreen" )
util.AddNetworkString( "GlorifiedBanking.ChangeScreen.SendLogs" )
util.AddNetworkString( "GlorifiedBanking.ForceLoad" )

util.AddNetworkString( "GlorifiedBanking.AdminPanel.OpenAdminPanel" )
util.AddNetworkString( "GlorifiedBanking.AdminPanel.SetPlayerBalance" )
util.AddNetworkString( "GlorifiedBanking.AdminPanel.SetLockdownStatus" )
util.AddNetworkString( "GlorifiedBanking.AdminPanel.PlayerListOpened" )
util.AddNetworkString( "GlorifiedBanking.AdminPanel.PlayerListOpened.SendInfo" )
util.AddNetworkString( "GlorifiedBanking.AdminPanel.RequestLogUpdate" )
util.AddNetworkString( "GlorifiedBanking.AdminPanel.RequestLogUpdate.SendInfo" )

local function PlayerAuthChecks( ply )
    return not ( not ply:IsValid()
    or ply:IsBot()
    or not ply:IsFullyAuthenticated()
    or not ply:IsConnected() )
end

local function ATMDistanceChecks( ply, atmEntity )
    local maxDistance = GlorifiedBanking.Config.MAXIMUM_DISTANCE_FROM_ATM
    return atmEntity:GetPos():DistToSqr( ply:GetPos() ) <= maxDistance * maxDistance
end

local function ValidationChecks( ply, balance, atmEntity )
    return not ( GlorifiedBanking.LockdownEnabled
    or not balance
    or balance == nil
    or balance < 0
    or not PlayerAuthChecks( ply )
    or atmEntity:GetClass() != "glorifiedbanking_atm"
    or atmEntity.ForcedLoad
    or not ATMDistanceChecks( ply, atmEntity ) )
end

net.Receive( "GlorifiedBanking.WithdrawalRequested", function( len, ply )
    local amount = net.ReadUInt( 32 )
    local atmEntity = net.ReadEntity()
    if not ValidationChecks( ply, amount, atmEntity ) then return end

    atmEntity:Withdraw(ply, amount)
end )

net.Receive( "GlorifiedBanking.DepositRequested", function( len, ply )
    local amount = net.ReadUInt( 32 )
    local atmEntity = net.ReadEntity()
    if not ValidationChecks( ply, amount, atmEntity ) then return end

    atmEntity:Deposit(ply, amount)
end )

net.Receive( "GlorifiedBanking.TransferRequested", function( len, ply )
    local amount = net.ReadUInt( 32 )
    local atmEntity = net.ReadEntity()
    if not ValidationChecks( ply, amount, atmEntity ) then return end
    local receiver = net.ReadEntity()
    if not PlayerAuthChecks( receiver ) then return end

    atmEntity:Transfer( ply, receiver, amount )
end )

net.Receive( "GlorifiedBanking.CardInserted", function( len, ply )
    local atmEntity = net.ReadEntity()
    if not GlorifiedBanking.LockdownEnabled
    and atmEntity:GetClass() == "glorifiedbanking_atm"
    and atmEntity:GetCurrentUser() == NULL
    and ply:GetActiveWeapon():GetClass() == "glorifiedbanking_card"
    and PlayerAuthChecks( ply )
    and ATMDistanceChecks( ply, atmEntity ) then
        atmEntity:InsertCard( ply )
    end
end )

net.Receive( "GlorifiedBanking.Logout", function( len, ply )
    local atmEntity = net.ReadEntity()
    if atmEntity:GetClass() == "glorifiedbanking_atm"
    and atmEntity:GetCurrentUser() == ply then
        if atmEntity.ForcedLoad then
            atmEntity:EmitSound("GlorifiedBanking.Beep_Error")
            return
        end

        atmEntity:Logout()
        atmEntity:EmitSound("GlorifiedBanking.Beep_Normal")
    end
end )

net.Receive( "GlorifiedBanking.ChangeScreen", function( len, ply )
    local newScreen = net.ReadUInt( 4 )
    local atmEntity = net.ReadEntity()
    if atmEntity:GetClass() == "glorifiedbanking_atm"
    and atmEntity:GetCurrentUser() == ply
    and atmEntity.Screens[newScreen] then
        if atmEntity.ForcedLoad then
            atmEntity:EmitSound( "GlorifiedBanking.Beep_Error" )
            return
        end

        atmEntity:SetScreenID( newScreen )
        atmEntity:EmitSound( "GlorifiedBanking.Beep_Normal" )
        atmEntity.LastAction = CurTime()

        if newScreen == 7 then -- Is this screen the transaction history screen?
            GlorifiedBanking.SQL.Query( "SELECT * FROM `gb_logs` WHERE `SteamID` = '" .. ply:SteamID() .. "' OR `ReceiverSteamID` = '" .. ply:SteamID() .. "'ORDER BY `Date` DESC LIMIT 10", function( queryResult )
                net.Start( "GlorifiedBanking.ChangeScreen.SendLogs" )
                net.WriteEntity( atmEntity )
                net.WriteLargeString( util.TableToJSON( queryResult ) )
                net.Send( ply )
            end )
        end
    end
end )

net.Receive( "GlorifiedBanking.AdminPanel.SetPlayerBalance", function( len, ply )
    if GlorifiedBanking.HasPermission( ply, "glorifiedbanking_setplayerbalance" ) then
        local plySteamID = net.ReadString()
        local newBalance = net.ReadUInt( 32 )
        GlorifiedBanking.SetPlayerBalanceBySteamID( plySteamID, newBalance )
    end
end )

net.Receive( "GlorifiedBanking.AdminPanel.SetLockdownStatus", function( len, ply )
    if GlorifiedBanking.HasPermission( ply, "glorifiedbanking_togglelockdown" ) then
        local newStatus = net.ReadBool()
        GlorifiedBanking.SetLockdownStatus( newStatus )
    end
end )

net.Receive( "GlorifiedBanking.AdminPanel.PlayerListOpened", function( len, ply )
    if GlorifiedBanking.HasPermission( ply, "glorifiedbanking_openadminpanel" ) then
        local playerList = {}
        for k, v in ipairs( player.GetAll() ) do
            playerList[ v:SteamID() ] = GlorifiedBanking.GetPlayerBalance( v )
        end

        net.Start( "GlorifiedBanking.AdminPanel.PlayerListOpened.SendInfo" )
        net.WriteLargeString( util.TableToJSON( playerList ) )
        net.Send( ply )
    end
end )

net.Receive( "GlorifiedBanking.AdminPanel.RequestLogUpdate", function( len, ply )
    if GlorifiedBanking.HasPermission( ply, "glorifiedbanking_openadminpanel" ) then
        local pageNumber = net.ReadUInt( 16 )
        local itemLimit = net.ReadUInt( 6 )
        local filter = net.ReadString()
        local filterSteamID = net.ReadString()
        if filter != "All" and filter != "Withdrawals" and filter != "Deposits" and filter != "Transfers" then return end
        local query = "SET @row_number:=0; SELECT @row_number:=@row_number+1 AS `row_number`,`Date`,`Type`,`SteamID`,`ReceiverSteamID`,`Amount` FROM `gb_logs` WHERE "

        if filter != "All" then
            query = query .. "`Type` = '" .. filter .. "' AND "
        end

        if filterSteamID != "NONE" then
            query = query .. "`SteamID` = '" .. filterSteamID .. "' AND "
        end

        local startLimit = pageNumber == 1 and 1 or ( pageNumber - 1 ) * itemLimit
        local endLimit = pageNumber == 1 and itemLimit or pageNumber * itemLimit
        query = query .. "row_number BETWEEN " .. startLimit .. " AND " .. endLimit
        GlorifiedBanking.SQL.Query( query, function( queryResult )
            net.Start( "GlorifiedBanking.AdminPanel.RequestLogUpdate.SendInfo" )
            net.WriteLargeString( util.TableToJSON( queryResult ) )
            net.Send( ply )
        end )
    end
end )

concommand.Add( "glorifiedbanking_admin", function( ply )
    if not IsValid( ply ) then return end
    if GlorifiedBanking.HasPermission( ply, "glorifiedbanking_openadminpanel" ) then
        net.Start( "GlorifiedBanking.AdminPanel.OpenAdminPanel" )
        net.WriteBool( GlorifiedBanking.LockdownEnabled )
        net.WriteBool( GlorifiedBanking.HasPermission( ply, "glorifiedbanking_setplayerbalance" ) )
        net.Send( ply )
    end
end )