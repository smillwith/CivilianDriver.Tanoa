dingus_fnc_spawnAI = {

  //Randomly generated drivers
  _markers = [] call dingus_fnc_getDriverMarkers;
  _maxDrivers = 11;
  _driverIdx = 0;
  while { _driverIdx <= _maxDrivers } do {
    //Create a vehicle, group and leader
    _startingMarker = _markers select floor random count _markers;
    _models = ["C_Man_casual_1_F_tanoan", "C_man_sport_1_F_afro", "C_Man_casual_1_F_asia", "C_man_1"];
    _vehicles = ["C_Offroad_02_unarmed_F", "C_Hatchback_01_F", "C_Offroad_01_F", "C_Hatchback_01_F", "C_Hatchback_01_F", "C_Hatchback_01_sport_F", "B_GEN_Offroad_01_gen_F"];
    _group = createGroup [civilian, true];
    _group setFormation "LINE";
    _group setBehaviour "SAFE";
    _vehicle = (_vehicles select floor random count _vehicles) createVehicle (getMarkerPos _startingMarker);
    _vehicle allowDamage false;
    _leader = _group createUnit [_models select floor random count _models, (getMarkerPos _startingMarker), [], 2, "NONE"];
    _leader assignAsDriver _vehicle;
    
    //Get in, assign way points
    [_leader] orderGetIn true;
    [_leader] call dingus_fnc_addDriverWaypoints;
    
    _driverIdx = _driverIdx + 1;
  };

  //For the existing, fixed drivers
  {
    [_x] call dingus_fnc_addDriverWaypoints;
  } forEach [driver2, driver3, driver4, driver5, driver6, driver7];
};

dingus_fnc_getDriverMarkers = {
  //populate the markers array dynamically
  _midx = 0;
  _mmax = 23;      // <--- Update to use the total number of blank markers for drivers
  _markers = [];

  while {_midx <= _mmax} do {
    _markers pushBack (format ['driver_waypoint_%1', _midx]);
    _midx = _midx + 1;
  };

  _markers;
};

dingus_fnc_addDriverWaypoints = {
  params ["_unit"];

  _markers = [] call dingus_fnc_getDriverMarkers;

  //systemChat format ['creating waypoints for: %1', _unit];

  _count = 2;
  _idx = 0;

  //Capture their starting position
  _startingPos = (getPosATL _unit);

  while { _idx <= _count } do {
    //Get a random marker
    _marker = _markers select floor random count _markers;

    //systemChat format ['marker pos: %1', markerPos _marker];

    //Add the waypoint
    _wp = (group _unit) addWaypoint [getMarkerPos _marker, _idx];
    _wp setWaypointTimeout [1, 10, 45];
    _wp setWaypointSpeed "LIMITED";
    _idx = _idx + 1;
  };

  //Add a cycle waypoint?
  _wpc = (group _unit) addWaypoint [_startingPos, _idx + 1];
  _wpc setWaypointType "CYCLE";
  _wpc setWaypointStatements ["true", "hint 'hello';"];
};
