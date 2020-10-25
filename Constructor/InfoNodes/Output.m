classdef Output < InfoNode
	
	properties (GetAccess = public, Constant)
		type = 'o'; % The type of the node
	end
	
	methods (Access = public)
		
		% Constructor
		function this = Output(wrapperName)
			
			% Call superclass constructor
			this = this@InfoNode(wrapperName);
			
		end
		
	end
	
end