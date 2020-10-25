 
filename = 'code_source.m';
snippet = fileread(filename);

cs.lexer = mtree_interface(snippet);

validInfoNodeTypes = {'v','w','c'};

% Find all DOT lexemes
rows_DOT = find(cs.lexer.relations(:,cs.lexer.cols.type) == cs.lexer.types.DOT); % 'rows' here refers to the row of this.lexer.relations
% Reduce these to those which have an immediate left child which is an ID
	if any(cs.lexer.relations(rows_DOT,cs.lexer.cols.leftChild)==0), warning('DOT can apparently not have a left child'), end
rows_DOT = rows_DOT( cs.lexer.relations(rows_DOT,cs.lexer.cols.leftChild) ~= 0 ); % Require it has a child
rows_DOTleftChild = cs.lexer.relations(rows_DOT,cs.lexer.cols.leftChild);
keep = cs.lexer.relations(rows_DOTleftChild,cs.lexer.cols.type) == cs.lexer.types.ID; % Keep only those whose left child is an ID
rows_DOT = rows_DOT(keep);
rows_DOTleftChild = rows_DOTleftChild(keep);
% Now check the string associated with that ID. Require that it matches one
% of the validInfoNodeTypes.
	if any(cs.lexer.relations(rows_DOTleftChild,cs.lexer.cols.string)==0), error('DOT ID can apparently not have a string'), end
referencedStringInds = cs.lexer.relations(rows_DOTleftChild,cs.lexer.cols.string);
referencedStrings = cs.lexer.labels(referencedStringInds);
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
	rows_ancestor = cs.lexer.relations(rows_ancestor,cs.lexer.cols.parent);
	
	% (2) Downselect to what is not the top of a tree
	keepPursuing = rows_ancestor ~= 0; % 0 when at the top of the tree
	% Save these entries as non-definitions
	isDOTdefinition(row_rows_DOT(~keepPursuing)) = 0;
	% Do the actual downselect
	row_rows_DOT  = row_rows_DOT( keepPursuing);
	rows_ancestor = rows_ancestor(keepPursuing);
	
	% (3) On everything remaining, test whether we've found an EQUALS lexeme.
	ancestorIsEQUALS = cs.lexer.relations(rows_ancestor,cs.lexer.cols.type) == cs.lexer.types.EQUALS;
	% If we we came from a left child of this EQUALS, then mark this item
	% as a definition.
	isLeftChild = cs.lexer.relations( rows_ancestor(ancestorIsEQUALS), cs.lexer.cols.leftChild ) == rows_ancestor_last(ancestorIsEQUALS);
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

% %#ok<*NOPTS>
% '[A]>[B]' % A's parent is B
% '[ID"v"][FIELD]>[DOT][*]>[EQUALS]'
% 
% '{[A][B]}>[C]' % A is a left child of C, B is a right child of C
% '[*]' % unconstrained lexeme
% '{{[A][B]}>[C][D]}>[E]' % left to right, (A,B)>C and (C,D)>E
% '{{[A][B]}>[C]{[D][E]}>[F]}>[G]' % (A,B)>C and (D,E)>F and (C,F)>G
% '{{[A][B]}>[C][D]}>[E]>[F]' % (A,B)>C and (C,D)>E and (E)>F
% '{{[A][B]}>[C][D]>[E]}>[F]' % (A,B)>C and (C,D)>E and (E)>F





% edge case: using a non-definition to index a definition on the LHS of an
% EQUALS will not be handled correctly.


% determine the node names
%{
	v.aaa.b and v.aaa.c have no relation, they are separate nodes. They are
	only both inside v.aaa for user organization purposes
	
	% NOT CURRENTLY IMPLEMENTED. DISREGARDS SUBSCRIPTING
		if definition & subscripting: ending is field name
		if not definition & subscripting & variable: ending is field name
		if not definition & subscripting & wrapper: ending is method name
%}

% Sanity check
if any(   cs.lexer.relations(  cs.lexer.relations( cs.lexer.relations(:,cs.lexer.cols.type) == cs.lexer.types.DOT, cs.lexer.cols.rightChild),  cs.lexer.cols.type) ~= cs.lexer.types.FIELD   ), error('DOTs can have a non-FIELD right child'), end
if any(  cs.lexer.relations( cs.lexer.relations(:,cs.lexer.cols.type) == cs.lexer.types.FIELD, cs.lexer.cols.string) == 0  ), error('FIELDs can apparently not have associated strings'), end

% From the tip of our DOT tree, the left child was determined to be one
% of the validInfoNodeTypes. Now, the right child is the start of the node
% name. That right child will necessarily be a FIELD.
rows_rightChild = cs.lexer.relations(rows_DOT,cs.lexer.cols.rightChild);
nodeName = cs.lexer.labels(cs.lexer.relations(rows_rightChild,cs.lexer.cols.string));
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
	rows_ancestor = cs.lexer.relations(rows_ancestor,cs.lexer.cols.parent);
	isDOT = cs.lexer.relations(rows_ancestor,cs.lexer.cols.type) == cs.lexer.types.DOT;
	% Remove non-DOT ancestors from the investigation
	row_rows_DOT(~isDOT)  = [];
	rows_ancestor(~isDOT) = [];
	% Overwrite the rows_topDOTcontainer with the new highest found DOT
	% ancestor
	rows_topDOTcontainer(row_rows_DOT) = rows_ancestor;
	
	% If still in play, assume the right child is a FIELD, and extract its
	% corresponding string
	rows_rightChild = cs.lexer.relations(rows_ancestor,cs.lexer.cols.rightChild);
	fieldNames = cs.lexer.labels(cs.lexer.relations(rows_rightChild,cs.lexer.cols.string));
	% Append the field name to the respective node name
	nodeName(row_rows_DOT) = cellfun(@(nn,fn) [nn,'.',fn], nodeName(row_rows_DOT),fieldNames, 'UniformOutput',false);
	
end

% rows_DOT
% infoNodeType
% rows_topDOTcontainer
% nodeName


% Now to create the InfoNode objects


return

%%
validInfoNodeTypes = {'v','w','c'};
filename = 'code_source.m';
snippet = fileread(filename);
cs = CodeSnippet(snippet);
infoNodeDetails = cs.analyze(validInfoNodeTypes);

%%
clear all
clc

filename = 'code_source.m';
snippet = fileread(filename);

ac = AlgorithmConstructor();
% id = ac.addSnippet(snippet)
ids = ac.addSnippets(snippet)





