_handle = execVM "common.sqf"; 
waitUntil { scriptDone _handle };

["TaskLocations", "1"] call dingus_fnc_setVar;

["Boarding", "0"] call dingus_fnc_setVar;
["Boarded", "0"] call dingus_fnc_setVar;
["Transporting", "0"] call dingus_fnc_setVar;
["Arrived", "0"] call dingus_fnc_setVar;

["CurrentLocation", ""] call dingus_fnc_setVar;
["DestinationLocation", ""] call dingus_fnc_setVar;

["CurrentVehicle", car1] call dingus_fnc_setVar;
["CurrentPassenger", nil] call dingus_fnc_setVar;

execVM "vehicleHelpers.sqf";

//Initialize locations and passengers
_handle2 = execVM "passengers.sqf";
waitUntil { scriptDone _handle2 };
[] call dingus_fnc_initializeLocations;

//Initialize Passengers
_handle3 = execVM "ai.sqf";
waitUntil { scriptDone _handle3 };
[] call dingus_fnc_spawnFixedAI;
