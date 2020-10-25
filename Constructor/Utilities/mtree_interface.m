classdef mtree_interface < mtree
	
	properties (GetAccess = public, SetAccess = private)
		% A struct with all the lexeme types as fields. The corresponding
		% value is the index of lexemeTypes.
		types; % Auto-populated inside the constructor
		
		% Column descriptors for the 'relations' matrix. The entries here
		% are derived from the comments inside the original mtree file.
		cols = struct(...
			'type',       1,...
			'string',     8,...
			'parent',    13,... % true parent, specifically.
			'leftChild',  2,...
			'rightChild', 3 ...
		);
	end
	
	methods (Access = public)
		
		% Constructor
		function this = mtree_interface(varargin)
			% Primary parent constructor
			this = this@mtree(varargin{:});
			
			% Populate all the types in the 'types' struct
			types_ = struct();
			typeList = this.lexemeTypes;
			for typeInd = 1:numel(typeList)
				% Create the property on 'this'
				types_.(typeList{typeInd}) = typeInd;
			end
			% Save this list to 'this'
			this.types = types_;
		end
		
		% Hack function, the primary way to get the information out of the
		% original mtree object.
		function [info,strings,charLineRefs] = hack(this)
			info = this.T;
			strings = this.C;
			charLineRefs = this.lnos;
		end
		
		function [line,column] = charPosToLineColumn(this,charPos)
			line = find(charPos > this.lineStarts,1,'first');
			column = charPos - this.lineStarts(line);
		end
		function charPos = lineColumnToCharPos(this,line,column)
			charPos = this.lineStarts(line) + column;
		end
		
	end
	
	properties (GetAccess = public, Dependent)
		labels;
		lineStarts;
		lexemeTypes;
		relations;
	end
	
	methods % Getters
		function val = get.labels(this)
			val = this.C;
		end
		function val = get.lineStarts(this)
			val = this.lnos;
		end
		function val = get.lexemeTypes(this)
			val = this.N;
		end
		function val = get.relations(this)
			val = this.T;
		end
	end
	
end