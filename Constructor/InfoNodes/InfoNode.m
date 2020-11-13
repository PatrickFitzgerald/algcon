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
		
		% Returns the subset of InfoNode array 'this' which matches the
		% specified type and name. 
		function sub = find(this,type_,name_)
			
			% Validate the inputs
			if ~( isscalar(type_) && ischar(type_) )
				error('type_ needs to be a single character');
			end
			if ~( isrow(name_) && ischar(name_) ) % huh, who knew that was a function? neat.
				error('name_ needs to be a character vector');
			end
			
			% Extract a list of types and names
			allTypes = cat(1,this.type);
			this = reshape(this,[],1);
			allNames = {this.name};
			
			% Match against the type first
			isTypeMatch = allTypes == type_; % I can check with == safely
			% Reduce 'this' to a subset.
			sub = this(isTypeMatch);
			
			% Further refine the 'sub' subset to match name as well
			isNameMatch = strcmp(allNames(isTypeMatch),name_);
			sub = sub(isNameMatch);
			
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