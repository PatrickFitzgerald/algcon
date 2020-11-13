classdef ParsedSnippet < CodeSnippet
	
	properties (GetAccess = private, SetAccess = private)
		lexer;
	end
	
	methods (Access = public)
		
		% Constructor
		function this = ParsedSnippet(sourceCode)
			
			this = this@CodeSnippet(sourceCode);
			this.lexify();
			
		end
		
		function infoNodeDetails = analyze(this,validInfoNodeTypes)
			
			if numel(this) > 1
				error('Do not call analyze() on more than one CodeSnippet at a time.');
			end
			
			% Find all DOT lexemes
			rows_DOT = find(this.lexer.relations(:,this.lexer.cols.type) == this.lexer.types.DOT); % 'rows' here refers to the row of this.lexer.relations
			% Reduce these to those which have an immediate left child which is an ID
				if any(this.lexer.relations(rows_DOT,this.lexer.cols.leftChild)==0), warning('DOT can apparently not have a left child'), end
			rows_DOT = rows_DOT( this.lexer.relations(rows_DOT,this.lexer.cols.leftChild) ~= 0 ); % Require it has a child
			rows_DOTleftChild = this.lexer.relations(rows_DOT,this.lexer.cols.leftChild);
			keep = this.lexer.relations(rows_DOTleftChild,this.lexer.cols.type) == this.lexer.types.ID; % Keep only those whose left child is an ID
			rows_DOT = rows_DOT(keep);
			rows_DOTleftChild = rows_DOTleftChild(keep);
			% Now check the string associated with that ID. Require that it matches one
			% of the validInfoNodeTypes.
				if any(this.lexer.relations(rows_DOTleftChild,this.lexer.cols.string)==0), error('DOT ID can apparently not have a string'), end
			referencedStringInds = this.lexer.relations(rows_DOTleftChild,this.lexer.cols.string);
			referencedStrings = this.lexer.labels(referencedStringInds);
			% Refine search to only DOT expressions which are one of the supported info
			% node types.
			isValidDOT = cellfun(@(s) ischar(s) && ismember(s,validInfoNodeTypes),referencedStrings);
			rows_DOT = rows_DOT(isValidDOT);
			infoNodeType = referencedStrings(isValidDOT);
			
			
			row_rows_DOT = 1:numel(rows_DOT); % A list of which rows of 'rows_DOT' that 'rows_ancestor' refers to.
			rows_ancestor = rows_DOT; % 'rows' here again refers to the row of this.lexer.relations
			
			isDOTdefinition = nan(numel(rows_DOT),1); % 0 false, 1 true, nan undetermined. Not an actual boolean.
			
			% Iteratively move up the tree from the DOT items until we find that it
			% stems from the left child of an EQUALS lexeme (DOT was a definition /
			% assignment) or, failing that, we run out of lexed tree (DOT was
			% non-definitional, and is treated as a simple 'use').
			while ~isempty(row_rows_DOT)
				
				% (1) Lookup the parents of the most recent ancestor investigated.
				rows_ancestor_last = rows_ancestor; % Save this for comparison in step (3)
				rows_ancestor = this.lexer.relations(rows_ancestor,this.lexer.cols.parent);
				
				% (2) Downselect to what is not the top of a tree
				keepPursuing = rows_ancestor ~= 0; % 0 when at the top of the tree
				% Save these entries as non-definitions
				isDOTdefinition(row_rows_DOT(~keepPursuing)) = 0;
				% Do the actual downselect
				row_rows_DOT  = row_rows_DOT( keepPursuing);
				rows_ancestor = rows_ancestor(keepPursuing);
				
				% (3) On everything remaining, test whether we've found an EQUALS lexeme.
				ancestorIsEQUALS = this.lexer.relations(rows_ancestor,this.lexer.cols.type) == this.lexer.types.EQUALS;
				% If we we came from a left child of this EQUALS, then mark this item
				% as a definition.
				isLeftChild = this.lexer.relations( rows_ancestor(ancestorIsEQUALS), this.lexer.cols.leftChild ) == rows_ancestor_last(ancestorIsEQUALS);
				% ^ Indexes all true entries of ancestorIsEquals. Combine results now:
				isDefinition = ancestorIsEQUALS;
				isDefinition(ancestorIsEQUALS) = isLeftChild;
				% Save these as definitions
				isDOTdefinition(row_rows_DOT(isDefinition)) = 1;
				
				% (4) Perform the final downselect for this iteration
				row_rows_DOT  = row_rows_DOT( ~isDefinition);
				rows_ancestor = rows_ancestor(~isDefinition);
				
			end
			
			if any(isnan(isDOTdefinition)), error('some DOT instances were not determined'), end
			
			isDOTdefinition = logical(isDOTdefinition);
			
			
			% Determine the node names
			% Note that v.aaa.b and v.aaa.c have no relation, they are
			% separate nodes. They are only both inside v.aaa for user
			% organization purposes
			
				if any(  this.lexer.relations( this.lexer.relations( this.lexer.relations(:,this.lexer.cols.type) == this.lexer.types.DOT, this.lexer.cols.rightChild),  this.lexer.cols.type) ~= this.lexer.types.FIELD   ), error('DOTs can have a non-FIELD right child'), end
				if any(  this.lexer.relations( this.lexer.relations(:,this.lexer.cols.type) == this.lexer.types.FIELD, this.lexer.cols.string) == 0  ), error('FIELDs can apparently not have associated strings'), end
			
			% From the tip of our DOT tree, the left child was determined to be one
			% of the validInfoNodeTypes. Now, the right child is the start of the node
			% name. That right child will necessarily be a FIELD.
			rows_rightChild = this.lexer.relations(rows_DOT,this.lexer.cols.rightChild);
			nodeName = this.lexer.labels(this.lexer.relations(rows_rightChild,this.lexer.cols.string));
			% Allow node names to be the repeated DOTs, so we need to ascend the tree,
			% adding the right child FIELD name to any immediately containing DOT,
			% recursively.
			row_rows_DOT = 1:numel(rows_DOT); % A list of which rows of 'rows_DOT' that 'rows_ancestor' refers to.
			rows_ancestor = rows_DOT; % 'rows' here again refers to the row of this.lexer.relations
			% Also keep a record of the root-most DOT that contains the full DOT
			% sequence
			rows_topDOTcontainer = rows_DOT;
			while ~isempty(row_rows_DOT)
				
				% Look one level up the tree
				rows_ancestor = this.lexer.relations(rows_ancestor,this.lexer.cols.parent);
				isDOT = this.lexer.relations(rows_ancestor,this.lexer.cols.type) == this.lexer.types.DOT;
				% Remove non-DOT ancestors from the investigation
				row_rows_DOT(~isDOT)  = [];
				rows_ancestor(~isDOT) = [];
				% Overwrite the rows_topDOTcontainer with the new highest found DOT
				% ancestor
				rows_topDOTcontainer(row_rows_DOT) = rows_ancestor;
				
				% If still in play, assume the right child is a FIELD, and extract its
				% corresponding string
				rows_rightChild = this.lexer.relations(rows_ancestor,this.lexer.cols.rightChild);
				fieldNames = this.lexer.labels(this.lexer.relations(rows_rightChild,this.lexer.cols.string),1);
				% Append the field name to the respective node name
				nodeName(row_rows_DOT) = cellfun(@(nn,fn) [nn,'.',fn], nodeName(row_rows_DOT,1),fieldNames, 'UniformOutput',false);
				
			end
			
			% Determine whether each node is a 'use'.
			isUse = ~isDOTdefinition;
			% It's not quite this simple, and we need to perform some
			% corrections. If a node is defined early on, and then used
			% later, don't count the latter as a use. We need to be
			% careful. If we get a line like
			%    v.a = v.a;
			% then it counts both as a use and a definition. However, if we
			% get code like
			%    v.a = 3;
			%    abc = v.a;
			% then v.a should not count towards a use.
			% To distinguish these cases, we also need to know which line
			% of code the def/use appeared on. This is less directly tied
			% to the line of written code, and more has to do with which
			% syntactical line (akin to a sentence) this happened on.
			% Determine those now.
			row_rows_DOT = 1:numel(rows_DOT); % A list of which rows of 'rows_DOT' that 'rows_ancestor' refers to.
			rows_ancestor = rows_topDOTcontainer; % 'rows' here again refers to the row of this.lexer.relations. Start a bit closer to the root, may as well.
			rows_containingSentence = nan(size(rows_DOT));
			while ~isempty(row_rows_DOT)
				% Look one level higher to see the parent. Save a copy of
				% our last place first.
				rows_lastAncestor = rows_ancestor;
				rows_ancestor = this.lexer.relations(rows_ancestor,this.lexer.cols.parent);
				
				% Check whether we've hit the root of that sentence
				isAtRoot = rows_ancestor == 0; % No formal parent to reference.
				% Save the starting lexeme row for these items we've
				% reached the root. 
				rows_containingSentence(row_rows_DOT(isAtRoot)) = rows_lastAncestor(isAtRoot);
				% Trim these found-root items from investigation
				row_rows_DOT( isAtRoot) = [];
				rows_ancestor(isAtRoot) = [];
			end
			% Appy the correction: it's only a 'use' if there are no
			% previous sentences in which that item was defined.
			[~,a,b] = unique( cellfun(@(t,n)[t,'.',n],infoNodeType,nodeName,'UniformOutput',false) );
			countsB = histc(b,1:numel(a));
			for uniqInd = find( countsB > 1 )' % Only need to correct things which appear more than once.
				nodeInds = find( b==uniqInd ); % Find all the entries which share this InfoNode
				% Find the earliest sentence which defines this InfoNode
				rows_containingSentence_mini = rows_containingSentence(nodeInds);
				row_earliestDefSentence = min([rows_containingSentence_mini(isDOTdefinition(nodeInds));inf]); % If never defined, inf.
				% All uses with sentence row 
				isTrueUse = ~isDOTdefinition(nodeInds) & (rows_containingSentence_mini < row_earliestDefSentence);
				isUse(nodeInds(isTrueUse)) = true;
			end
			
% For reference, here are all the useful results from this function
% rows_DOT
% infoNodeType
% rows_topDOTcontainer
% nodeName
% isDOTdefinition
% rows_containingSentence
% isUse
			
			% Make a list of the outputs
			infoNodeDetails = struct(...
				'type', infoNodeType,...
				'name', nodeName,...
				'isDef',num2cell(isDOTdefinition(:)),...
				'isUse',num2cell(isUse(:)));
			
		end
		
	end
	
	methods (Access = private)
		
		% Lexify the source code using the mtree interface.
		function lexify(this)
			this.lexer = mtree_interface(this.sourceCode);
		end
		
	end
	
end