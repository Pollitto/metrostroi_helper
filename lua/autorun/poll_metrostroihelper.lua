if not Metrostroi or not Metrostroi.Version or Metrostroi.Version < 1496343479 then Msg("This Metrostroi version isn't compatible for helper.\n") end
AddCSLuaFile()
if SERVER then
	util.AddNetworkString("MTHelper")

	local trainFilter = {
		"gmod_subway_81-717_mvm",
		"gmod_subway_81-717_lvz",
		"gmod_subway_81-502",
		"gmod_subway_81-703",
		"gmod_subway_ezh",
		"gmod_subway_ezh3",
	}
	local trains = {}
	hook.Add("PlayerEnteredVehicle", "MTHelperEnter", function(ply, veh, _)
		if not veh:GetNW2Entity("TrainEntity") then return end
		if !table.HasValue( trainFilter, veh:GetNW2Entity("TrainEntity"):GetClass() ) then return end

		if !table.HasValue( trains, veh:GetNW2Entity("TrainEntity") ) then
			table.insert( trains, veh:GetNW2Entity("TrainEntity") )
		end
		net.Start("MTHelper")
			net.WriteBool(false)
			net.WriteEntity(veh)
		net.Send(ply)
	end)

	hook.Add("PlayerLeaveVehicle", "MTHelperLeave", function(ply, veh)
		if not veh:GetNW2Entity("TrainEntity") then return end
		if !table.HasValue( trainFilter, veh:GetNW2Entity("TrainEntity"):GetClass() ) then return end

		if table.HasValue( trains, veh:GetNW2Entity("TrainEntity") ) then
			table.RemoveByValue( trains, veh:GetNW2Entity("TrainEntity") )
		end
		net.Start("MTHelper")
			net.WriteBool(true)
			net.WriteEntity(veh)
		net.Send(ply)
	end)

	hook.Add("Think", "MTHelperThink", function()
		for k, train in pairs(trains) do
			if !IsValid(train) then return end
			--print(train.RheostatController.SelectedPosition)
			train:SetNW2Int("RKPos", train.RheostatController.SelectedPosition or 0)
			train:SetNW2Int("KVPos", train.KV.ControllerPosition or 0)
			train:SetNW2Int("PS", train.PositionSwitch.PS or 0)
			train:SetNW2Int("PP", train.PositionSwitch.PP or 0)
			train:SetNW2Int("PM", train.PositionSwitch.PM or 0)
			train:SetNW2Int("PT", train.PositionSwitch.PT or 0)
			--print(train.PositionSwitch.PPS)
		end
	end)
else
	CreateClientConVar("metrostroi_helper", "0", true, false, "0 - disable, 1 - show help info about train systems.")
	local train = nil
	local inSeat = false

	surface.CreateFont("MTHelperFont", {
		font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = true,
		size = 24,
		weight = 700,
		antialias = false,
		underline = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = true,
	})

	local function HelperShow()
		print(train)

		if GetConVar("metrostroi_helper"):GetInt() == 1 then

			local RK = 0
			local PS = 0
			local PP = 0
			local PM = 0
			local PT = 0
			local KV = 0
			local PPS = ""
			local PMT = ""
			local KVpos = {
				[-3] = "T2",
				[-2] = "T1a",
				[-1] = "T1",
				[0] = "0",
				[1] = "X1",
				[2] = "X2",
				[3] = "X3",
			}
			
			hook.Add("HUDPaint", "MTHelperHUD", function()
				RK = math.Round( train:GetNW2Int("RKPos") or 0 )
				KV = math.Round( train:GetNW2Int("KVPos") or 0 )
				PS = math.Round( train:GetNW2Int("PS") or 0 )
				PP = math.Round( train:GetNW2Int("PP") or 0 )
				PM = math.Round( train:GetNW2Int("PM") or 0 )
				PT = math.Round( train:GetNW2Int("PT") or 0 )

				PPS = PS == 1 and "Series connection" or PP == 1 and "Parallel connection" or "N/A"
				PMT = PM == 1 and "Drive mode" or PT == 1 and "Brake mode" or "N/A"

				draw.DrawText( "RK position: "..RK, "MTHelperFont", ScrW() * 0.876, ScrH() * 0.75, Color( 230, 230, 180, 255 ), TEXT_ALIGN_LEFT )
				draw.DrawText( "\n"..PMT.."\n"..PPS, "MTHelperFont", ScrW() * 0.99, ScrH() * 0.75, Color( 230, 230, 180, 255 ), TEXT_ALIGN_RIGHT )
				draw.DrawText( "\n\n\nPower controller: "..KVpos[KV], "MTHelperFont", ScrW() * 0.84, ScrH() * 0.75, Color( 230, 230, 180, 255 ), TEXT_ALIGN_LEFT )
			end)
		end
	end
	local function HelperHide()
		hook.Remove("HUDPaint", "MTHelperHUD")
		print("helper removed")
	end

	net.Receive("MTHelper", function()
		inSeat = net.ReadBool()
		if inSeat then
			HelperHide()
		else
			local veh = net.ReadEntity()
			train = veh:GetNW2Entity("TrainEntity")
			HelperShow()
		end
	end)

	cvars.AddChangeCallback( "metrostroi_helper", function(cvar_name, old_val, new_val)
		if new_val == "0" then
			HelperHide()
		elseif inSeat then
			HelperShow()
		end
	end, "MTHelperCallback")
end