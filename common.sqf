dingus_fnc_Alert = {
  params ["_msg"];
  hint _msg;
};

dingus_fnc_getVar = {
  params ["_key", "_defaultValue"];
  if (!isNil "_defaultValue") then {
    missionNamespace getVariable [_key, _defaultValue];
  } else {
    missionNamespace getVariable _key;
  };
};

dingus_fnc_setVar = {
  params ["_k", "_v"];
  //if (isNil "_k") then { _k = 'nil'; };
  //if (isNil "_v") then { _v = 'nil'; };
  //systemChat format ["Setting key: %1", _k];
  //systemChat format ["Setting value: %1", _v];
  
  if (isNil "_v") then {
    missionNamespace setVariable [_k, nil];
  } else {
    missionNamespace setVariable [_k, _v];
  };
  
};

/*
-------------------------------------------
 Info stand helpers
-------------------------------------------
*/

dingus_fnc_initMapMarkers = {
  //get them all
  {
    if (_x find "marker_" > 0) then {
      //Copy this one
      //Position
      //Type
      //Text

    };

  } forEach allMapMarkers;

  //Then later on, when they 'show' markers we can put them on the map
  //When they hide them, we can hide them

};

dingus_fnc_initInfoStand = {
  params ["_item"];

  _item addAction ["Skip Time: 1 Hour", {[] call dingus_fnc_SkipTime;}, [], 45, false, true, "", ""];
  
  _item addAction ["Weather: Clear", {[] call dingus_fnc_SetClear;}, [], 45, false, true, "", "((rain > 0) || (overcast > 0.10))"];
  _item addAction ["Weather: Cloudy", {[] call dingus_fnc_SetCloudy;}, [], 45, false, true, "", "overcast < 0.5"];
  _item addAction ["Weather: Rainy", {[] call dingus_fnc_SetRainy;}, [], 45, false, true, "", "rain < 0.8"];
};

dingus_fnc_ToggleLocationMarkers = {
  _value = ["TaskLocations", "1"] call dingus_fnc_getVar;
  if (_value == "1") then {
    _value = "0";
  } else {
    _value = "1";
  };
  ["TaskLocations", _value] call dingus_fnc_setVar;
};

dingus_fnc_SkipTime = {
  skipTime 1;
};

dingus_fnc_SetRainy = {
  //We need to skip back a few hours, then skip back forward when we're done making changes
  skipTime -1;
  0 setFog 0;
  0 setOvercast 0.80;
  0 setRain 0.80;
  skipTime 1;
};

dingus_fnc_SetClear = {
  skipTime -24;
  86400 setRain 0;
  86400 setFog 0;
  86400 setOvercast 0.10;
  skipTime 24;
};

dingus_fnc_SetCloudy = {
  skipTime -24;
  86400 setRain 0;
  86400 setFog 0;
  86400 setOvercast 0.55;
  skipTime 24;  
};

dingus_fnc_formatActionLabel = {
  params ["_text"];

  _text = "** " + _text + " **";
  _label = "<t color='#228A37'>" + _text + "</t>";
  _label;
};
