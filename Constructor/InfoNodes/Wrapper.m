classdef Wrapper < InfoNode
	
	properties (GetAccess = public, Constant)
		type = 'w'; % The type of the node
	end
	
	methods (Access = public)
		
		% Constructor
		function this = Wrapper(wrapperName)
			
			% Call superclass constructor
			this = this@InfoNode(wrapperName);
			
		end
		
	end
	
end