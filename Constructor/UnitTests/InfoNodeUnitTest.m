classdef InfoNodeUnitTest < matlab.unittest.TestCase
	
	methods (Test)
		
		% Confirms the complicated code inside InfoNode.find() is working
		% correctly.
		function findTest(testCase)
			
			infoNodes = InfoNode.empty(1,0);
			infoNodes(1) = Constant('speedOfLight_mps');
			infoNodes(2) = Constant('electronCharge_C');
			infoNodes(3) = Variable('myVar1');
			infoNodes(4) = Wrapper('MyWrapper');
			% omitting Output object
			
			qTypes = {}; qNames = {};
			qTypes{end+1} = Wrapper.type;  qNames{end+1} = 'AnotherWrapper';
			qTypes{end+1} = Constant.type; qNames{end+1} = 'plancksConsant_Js';
			qTypes{end+1} = Output.type;   qNames{end+1} = 'someOutput';
			qTypes{end+1} = Constant.type; qNames{end+1} = 'electronCharge_C';
			qTypes{end+1} = Variable.type; qNames{end+1} = 'myVar2';
			qTypes{end+1} = Variable.type; qNames{end+1} = 'myVar1';
			qTypes{end+1} = Wrapper.type;  qNames{end+1} = 'AYetDifferentWrapper';
			qTypes{end+1} = Variable.type; qNames{end+1} = 'myVar3';
			qTypes{end+1} = Wrapper.type;  qNames{end+1} = 'MyWrapper';
			
			actMatches = infoNodes.find(qTypes,qNames);
			
			expMatches = [
				nan; % no name match
				nan; % no name match
				nan; % no type match
				2;   % matches infoNode(2) exactly
				nan; % no name match
				3;   % matches infoNode(3) exactly
				nan; % no name match
				nan; % no name match
				4;   % matches infoNode(4) exactly
			];
			
			testCase.verifyEqual(actMatches,expMatches);
			
		end
		
	end
	
end