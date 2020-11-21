classdef AlgorithmConstructor < handle
	
	% NOMENCLATURE:
	% A snippet is a small chunk of valid matlab source code.
	% An info node is anything inside a code snippet which stores or
	% generates information
	
	properties (GetAccess = public, SetAccess = private)
		snippets  = CodeSnippet.empty(1,0);
		infoNodes = InfoNode.empty(1,0);
	end
	
	properties (GetAccess = private, SetAccess = private)
		infoNodeClasses = {...
			'Variable',...
			'Wrapper',...
			'Constant',...
			'Output'...
		};
		infoNodeConstructors = {};
		infoNodeTypes = {};
	end
	
	properties (GetAccess = public, Constant)
		% One more \n than necessary so 'abc' and 'xyz' concatenated with
		% this will also be separate lines.
		snippetSeparator = sprintf('\n\n\n');
	end
	
	methods (Access = public)
		
		% Constructor
		function this = AlgorithmConstructor()
			
			% Populate the infoNodeConstructors and infoNodeTypes
			for classInd = 1:numel(this.infoNodeClasses)
				className = this.infoNodeClasses{classInd};
				this.infoNodeConstructors{classInd} = str2func(className);
				this.infoNodeTypes{classInd} = eval([className,'.type']);
			end
			% Confirm the node types are unique
			if numel(this.infoNodeTypes) ~= numel(unique(this.infoNodeTypes))
				error('The InfoNode types are non-unique.');
			end
			
		end
		
		% Adds a snippet from a charvector
		function snippetID = addSnippet(this,snippetSource)
			
			% Generate a code snippet from this source code
			cs = this.generateUserCodeSnippet(snippetSource);
			
			% Formally import the code snippet
			snippetID = this.importCodeSnippets(cs);
			
		end
		
		% Splits up the provided manySnippets by searching for 2
		% consecutive empty lines (whitespace only). Each snippet
		% is effectively passed to addSnippet()
		function snippetIDs = addSnippets(this,manySnippetSources)
			
			minConsecutiveStreak = 2; % Corresponds to snippetSeparator property
			
			% Search for lines to split at.
			% Determine what's on each line, and where those lines start.
			% This necessarily has exactly one match per line.
			[nontrivialLineContent,lineStartInds] = regexp(manySnippetSources,'[ \t]*([^\s]?.*)\n?','tokens','dotexceptnewline');
			% \n? means catch anywhere an newline is, but also don't reject
			% the last line.
			% This is a cell of cells of one char vector. Remove that
			% unnecessary layer of cells
			nontrivialLineContent = cellfun(@(cellchar) cellchar{1}, nontrivialLineContent, 'UniformOutput', false)';
			
			
			% Determine whether each line is empty
			lineIsEmpty = cellfun(@isempty,nontrivialLineContent);
			% Determine the consecutivity of emptiness
			numLines = numel(lineIsEmpty);
			consecutiveEmptyRunning = nan(numLines+1,1); % Line 1 is index 2 here.
			consecutiveEmptyRunning(1) = 0; % This serves as an initial condition for the bottom loop. Prevents the need for several IF blocks.
			consecutiveRunEndLines = nan(0,1);
			for lineInd = 1:numLines
				if lineIsEmpty(lineInd)
					consecutiveEmptyRunning(lineInd+1) = consecutiveEmptyRunning(lineInd+0) + 1; % = Previous + 1
				else % Line is not empty
					consecutiveEmptyRunning(lineInd+1) = 0; % Break consecutive streak
					% If we just ended a sufficiently long streak, record it
					if consecutiveEmptyRunning(lineInd+0) >= minConsecutiveStreak
						consecutiveRunEndLines(end+1,1) = lineInd-1; %#ok<AGROW>
					end
				end
			end
			% There may have been a streak at the very end which is not
			% captured inside consecutiveRunEndLines. This is not an issue
			% because that ending point will be accounted for below using
			% 'lastLine'.
			
			% Trim these results to not include the extra entry at the
			% beginning
			consecutiveEmptyRunning(1) = []; % Now line 1 is index 1
			
			% Create a list of the lines which are the beginning and end of
			% each snippet.
			startLine = find(~lineIsEmpty,1,'first'); % Returns 0 or 1 line number
			lastLine  = find(~lineIsEmpty,1,'last');  % ^ same, but matches. Both 0 or both 1.
			lineBeforeBlanks = consecutiveRunEndLines - consecutiveEmptyRunning(consecutiveRunEndLines);
			lineAfterBlanks = consecutiveRunEndLines+1;
			% Concatenate all of these starts and ends. Reshape them to
			% have all the starts in column 1, and all the ends on column
			% 2. If everything is empty, this should still be fine.
			if numel(lineAfterBlanks)>0 && lineAfterBlanks(1) ~= startLine
				snippetLineStartStops = [[startLine;lineAfterBlanks],[lineBeforeBlanks;lastLine]];
			else
				snippetLineStartStops = [[startLine;lineAfterBlanks(2:end)],[lineBeforeBlanks(2:end);lastLine]];
			end
			
			% Do some bookkeeping on which chars the lines start and end
			% on. line k is all the text between lineBoundaryChars(k) and
			% lineBoundaryChars(k+1)-1
			lineBoundaryChars = [lineStartInds';numel(manySnippetSources)+1];
			
			% Now, loop over these pieces of source code and generate
			% actual code snippet objects
			codeSnippets = CodeSnippet.empty(1,0);
			for rawSnippetInd = 1:size(snippetLineStartStops,1)
				% Extract this snippet
				snippetStartLine = snippetLineStartStops(rawSnippetInd,1);
				snippetEndLine   = snippetLineStartStops(rawSnippetInd,2);
				snippetStartChar = lineBoundaryChars(snippetStartLine);
				snippetEndChar   = lineBoundaryChars(snippetEndLine+1)-1;
				snippetCode = manySnippetSources(snippetStartChar:snippetEndChar);
				if numel(snippetCode) == 0 % Don't add empty snippets
					continue
				end
				
				% Create a code snippet object for this source code
				codeSnippets(1,rawSnippetInd) = this.generateUserCodeSnippet(snippetCode);
				
			end
			
			% Formally add the snippets to the AlgorithmConstructor
			snippetIDs = this.importCodeSnippets(codeSnippets);
			
		end
		
		function doStuff(this)
			
			% Generate a list of output nodes.
			outputNodeInds = this.infoNodes.find(Output.type,'*');
			
			% First, clean out the info nodes which we simply cannot
			% define.
			
			
% 			this.infoNodes(1).defs
% this.snippets(5)
% this.snippets(5).uses
% this.infoNodes(2).defs
% this.snippets(4).uses
			
		end
		
		function assume_conversion(this,conversionObject)
			conversionSnippets = conversionObject.generateConversions();
			this.importCodeSnippets(conversionSnippets);
		end
		
	end
	
	methods (Access = private)
		
		function cs = generateUserCodeSnippet(this,sourceCode)
			
			% Clean up the snippet
			snippetSource = this.tidySnippet(sourceCode);
			
			% Generate the CodeSnippet object, specifically one meant for
			% parsing user inputs
			cs = ParsedSnippet(snippetSource);
			
		end
		
		function snippetIDs = importCodeSnippets(this,codeSnippets)
			
			numCS = numel(codeSnippets);
			
			% Store the code snippets
			this.snippets(1,end+(1:numCS)) = codeSnippets(:)';
			snippetIDs = reshape([codeSnippets.snippetID],1,numCS);
			
			% Extract the info node usage details all at once.
			infoNodeDetailsCell = arrayfun(@(cs) cs.analyze(this.infoNodeTypes), codeSnippets, 'UniformOutput',false);
			numDetails = cellfun(@numel,infoNodeDetailsCell);
			
			% Merge these results into one large list, but keep track of
			% which snippets they came from.
			allInfoNodeDetails = cat(1,infoNodeDetailsCell{:});
			snippetIDsStretched = repelem(snippetIDs,numDetails);
			
			allVarNames = arrayfun(@(detail)[detail.type,'.',detail.name],allInfoNodeDetails,'UniformOutput',false);
			[~,uniqToFirstOrig,origToUniq] = unique(allVarNames);
			
			uniqTypes = {allInfoNodeDetails(uniqToFirstOrig).type};
			uniqNames = {allInfoNodeDetails(uniqToFirstOrig).name};
			
			% Compare with the entries saved in this.infoNodes, and report
			% any matches. The result will be nan if no match to an
			% existing InfoNode is found. Otherwise, it will be an integer
			% which indexes this.infoNodes.
			matchedExistingINs = this.infoNodes.find(uniqTypes,uniqNames);
			
			% Make a new InfoNode for each which does not yet exist.
			numExistingINs = numel(this.infoNodes);
			newINinds = [];
			nextINind = numExistingINs+1;
			newInfoNodes = InfoNode.empty(0,1);
			missingTypeNamePairs = find(isnan(matchedExistingINs))';
			for uncreatedINind = missingTypeNamePairs
				newINinds(end+1) = nextINind; %#ok<AGROW>
				newInfoNodes(end+1) = this.createInfoNode(uniqTypes{uncreatedINind},uniqNames{uncreatedINind}); %#ok<AGROW>
				nextINind = nextINind + 1;
			end
			% Now add these onto the list
			this.infoNodes(newINinds) = newInfoNodes;
			% Update the match results from earlier to include these new
			% entries, as if they had existed before the find() call.
			matchedExistingINs(missingTypeNamePairs) = newINinds;
			
			
			% Now, assign all information described in allInfoNodeDetails
			% to their corresponding InfoNode. snippetIDsStretched
			% specifies the snippet index for each entry of the details.
			% origToUniq captures how the details map to the unique info
			% nodes.
			% Gather all the snippet IDs by the info nodes they define, and
			% again by the info nodes they use.
			isDef = [allInfoNodeDetails.isDef];
			isUse = [allInfoNodeDetails.isUse];
			
			% Create a map from unique info node to the details which
			% reference it.
			detRefUniqINs = accumarray(origToUniq,(1:numel(origToUniq))',[numel(uniqToFirstOrig),1],@(indList){indList});
			% Details referencing unique InfoNodes
			
			% Loop over each unique info node to apply the relevant info
			for uniqINind = 1:numel(matchedExistingINs)
				referencedDetails = detRefUniqINs{uniqINind}; % indexes allInfoNodeDetails
				sourceSnippetIDs = snippetIDsStretched(referencedDetails);
				isDefSubset = isDef(referencedDetails);
				isUseSubset = isUse(referencedDetails);
				
				% Add the defs
				this.infoNodes(matchedExistingINs(uniqINind)).addDef(sourceSnippetIDs(isDefSubset));
				% Add the uses
				this.infoNodes(matchedExistingINs(uniqINind)).addUse(sourceSnippetIDs(isUseSubset));
			end
			
			% Report the usage to each code snippet so they can keep track
			% of that information.
			cumulativeDetailEndInd = cumsum(numDetails);
			for snippetInd = 1:numCS
				% Determine which of the details corresponded to that snippet
				detailInds = cumulativeDetailEndInd(snippetInd) + (1-numDetails(snippetInd):0);
				isDef_ = isDef(detailInds);
				isUse_ = isUse(detailInds);
				infoNodeInds = matchedExistingINs(origToUniq(detailInds));
				codeSnippets(snippetInd).report(...
					unique(infoNodeInds(isDef_)),...
					unique(infoNodeInds(isUse_)))
			end
			
		end
		
		% Creates the appropriate InfoNode from scratch
		function infoNode_ = createInfoNode(this,type_,name_)
			typeInd = strcmp(type_,this.infoNodeTypes); % Exactly one match.
			constructor = this.infoNodeConstructors{typeInd};
			infoNode_ = constructor(name_);
		end
		
		% Removes the indentation for the provided snippet source code
		function snippet = tidySnippet(~,snippet)
			
			% Since tabs can have different widths based on what precedes
			% them, we need to be careful. What we really want is to find a
			% character terminating horizontal position which is common to
			% all lines, and has only space/tab characters to its left on
			% all lines.
			
			% Find all space characters preceding the content of each line.
			% Necessarily finds exactly one result per line.
			[indentCharVecs,lineStartInds] = regexp(snippet,'([ \t]*)[^\s]?.*','tokens','dotexceptnewline');
			% This is a cell of cells of one char vector. Remove that
			% unnecessary layer of cells
			indentCharVecs = cellfun(@(cellchar) cellchar{1}, indentCharVecs, 'UniformOutput', false);
			
			% Will be convenient to have this as a variable...
			tabChar = sprintf('\t');
			
			% Determine the maximum width of a tab character
			try % Try accessing the user's preferences for tabs
				maxTabWidth = com.mathworks.services.Prefs.getIntegerPref('EditorSpacesPerTab');
			catch % Otherwise hard code it
				maxTabWidth = 4;
			end
			
			% Determine the ending position of each character in each of
			% those indent strings.
			indentCharEndings = cell(size(indentCharVecs));
			for indentInd = 1:numel(lineStartInds)
				lastEndingPos = 0;
				indentCharVec = indentCharVecs{indentInd};
				endingCharPos = nan(size(indentCharVec));
				for charInd = 1:numel(indentCharVec)
					switch indentCharVec(charInd)
						case ' '
							endingCharPos(charInd) = lastEndingPos + 1;
						case tabChar
							% Round up the ending position to the next
							% integer multiple of maxTabWidth's
							endingCharPos(charInd) = maxTabWidth * ceil( (lastEndingPos + 1)/maxTabWidth ); % +1, minimum length is 1 char
						otherwise
							% Something went wrong. Throw warning and
							% continue using unmodified snippet.
							warning('AlgorithmConstructor:tidySnippit','Unexpected character in indent character sequence.');
							return
					end
					lastEndingPos = endingCharPos(charInd);
				end
				% Now endingCharPos is fully defined
				indentCharEndings{indentInd} = endingCharPos;
			end
			
			% Find all common ending positions.
			allEndings = unique([indentCharEndings{:}]);
			isCommon = arrayfun(... % Loop over allEndings
				@(uniqEnding) all(...
					cellfun(@(endings) ismember(uniqEnding,endings), indentCharEndings)  ),... % Check each of indentCharEndings for coincidence
				allEndings); % Loop over allEndings
			commonEndings = [0,allEndings(isCommon)]; % All have 0 in common. Never empty vector
			
			% We want the maximum common ending.
			commonEndingPos = max(commonEndings);
			
			% Trim each line to that ending position. Loop through the
			% instances in reverse so the indexing captured in
			% lineStartInds doesn't require extra accounting as we go.
			for indentInd = numel(lineStartInds) : -1 : 1 % reverse
				charsToRemove = find( indentCharEndings{indentInd}==commonEndingPos );
				removeCharInds = lineStartInds(indentInd) + (0:charsToRemove-1);
				snippet(removeCharInds) = []; % Note how this changes the indexing for all characters after this, but not before
			end
			
		end
		
	end
	
end