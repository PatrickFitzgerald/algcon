classdef RawSnippet < CodeSnippet
	
	properties (GetAccess = private, SetAccess = private)
		defs;
		uses;
	end
	
	methods (Access = public)
		
		% Constructor
		% defs,uses should list out the full InfoNode names (type+name) of
		% anything defined and used by the source code.
		function this = RawSnippet(sourceCode,defs,uses)
			
			this = this@CodeSnippet(sourceCode);
			
			this.defs = defs;
			this.uses = uses;
			
		end
		
		function infoNodeDetails = analyze(this,validInfoNodeTypes)
			
			if numel(this) > 1
				error('Do not call analyze() on more than one CodeSnippet at a time.');
			end
			
			% Condense the list of defs and uses into one list (unique)
			numDefs = numel(this.defs);
			numUses = numel(this.uses);
			[allINnames,~,oldToNewMap] = unique([this.defs(:),this.uses(:)]); % All defs, then all uses
			% allINnames = all InfoNode names. Entries are unique
			numINnames = numel(allINnames);
			% Merge the information on which lists the condensed names came
			% from.
			isDef = false(numINnames,1);
			isUse = false(numINnames,1);
			isDef( oldToNewMap(   0    + (1:numDefs)) ) = true;
			isUse( oldToNewMap(numDefs + (1:numUses)) ) = true;
			
			% Compare these names to the valid InfoNode types
			[wasMatch,type,name] = InfoNode.match(allINnames,validInfoNodeTypes);
			% If any did not match, throw any error.
			if any(~wasMatch)
				unmatchedNames = allINnames(~wasMatch);
				num = sum(~wasMatch);
				errText = sprintf(repmat('"%s", ',1,num),unmatchedNames{:});
				error('The following variable%s invalid: %s',[repmat('s are',1,num~=1),repmat(' is',1,num==1)],errText(1:end-2));
			end
			% If still running, use the type and name.
			
			% Make a list of the outputs
			infoNodeDetails = struct(...
				'type', type,...
				'name', name,...
				'isDef',num2cell(isDef(:)),...
				'isUse',num2cell(isUse(:)));
			
		end
		
	end
	
end