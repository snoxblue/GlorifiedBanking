
GlorifiedBanking.UI = GlorifiedBanking.UI or {}

local lerp = Lerp
function GlorifiedBanking.UI.LerpColor( t, from, to )
    local col = Color( 0, 0, 0 )

    col.r = lerp( t, from.r, to.r )
    col.g = lerp( t, from.g, to.g )
    col.b = lerp( t, from.b, to.b )
    col.a = lerp( t, from.a, to.a )

    return col
end

function GlorifiedBanking.UI.StartCutOut(areaDraw)
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)

    render.SetStencilWriteMask(1)
    render.SetStencilTestMask(1)
    render.SetStencilReferenceValue(1)

    render.OverrideColorWriteEnable(true, false)

    areaDraw()

    render.OverrideColorWriteEnable(false, false)

    render.SetStencilCompareFunction(STENCIL_EQUAL)
end

function GlorifiedBanking.UI.EndCutOut()
    render.SetStencilEnable(false)
end

file.CreateDir("glorifiedbanking")
function GlorifiedBanking.UI.GetImgur(id, callback, useproxy)
    if file.Exists("glorifiedbanking/" .. id .. ".png", "DATA") then
        return callback(Material("../data/glorifiedbanking/" .. id .. ".png", "noclamp smooth"))
    end

    http.Fetch(useproxy and "https://proxy.duckduckgo.com/iu/?u=https://i.imgur.com" or "https://i.imgur.com/" .. id .. ".png",
        function(body, len, headers, code)
            file.Write("glorifiedbanking/" .. id .. ".png", body)
            return callback(Material("../data/glorifiedbanking/" .. id .. ".png", "noclamp smooth"))
        end,
        function(error)
            if useproxy then return callback(Material("nil")) end
            return GlorifiedBanking.UI.GetImgur(id, callback, true)
        end
    )
end
