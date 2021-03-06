classdef DURATION < MultiplicativeConversion
% Implements just about any unit of time that's reasonable to use.
	
	properties (GetAccess = public, Constant)
		units = {...
			{'as','attosec','attosecond','attoseconds'},...
			{'fs','femtosec','femtosecond','femtoseconds'},...
			{'ps','picosec','picosecond','picoseconds'},...
			{'ns','nanosec','nanosecond','nanoseconds'},...
			{'mus','microsec','microsecond','microseconds'},...
			{'ms','millisec','millisecond','milliseconds'},...
			...
			{'s','sec','second','seconds'},...
			...
			{'min','mins','minute','minutes'},...
			{'h','hr','hour','hours'},...
			{'d','day','days'},...
			{'w','week','weeks'},...
			{'fortnight','fortnights'},... % why not :)
			{'month','months'},... % exactly 30 days
			{'y','year','years'},... % exactly 365 days
			{'dec','decade','decades'},...
			{'cent','century','centuries'},...
			{'millenium','millenia'}... % This should be enough...
		};
		equivalences = {...
			1e18, 'attoseconds',    1, 'second' ;...
			1e15, 'femtoseconds',   1, 'second' ;...
			1e12, 'picoseconds',    1, 'second' ;...
			1e9,  'nanoseconds',    1, 'second' ;...
			1e6,  'microseconds',   1, 'second' ;...
			1e3,  'milliseconds',   1, 'second' ;...
			1,    'minute',        60, 'seconds';...
			1,    'hour',          60, 'minutes';...
			1,    'hour',        3600, 'seconds';... % Redundant, but memorable
			1,    'day',           24, 'hours'  ;...
			1,    'week',           7, 'days'   ;...
			1,    'fortnight',      2, 'weeks'  ;...
			1,    'month',         30, 'days'   ;...
			1,    'year',         365, 'days'   ;...
			1,    'decade',        10, 'years'  ;...
			1,    'century'       100, 'years'  ;...
			1,    'millenium',   1000, 'years'  ;...
		};
		description = 'BasicUnits.DURATION is any temporal variable measuring a duration of time, not an absolute time.';
	end
	
	methods (Access = public)
		% Constructor
		function this = DURATION(varargin)
			this = this@MultiplicativeConversion(varargin{:});
		end
	end
	
end