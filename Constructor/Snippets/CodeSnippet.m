classdef (Abstract) CodeSnippet < handle & matlab.mixin.Heterogeneous % The concatenation methods here are helpful, less so the heterogeneous part
	
	properties (GetAccess = public, SetAccess = private)
		sourceCode;
		snippetID;
		
		defs = nan(1,0); % A list of all the InfoNode IDs that this snippet defines
		uses = nan(1,0); % A list of all the InfoNode IDs that this snippet uses
	end
	
	methods (Access = public)
		
		% Constructor
		function this = CodeSnippet(sourceCode)
			
			this.sourceCode = sourceCode;
			this.snippetID  = CodeSnippet.getNewID();
			
		end
		
		% Populates the defs, uses properties
		function report(this,defs,uses)
			this.defs = defs(:)';
			this.uses = uses(:)';
		end
		
	end
	
	methods (Access = public, Abstract)
		
		% A method for the algorithm constructor to call to understand what
		% this snippet requires for use, and what it offers to define.
		infoNodeDetails = analyze(this,validInfoNodeTypes);
		% The first chunk of code below is recommended to run before
		% executing any code. The second chunk is the form of the output.
		% It should be a struct, with an entry for each InfoNode entry
		% present in this snippet.
		% 	if numel(this) > 1
		% 		error('Do not call analyze() on more than one CodeSnippet at a time.');
		% 	end
		%	
		%	...
		%	
		% 	% Make a list of the outputs
		% 	infoNodeDetails = struct(...
		% 		'type', ____,...
		% 		'name', ____,...
		% 		'isDef',____,...
		% 		'isUse',____);
		
	end
	
	methods (Access = private, Static)
		
		% This method maintains a unique set of IDs for the current matlab
		% session.
		function newID = getNewID()
			persistent lastID
			if isempty(lastID)
				lastID = 0;
			end
			
			newID = lastID + 1;
			lastID = newID;
		end
		
	end
	
end