net.Receive("notify_coup_success", function()
    local ply = net.ReadEntity()

    surface.PlaySound("buttons/lightswitch2.wav")
    chat.AddText(Color(255, 20, 20, 255), "[DarkRP] ", Color(200, 200, 200, 255), string.format("The Mayor has been coup d'etat and %s has become the new Mayor!", ply:Nick()))
end)

net.Receive("notify_coup_failure", function()
    surface.PlaySound("buttons/lightswitch2.wav")
    chat.AddText(Color(255, 20, 20, 255), "[DarkRP] ", Color(200, 200, 200, 255), "A coup d'etat has failed and the user's have been wanted!")
end)

local CoupVersion = "1.0"

-- Really only for the developer/powerusers
concommand.Add("coup_system_info", function()
	local InfoTable = {
		"https://steamcommunity.com/sharedfiles/filedetails/?id=3246928845 created by Haze_of_dream",
		"",
		"Contact at: ",
		"STEAM_0:1:75838598",
		"https:/steamcommunity.com/id/Haze_of_dream",
		"",
		string.format("Coup d'etat Version: %s", CoupVersion)
	}
	
	for _, msg in pairs(InfoTable) do
		print(msg)
	end
end)