/*two problems

1. when I drop someone off, their action is no longer valid (unless we re-enable that code). it's supposed to prevent them from being assigned to the current location
  - Option 1: Re-enable the code that checks for 'current location' and uses it if the two are different
  - Option 2: Remove units that have been dropped off

2. when I leave an area we automatically spawn someone new. We don't need to if there is already someone there.
  - Option 1: Use variables to solve this. When we spawn someone, set a var for that location. Don't re-gen if there is already a value in that var (fishdockspassenger)

3. If you damage your vehicle and he pops out of your vehicle how do you get him back in to one?

Gamify it? Add score/money earned, a timer or countdown.

How many can you get in such a period.

Add traffic dynamically

Merge the two together, and make it multiplayer?

New"

Place where people can spawn but it not be a drop off (eg taxi stand)

Should we make a task for picking up the next person?

I don't like how the passengers respawn right now. It's too quick. I should add a delay to the triggers

*/

dingus_fnc_initializeLocations = {
  _markers = ["m_georgetownchurch", "m_fishdocks", "m_kuntismart", "m_madridapartments", "m_supermarket", "m_coconutcafe", "m_geidishardware", "m_privateresidence1", "m_privateresidence2", "m_privateresidence3", "m_beautysalon", "m_pharmacy", "m_hardwarestore", "m_joksgym", "m_outdoormarket", "m_chelsealofts", "m_pcrepairshop", "m_butchershop", "m_fishmarket", "m_movieworld", "m_georgetownspa"];
  _codes = ["georgetownchurch", "fishdocks", "kuntismart", "madridapartments", "supermarket", "coconutcafe", "geidishardware", "privateresidence1", "privateresidence2", "privateresidence3", "beautysalon", "pharmacy", "hardwarestore", "joksgym", "outdoormarket", "chelsealofts", "pcrepairshop", "butchershop", "fishmarket", "movieworld", "georgetownspa"];
  _names = ["Georgetown Church", "Fish Docks", "Kuntis Mart", "Madrid Apartments", "Foodhaul Supermarket", "Coconet Cafe North", "Geidi's Hardware", "Private Residence", "Private Residence", "Private Residence", "Beauty Salon", "Pharmacy", "Hardware Store", "Jok's Gym", "Outdoor Market", "Chelsea Lofts", "PC Repair Shop", "Butcher Shop", "Fish Market", "Movie World", "Georgetown Spa"];

  //

  ["LocationMarkers", _markers] call dingus_fnc_setVar;
  ["LocationCodes", _codes] call dingus_fnc_setVar;
  ["LocationNames", _names] call dingus_fnc_setVar;

  {
    [_x] call dingus_fnc_createPassengerGroup;
  } forEach _codes;
};

dingus_fnc_initializePassengers = {
  //We need to make sure passengers are available at MOST if not all locations right from the start

  //[passenger1, "fishdocks"] call dingus_fnc_AddPassengerBoardingAction;
  //[passenger2, "georgetownchurch"] call dingus_fnc_AddPassengerBoardingAction;
  //[passenger3, "kuntismart"] call dingus_fnc_AddPassengerBoardingAction;

  //_airportMarkers = ["LocationMarkers", []] call dingus_fnc_getVar;
  //_airportCodes = ["LocationCodes", []] call dingus_fnc_getVar;
  //_airportNames = ["LocationNames", []] call dingus_fnc_getVar;
};


dingus_fnc_PassengersBoarding = {
  params ["_unit", "_code"];

  //Only use 'code' param if it is given and if it is the same as the current airport. Otherwise, current airport takes precedence.
  if (isNil "_code" || _code == "") then {
    //systemChat 'Using current code instead';
    _code = ["CurrentLocation", ""] call dingus_fnc_getVar;
  };

  //systemChat format ['boarding with code: %1', _code];

  _vehicle = ["CurrentVehicle"] call dingus_fnc_getVar;

  if (!isNil {_vehicle}) then {
    ["Boarding", "1"] call dingus_fnc_setVar;

    {
      _x assignAsCargo _vehicle;
    } forEach units group _unit;

    units group _unit orderGetIn true;

    //TODO: This should be deferred and called from a trigger. we need to know how many passengers are expected and then when the count reaches that level trigger it

    //Signal that loading is complete
    [_code] call dingus_fnc_OnPassengersLoaded;

    ["CurrentPassenger", _unit] call dingus_fnc_setVar;

    //Safety check - if you just picked up the same passenger again, make sure we don't delete them when we leave the airport
    if ([format ["LastPassenger%1", _code], nil] call dingus_fnc_getVar == _unit) then {
      //systemChat "Clearing previous passenger";
      [format ["LastPassenger%1", _code], nil] call dingus_fnc_setVar;
    } else {
      //systemChat "Previous passenger safe to delete.";
    };
  };
};

//TODO: We should actually call this from a trigger
dingus_fnc_OnPassengersLoaded = {
  params ["_currentCode"];
  
  _airportMarkers = ["LocationMarkers", []] call dingus_fnc_getVar;
  _airportCodes = ["LocationCodes", []] call dingus_fnc_getVar;
  _airportNames = ["LocationNames", []] call dingus_fnc_getVar;

  _found = false;
  _name = "";
  _marker = "";
  _loc = [0,0,0];
  _count = 0;
  _code = "";

  //Prevent destination from being the same as the current airport
  while { !_found && _count < 100 } do {
    _idx = floor random count _airportMarkers;
    _marker = _airportMarkers select _idx;
    _name = _airportNames select _idx;
    _code = _airportCodes select _idx;
    _loc = getMarkerPos _marker;
    
    //Validate that the code isn't the same as the currently selected or supplied airport code
    //systemChat format ["Does %1 == %2", _code, _currentCode];
    if (_code != _currentCode) then {
      //Found a unique one
      _found = true;
    };
    _count = _count + 1;
  };

  //Clear the 'boarding' flag and stuff
  ["Boarding", "0"] call dingus_fnc_setVar;
  ["Boarded", "1"] call dingus_fnc_setVar;
  ["DestinationLocation", _code] call dingus_fnc_setVar;
  [format ["NextPassenger%1", _currentCode], nil] call dingus_fnc_setVar;

  //Get a new task index
  _tasks = [player] call BIS_fnc_tasksUnit;
  _taskIndex = 0;
  if (count _tasks > 0) then {
    _taskIndex = ((count _tasks) + 1);
  };
  _taskName = format ["task%1", _taskIndex];
  _taskTitle = "Arrive at " + _name;
  _taskDescription = "Transport your passengers to " + _name + ".";

  _markerForTask = _marker;

  //If markers are turned off, then don't use a marker
  if (["TaskLocations", "1"] call dingus_fnc_getVar == "0") then {
    _markerForTask = [];
  };

  //taskCreate - Other style
  //0: BOOL or OBJECT or GROUP or SIDE or ARRAY - Task owner(s)
  //1: STRING or ARRAY - Task name or array in the format [task name, parent task name]
  //2: ARRAY or STRING - Task description in the format ["description", "title", "marker"] or CfgTaskDescriptions class
  //3: OBJECT or ARRAY or STRING - Task destination
  //4: BOOL or NUMBER or STRING - Task state (or true to set as current)
  //5: NUMBER - Task priority (when automatically selecting a new current task, higher priority is selected first)
  //6: BOOL - Show notification (default: true)
  //7: STRING - Task type as defined in the CfgTaskTypes
  //8: BOOL - Should the task being shared (default: false), if set to true, the assigned players are being counted
  [
    player,
    _taskName,
    [_taskDescription, _taskTitle, "x"],
    _markerForTask,
    true,
    1,
    true,
    "move",
    false
  ] call BIS_fnc_taskCreate;
};

dingus_fnc_DepartedLocation = {
  params ["_code"];

  //When we leave a location, we clear the name and other vitals
  ["CurrentLocation", ""] call dingus_fnc_setVar;
  //["CurrentFuelTruck", nil] call dingus_fnc_setVar;
  //["CurrentRepairTruck", nil] call dingus_fnc_setVar;

  //Re-spawn the passenger group for this location
  _existing = [format ["NextPassenger%1", _code], nil] call dingus_fnc_getVar;
  if (isNil "_existing") then {
    //systemChat 'boo';
    [_code] call  dingus_fnc_createPassengerGroup;;
  } else {
    //systemChat 'foo';
  };

  //Delete previous passenger
  _previous = [format ["LastPassenger%1", _code], nil] call dingus_fnc_getVar;
  if (!isNil "_previous" && (vehicle _previous == _previous)) then {
    //systemChat 'deleting last passengers';
    _grp = group _previous;
    { deleteVehicle _x; } forEach units _grp;
    deleteGroup _grp;
    [format ["LastPassenger%1", _code], nil] call dingus_fnc_setVar;
  } else {
    //systemChat 'No units to delete';
  };
};

dingus_fnc_ArrivedAtLocation = {
  params ["_code"];
  
  ["CurrentLocation", _code] call dingus_fnc_setVar;

  //When we land at an airport
  //TODO: Make sure we're at the correct airport and they are still alive!
  _destinationAirport = ["DestinationLocation", ""] call dingus_fnc_getVar;
  _passenger = (["CurrentPassenger"] call dingus_fnc_getVar);
  _hasPassenger = (!isNil "_passenger");
  systemChat format ['Passenger: %1', _hasPassenger];
  if (_code == _destinationAirport && _hasPassenger) then {
    [] call dingus_fnc_PassengersArrived;
  };
};

dingus_fnc_PassengersArrived = {
  ["Arrived", "1"] call dingus_fnc_setVar;

  //At some point we should set the task as complete
  //_currentTask = ["CurrentTask", ""] call dingus_fnc_getVar;
  _allTasks = [player] call BIS_fnc_tasksUnit;
  _currentTask = _allTasks select (count _allTasks - 1);
  [_currentTask, "SUCCEEDED", true] call BIS_fnc_taskSetState;
};

dingus_fnc_PassengersUnloading = {
  ["Boarded", "0"] call dingus_fnc_setVar;
  ["Boarding", "0"] call dingus_fnc_setVar;
  ["Arrived", "0"] call dingus_fnc_setVar;

  //TODO: get the passengers(s) in a better way
  _passenger = ["CurrentPassenger"] call dingus_fnc_getVar;

  if (!isNil {_passenger}) then {
    //Flight's over. Get out. Then...Send them away to a grave or something?
    (group _passenger) leaveVehicle (vehicle _passenger);

    //Send them to a known marker at the current airport
    _code = ["CurrentLocation", ""] call dingus_fnc_getVar;
    _marker = _code + "_arrivals";
    _wp = (group _passenger) addWaypoint [getMarkerPos _marker, 0];

    [format ["LastPassenger%1", _code], _passenger] call dingus_fnc_setVar;
  };

  ["CurrentPassenger", nil] call dingus_fnc_setVar;
  ["Arrived", "0"] call dingus_fnc_setVar;
};

dingus_fnc_createPassengerGroup = {
  params ["_code"];
 
  //systemChat format ["Here with code: %1", _code];

  _models = ["C_Man_casual_1_F_tanoan", "C_man_sport_1_F_afro", "C_Man_casual_1_F_asia", "C_man_1", "C_man_p_beggar_F"];
  _marker = _code + "_pickup";
  //_lookMarker = format ["m_%1", _code];
  //_markerRunway =  "m_airport_" + _code;
  _group = createGroup [civilian, true];

  //Set formation
  //_group setFormation "FILE";
  _group setBehaviour "SAFE";

  //systemChat format ["%1", (getMarkerPos _marker)];

  //Create leader
  _leader = _group createUnit [_models select floor random count _models, (getMarkerPos _marker), [], 0.5, "FORM"];
  //_leader lookAt (markerPos _lookMarker) select 2;
  _leader setFormDir (markerDir _marker);
  _leader setDir (markerDir _marker);
  //_leader disableAI "AUTOCOMBAT";

  //Apply a loadout to this guy
  [_leader] call dingus_fnc_ApplyPassengerLoadout;

  //Spawn a second or third
  _rnd = floor random 100;

  if (_rnd mod 2 == 0) then {
    _two = _group createUnit [_models select floor random count _models, _group, [], 0.5, "NONE"];
    [_two] call dingus_fnc_ApplyPassengerLoadout;
    //_two disableAI "AUTOCOMBAT";
  };

  //Add action to leader
  [_leader, _code] call dingus_fnc_AddPassengerBoardingAction;

  //Save this passenger in vars
  [format ["NextPassenger%1", _code], _leader] call dingus_fnc_setVar;
};

dingus_fnc_ApplyPassengerLoadout = {
  params ["_unit"];

  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  //removeHeadgear _unit;
  //removeGoggles _unit;

  _uniforms = ["U_NikosAgedBody", "U_Marshal", "U_C_Journalist", "U_C_Man_casual_1_F", "U_C_Poloshirt_salmon", "U_IG_Guerilla1_1", "U_IG_Guerilla2_1", "U_IG_Guerilla2_2", "U_IG_Guerilla2_3", "U_IG_Guerilla3_1", "U_IG_Guerilla3_2"];

  //Get random uni
  _uniform = _uniforms select floor random count _uniforms;

  //Uniform
  _unit forceAddUniform _uniform;
  
  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
};

/* Action Helpers */

dingus_fnc_PassengersCanBoard = {
  (vehicle player == player && ((["Boarded", "0"] call dingus_fnc_getVar) == "0"));
};

dingus_fnc_AddPassengerBoardingAction = {
  params ["_leader", "_code"];

  _greetings = ["What up! I'm your driver. Hop in!", "Hello, I'm your driver. Sit anywhere you like!", "Hello there. Do you need a ride? Hop in!", "Where are you headed?"];

  _label = [_greetings select floor random count _greetings] call dingus_fnc_formatActionLabel;

  //We aren't sending over their starting location anymore...does it cause duplicates?
  _leader addAction [_label, {
    [_this select 0, ""] call dingus_fnc_PassengersBoarding;
  }, [], 45, true, true, "", "[] call dingus_fnc_PassengersCanBoard"];
};

dingus_fnc_PassengersCanUnload = {
  _inVehicle = (vehicle player != player);
  _arrived = ((["Arrived", "0"] call dingus_fnc_getVar) == "1");
  _atDestination = ((["CurrentLocation", ""] call dingus_fnc_getVar) == (["DestinationLocation", ""] call dingus_fnc_getVar));
  //TODO: Current passenger check

  _inVehicle && _arrived && _atDestination;
};

dingus_fnc_AddPassengerUnloadAction = {
  params ["_unit"];

  _label = "OK! Here we are. Safe and sound.";
  _label = [_label] call dingus_fnc_formatActionLabel;

  _unit addAction [_label, {
    [] call dingus_fnc_PassengersUnloading;
  }, [], 45, false, true, "", "[] call dingus_fnc_PassengersCanUnload"];
};


