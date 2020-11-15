classdef InfoNode < handle & matlab.mixin.Heterogeneous % handle class which can have unlike subclasses be concatenated
% INFONODE is designed to be a node of information, i.e. a source and/or
% destination of information.
	
	properties (GetAccess = public, SetAccess = private)
		name = '';       % The user-provided name of this node
		defs = nan(1,0); % A list of all the snippet IDs that define this node
		uses = nan(1,0); % A list of all the snippet IDs that use this node
	end
	
	properties (GetAccess = public, Constant, Abstract)
		type; % The type of the node
	end
	
	% name is case sensitive
	% type is case insensitive
	
	methods (Access = public, Sealed)
		
		% Constructor
		function this = InfoNode(fieldName)
			% Store the field name
			this.name = fieldName;
		end
		
		% Declare a snippet as being a possible definition of this node.
		function addDef(this,snippedID)
			for ind = 1:numel(this)
				this(ind).defs = unique([this(ind).defs,snippedID]);
			end
		end
		
		% Declare a snippet as being a possible use of this node.
		function addUse(this,snippedID)
			for ind = 1:numel(this)
				this(ind).uses = unique([this(ind).uses,snippedID]);
			end
		end
		
		% 
		function tIndFound = find(this,qTypes,qNames)
			
			% Support simpler input
			if ischar(qTypes) && ischar(qNames)
				qTypes = {qTypes};
				qNames = {qNames};
			elseif ~(~ischar(qTypes) && ~ischar(qNames))
				error('Charvector inputs or cell array of charvector inputs are required.')
			elseif numel(qTypes) ~= numel(qNames)
				error('Types and names must come in pairs.');
			end
			
			% Reshape for ease of processing below.
			qTypes = qTypes(:);
			qNames = qNames(:);
			
			% Extract a list of types and names
			tTypes = reshape({this.type},1,[]); % pre-script "t" is for "this"
			tNames = reshape({this.name},1,[]);
			
			% Reduce to unique representation
			[tTypesUniq,~,tOrigToUniq] = unique(tTypes);
			[qTypesUniq,~,qOrigToUniq] = unique(qTypes);
			% Create a way to map an index in the respective unique entry
			% to the set of indices which matched that unique entry.
			tMapToInds = accumarray(tOrigToUniq,(1:numel(tOrigToUniq))',[numel(tTypesUniq),1],@(indList){indList});
			qMapToInds = accumarray(qOrigToUniq,(1:numel(qOrigToUniq))',[numel(qTypesUniq),1],@(indList){indList});
			
			% Compare the unique sets to find matches.
			typeMatchesCell = cellfun(@(qType)strcmp(qType,tTypesUniq),qTypesUniq,'UniformOutput',false);
			typeMatches = cat(1,typeMatchesCell{:}); % qUniq x tUniq
			% Find pairs of which of the unique type entries match up to
			% each other between the q and t sets.
			[qMatch,tMatch] = find(typeMatches);
			
			
			% Preallocate output. qInds below indexes this, and will insert
			% corresponding tInds values.
			tIndFound = nan(size(qTypes));
			% Loop over each match pair. Here, we'll compare everything
			% that had a common type.
			for typeMatchInd = 1:numel(qMatch)
				
				% Look up the indices of the q and t sets that we'll be
				% comparing
				tInds = tMapToInds{tMatch(typeMatchInd)};
				qInds = qMapToInds{qMatch(typeMatchInd)};
				
				% Use unique to match these all at once. We will
				% concatenate the relevant names and use unique to tell us
				% the first instance of each unique entry. By placing the
				% relevant tInds first, if a match exists inside tNames,
				% then this will get priority. 'stable' ensures the tNames
				% don't get reordered.
				[~,~,firstNameMatch] = unique([tNames(tInds)';qNames(qInds)],'stable');
				tIndsCount = numel(tInds);
				% Discard trivial results, where tNames were compared to
				% tNames.
				firstNameMatch(1:tIndsCount) = [];
				% firstNameMatch indexes tInds.
				
				% Test whether the matches found were inside the tNames set
				wasMatched = firstNameMatch <= tIndsCount; % indexes qInds
				
				% Store the result.
				tIndFound(qInds(wasMatched)) = tInds(firstNameMatch(wasMatched));
				
			end
			
		end
		
	end
	
	methods (Access = public, Sealed, Static)
		
		% This method searches through a list of fullNames, and finds any
		% of those which match the expected form with on any of the
		% supported nodeTypes. wasMatch will be true if it matched an
		% expected form, and type,name will be the corresponding split
		% InfoNode type and name that such a fullName would correspond to.
		function [wasMatch,type,name] = match(fullNames,nodeTypes)
			
			% Sanitize inputs
			if ~iscell(fullNames)
				fullNames = {fullName};
			end
			fullNames = fullNames(:);
			nodeTypes = nodeTypes(:)';
			
			% Find anything of the form TYPE.OTHERTEXT
			form = ['^([',sprintf(repmat('(?:%s)',1,numel(nodeTypes)),nodeTypes{:}),'])\.([^\s\$\#]*)'];
			matchInfo = regexp(fullNames,form,'tokens');
			
			% Format the outputs
			wasMatch = cellfun(@(mI)numel(mI)~=0,matchInfo);
			type = cell(size(wasMatch));
			name = cell(size(wasMatch));
			type(wasMatch) = cellfun(@(mI)mI{1}{1},matchInfo(wasMatch),'UniformOutput',false);
			name(wasMatch) = cellfun(@(mI)mI{1}{2},matchInfo(wasMatch),'UniformOutput',false);
			
		end
		
	end
	
end