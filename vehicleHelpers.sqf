dingus_fnc_PlayerVehicleChanged = {
  _veh = vehicle player;

  if (_veh == player) then {
    ["CurrentVehicle", nil] call dingus_fnc_setVar;  
  } else {
    ["CurrentVehicle", vehicle player] call dingus_fnc_setVar;
  };
};
