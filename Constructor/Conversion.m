classdef (Abstract) Conversion < handle
% Conversion objects are responsible for generating snippets to perform the
% conversions between variables, so users don't need to.
	
	methods (Access = public)
		
		% Constructor
		function this = Conversion()
			% Nothing to see here
		end
		
	end
	
	methods (Access = protected, Abstract)
		
		% This method generates the conversion snippets given the provided
		% infoNodeName (which includes the type).
		conversionSnippets = generateConversions_(this,infoNodeName);
		
	end
	
	methods (Access = ?AlgorithmConstructor) % Made accessible only to Algorithm Constructor
		function conversionSnippets = generateConversions(this)
			conversionSnippets = this.generateConversions_();
		end
	end
	
end