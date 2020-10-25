classdef Variable < InfoNode
	
	properties (GetAccess = public, Constant)
		type = 'v'; % The type of the node
	end
	
	methods (Access = public)
		
		% Constructor
		function this = Variable(variableName)
			
			% Call superclass constructor
			this = this@InfoNode(variableName);
			
		end
		
	end
	
end