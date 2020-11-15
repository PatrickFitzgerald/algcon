classdef Output < InfoNode
	
	properties (GetAccess = public, Constant)
		type = 'o'; % The type of the node
	end
	
	methods (Access = public)
		
		% Constructor
		function this = Output(outputName)
			
			% Call superclass constructor
			this = this@InfoNode(outputName);
			
		end
		
	end
	
end