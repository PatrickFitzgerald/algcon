classdef (Abstract) MultiplicativeConversion < Conversion
% This manages the conversions between units which have a common zero
% point, but differ on scale.
	
	properties (GetAccess = public, Constant, Abstract)
		units;  % A cell array containing cell arrays of equivalent unit
		% names. Put the most verbose labels of each variable at the end of
		% each list, so it may be used in the documentation.
		equivalences; % The multiplicative relationships between different units.
		% The columns here represent x, X, y, and Y in the equation
		%    x X = y Y
		% These equivalences don't need to be pairwise exhaustive, just
		% list out the conversions that one would find worth remembering,
		% whose combination can cover all possible conversions between the
		% supported units.
		% 
		% Here's an example:
		% units = {...
		% 	  {'ms','millisec','millisecond','milliseconds'},...
		% 	  {'s','sec','second','seconds'},...
		% 	  {'m','min','mins','minute','minutes'},...
		% 	  {'h','hr','hour','hours'},...
		% };
		% equivalences = {...
		% 	  1000, 'milliseconds', 1, 'seconds';...
		% 	  1,    'minute',      60, 'seconds';...
		% 	  1,    'hour',        60, 'minutes';...
		% };
		description; % A description for this type of unit and associated conversions
	end
	properties (GetAccess = protected, SetAccess = private)
		flattenedUnits;
		conversionsUsed;
		conversionDirs;
		representativeLabels;
		numberForm = '%.12g';
	end
	properties (GetAccess = public, SetAccess = protected)
		infoNodeType = '';
		infoNodeName = '';
	end
	
	methods (Access = public)
		
		% Constructor
		function this = MultiplicativeConversion(infoNodeNameFull)
			
			% Create a tidied list of units
			tidiedUnits = cellfun(@(group) {group(:)'},this.units); % Make all entries row vectors of strings
			% Make an equivalent list which is not grouped
			this.flattenedUnits = cat(2,tidiedUnits{:});
			
			% Confirm the units are all unique
			if numel(unique(this.flattenedUnits)) ~= numel(this.flattenedUnits)
				error('Units must be unique, error in %s definition',class(this));
			end
			
			
			% Do some work on determining the interdependence of these
			% variables
			numDistinctUnits = numel(this.units);
			% Make a map object to map from unit labels to their distinct
			% unit index
			labelToUnitMap = containers.Map(this.flattenedUnits,repelem(1:numDistinctUnits,cellfun(@numel,this.units)));
			% Use this map to see what units the left and right sides of
			% the equivalences call out.
			allEquivUnitMappings = cellfun(@(depUnitLabel) labelToUnitMap(depUnitLabel),this.equivalences(:,[2,4]));
			% Double check that the equivalences are unique
			temp = unique(allEquivUnitMappings,'rows');
			if ~(size(allEquivUnitMappings) == size(temp)) % Shouldn't be any duplicate 
				error('There are conflicting equivalences defined. You only need to relate unit X and Y (at most) once.');
			end
			
			% Determine the path between each unit, using the equivalences
			% as edges in a graph connecting the units (nodes)
			conversionsUsed = cell(numDistinctUnits);
			conversionDirs  = cell(numDistinctUnits);
			for startUnitInd = 1:numDistinctUnits
				[~,paths,conversionsUsed(startUnitInd,:)] = dijkstra((1:numDistinctUnits)',[(1:numDistinctUnits)',allEquivUnitMappings],startUnitInd);
				conversionDirs(startUnitInd,:) = cellfun(@(p,s) p(1:end-1)==cellfun(@(unitLabel)labelToUnitMap(unitLabel),this.equivalences(s,2)'), paths,conversionsUsed(startUnitInd,:), 'UniformOutput',false);
				% true if starting unit ind is the same as the left hand
				% side unit of the equivalence
			end
			this.conversionsUsed = conversionsUsed;
			this.conversionDirs  = conversionDirs;
			
			
			% Another last bit of bookkeeping, useful elsewhere.
			this.representativeLabels = cellfun(@(u) u{end}, this.units,'UniformOutput',false);
			
			
			% Extract the units of the provided infoNode
			lastUnderscore = find(infoNodeNameFull=='_',1,'last'); % Exactly zero or one result
			preferredUnits = infoNodeNameFull(lastUnderscore+1:end); % Can be empty if no underscore found
			% Confirm not empty, and membership in supported units
			if isempty(preferredUnits)
				error('The provided info node name "%s" does not have any units (name_UNITS).',infoNodeNameFull);
			end
			if ~ismember(preferredUnits,this.flattenedUnits)
				error('Found "%s" as the units of info node "%s", but these units are unsupported.',preferredUnits,infoNodeNameFull);
			end
			
			% Now try to extract off the type of the info node, and the
			% reduced name of the variable.
			firstDot = find(infoNodeNameFull=='.',1,'first'); % Exactly zero or one result
			this.infoNodeType = infoNodeNameFull(1:firstDot-1); % Could be empty
			this.infoNodeName = infoNodeNameFull(firstDot+1:lastUnderscore-1);
			if isempty(this.infoNodeName) || numel(regexp(this.infoNodeName,'\w'))==0 % Require the nodeName is not empty, and contains at least one alphanumeric character
				error('The proper info node name "%s" extracted from "%s" is invalid.',this.infoNodeName,infoNodeNameFull);
			end
			% Okay, that should do it for error checking
			
		end
		
	end
	
	methods (Access = protected)
		
		% This method generates the conversion snippets given the provided
		% infoNodeName (which includes the type).
		function conversionSnippets = generateConversions_(this)
			
			% Now to construct the snippets
			preamble = sprintf('%% This snippet was auto-generated by %s.',class(this));
			variableNameNoUnits = [this.infoNodeType,'.',this.infoNodeName,'_'];
			numDistinctUnits = numel(this.units);
			conversionSnippets = CodeSnippet.empty(0,1);
			for startUnitInd = 1:numDistinctUnits
				for stopUnitInd = 1:numDistinctUnits
					
					% Extract the conversion between these units, and the
					% direction of the conversion for each equivalence.
					eqsUsed = this.conversionsUsed{startUnitInd,stopUnitInd};
					convDir = this.conversionDirs{startUnitInd,stopUnitInd};
					
					if numel(eqsUsed) == 0
						% <preamble>
						% This is a trivial conversion, really just a relabeling  
						% ..._Y = ..._X;
						statement = '% This is a trivial conversion, really just a relabeling.';
						scaleFactor = '';
						comment = '';
					else % Nontrivial scale factors to account for
						% <preamble>
						% The conversion from X to Z is derived from the following equivalences: 
						%     x X = y Y
						%     y Y = z Z
						% ..._Z = num * ..._X; % num [Z/X] = (z/y) * (y/x)
						statement = sprintf('%% The conversion from %s to %s is derived\n%% from the following equivalences:\n',...
							this.representativeLabels{startUnitInd},...
							this.representativeLabels{stopUnitInd});
						
						comment = '\n %%%% %s [%%s/%%s] = ';
						numberFactor = 1.0;
						for eqInd = 1:numel(eqsUsed) % loop over equivalences used
							numberX = this.equivalences{eqsUsed(eqInd),1};
							numberY = this.equivalences{eqsUsed(eqInd),3};
							stringX = sprintf(this.numberForm,numberX);
							stringY = sprintf(this.numberForm,numberY);
							
							statement = [statement,sprintf('%%    %s %s = %s %s\n',...
								stringX,...
								this.equivalences{eqsUsed(eqInd),2},... % the units corresponding to that equivalence
								stringY,...
								this.equivalences{eqsUsed(eqInd),4})]; %#ok<AGROW>
							
							% convDir is true when the starting unit is the
							% left hand side unit (X) in the equivalence
							% used.
							if convDir(eqInd)
								% Y = (x/y) X
								numberFactor = numberFactor * numberX / numberY;
								numerator   = stringX;
								denominator = stringY;
							else
								% X = (y/x) Y
								numberFactor = numberFactor * numberY / numberX;
								numerator   = stringY;
								denominator = stringX;
							end
							comment = [comment,sprintf('(%s/%s) * ',numerator,denominator)]; %#ok<AGROW>
							
						end
						statement = statement(1:end-1); % trim off trailing newline.
						comment = comment(1:end-3); % Trim off trailing ' * '
						
						stringFactor = sprintf('%.14g',numberFactor);
						comment = sprintf(comment,stringFactor);
						
						scaleFactor = [stringFactor,' * '];
						
					end
					
					for startUnitLabelInd = 1:numel(this.units{startUnitInd})
						for stopUnitLabelInd = 1:numel(this.units{stopUnitInd})
							
							% Don't generate conversions for identical labels 
							if (startUnitInd == stopUnitInd) && (startUnitLabelInd == stopUnitLabelInd)
								continue
							end % Otherwise, continue
							
							% Extract the units
							startUnitsLabel = this.units{startUnitInd}{startUnitLabelInd};
							stopUnitsLabel  = this.units{stopUnitInd }{stopUnitLabelInd };
							
							startVariable = [variableNameNoUnits,startUnitsLabel];
							stopVariable  = [variableNameNoUnits,stopUnitsLabel ];
							
							% Finalize the source code for this snippet
							sourceCode = sprintf('%s\n%s\n%s = %s%s;%s',preamble,statement,stopVariable,scaleFactor,startVariable,sprintf(comment,stopUnitsLabel,startUnitsLabel));
							
							% Create a formal code snippet to contain this.
							% The variables it defines is simply the
							% stopVariable, and the variables uses is
							% simply the startVariable.
							conversionSnippets(end+1,1) = RawSnippet(sourceCode,{stopVariable},{startVariable}); %#ok<AGROW>
							
						end
					end
					
					
					
					
					
% 					% Extract numerical scale factors.
% 					startScale = this.flattenedScales(startUnitInd);
% 					stopScale  = this.flattenedScales(stopUnitInd);
% 					
% 					
% 					
% 					if startScale == stopScale % Name conversion
% 						scaleFactor = ''; % no scale factor
% 						comment = ' % Conversion in variable name only';
% 					else % Numerical and name conversion
% 						scaleFactor = sprintf('%g / %g * ',stopScale,startScale); % numerical conversion
% 						comment = sprintf(' %% %g %s = %g %s',startScale,startUnits,stopScale,stopUnits);
% 					end
% 					snippet = [preamble,sprintf('\n%s = %s%s;%s',stopVariable,scaleFactor,startVariable,comment)];
					
					
				end
			end
			
		end
		
	end
	
end