classdef Constant < InfoNode
	
	properties (GetAccess = public, Constant)
		type = 'c'; % The type of the node
	end
	
	methods (Access = public)
		
		% Constructor
		function this = Constant(constantName)
			
			% Call superclass constructor
			this = this@InfoNode(constantName);
			
		end
		
	end
	
end