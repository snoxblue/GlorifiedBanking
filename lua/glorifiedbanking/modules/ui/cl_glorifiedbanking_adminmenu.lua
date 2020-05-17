
local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() * .42, ScrH() * .8)
    self:Center()
    self:MakePopup()

    self.Theme = GlorifiedBanking.Themes.GetCurrent()

    self.Navbar = vgui.Create("GlorifiedBanking.AdminNavbar", self)

    local function changePage(page)
        if not IsValid(self.Page) then
            self.Page = vgui.Create(page, self)
            self.Page:Dock(FILL)

            return
        end

        self.Page:AlphaTo(0, 0.15, 0, function(anim, panel)
            self.Page:Remove()

            self.Page = vgui.Create(page, self)
            self.Page:Dock(FILL)
            self.Page:SetAlpha(0)
            self.Page:AlphaTo(255, 0.15)
        end)
    end

    self.Navbar:AddItem("PLAYERS", LEFT, function(s) changePage("GlorifiedBanking.Players") end)

    self.Navbar:AddItem("LOGS", LEFT, function(s) changePage("GlorifiedBanking.Logs") end)

    self.Navbar:AddItem("SETTINGS", LEFT, function(s) changePage("GlorifiedBanking.Logs") end)

    self.Navbar:AddItem("X", RIGHT, function(s)
        self:AlphaTo(0, 0.3, 0, function(anim, panel)
            panel:Remove()
        end)
    end)

    self.Navbar:SelectTab(1)
    changePage("GlorifiedBanking.Players")

    self:SetAlpha(0)
    self:AlphaTo(255, 0.3)
end

function PANEL:PerformLayout(w, h)
    self.Navbar:Dock(TOP)
    self.Navbar:SetSize(w, h * .06)

    if IsValid(self.Page) then
        self.Page:Dock(FILL)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(6, 0, 0, w, h, self.Theme.Data.Colors.adminMenuBackgroundCol)
end

vgui.Register("GlorifiedBanking.AdminMenu", PANEL, "EditablePanel")

if IsValid(GlorifiedBanking.UI.AdminMenu) then
    GlorifiedBanking.UI.AdminMenu:Remove()
    GlorifiedBanking.UI.AdminMenu = nil
end

if not IsValid(LocalPlayer()) then return end
GlorifiedBanking.UI.AdminMenu = vgui.Create("GlorifiedBanking.AdminMenu")
print("Reloaded admin menu")
