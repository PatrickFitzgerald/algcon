classdef Constant < InfoNode
	
	properties (GetAccess = public, Constant)
		type = 'c'; % The type of the node
	end
	
	methods (Access = public)
		
		% Constructor
		function this = Constant(wrapperName)
			
			% Call superclass constructor
			this = this@InfoNode(wrapperName);
			
		end
		
	end
	
end