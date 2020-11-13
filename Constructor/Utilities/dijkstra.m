% Obtained from Mathworks File Exchange 2020-11-01, written by Joseph Kirk
% https://www.mathworks.com/matlabcentral/fileexchange/12850-dijkstra-s-shortest-path-algorithm
% Modified for my purposes 2020-11-01, Patrick D Fitzgerald
%    • Added some documentation
%    • Added a new output, segmentsUsed
%    • Removed some excess content
%    • Added custom weights
%    • Determined that the algorithm as written is incompatible with a
%    directed graph implementation.
function [dist,path,segmentsUsed] = dijkstra(nodes,segments,start_id,finish_id)
% DIJKSTRA Calculates the shortest distance and path between points on an
%     undirected graph using Dijkstra's Shortest Path Algorithm
% 
% [DIST, PATH, SEGMENTSUSED] = DIJKSTRA(NODES, SEGMENTS, SID, FID)
%     Calculates the shortest distance and path between start and finish
%     nodes SID and FID 
% 
% [DIST, PATH, SEGMENTSUSED] = DIJKSTRA(NODES, SEGMENTS, SID)
%     Calculates the shortest distances and paths from the starting node
%     SID to all other nodes in the map
% 
% Inputs:
%     NODES should be an Nx1 where each entry is the node (unique numeric) ID.
%     SEGMENTS should be an Mx4 matrix with the format [ID N1 N2 W]
%         where ID is an unique numeric segement identifier, and N1, N2
%         correspond to node IDs from NODES list such that there is an
%         undirected edge/segment between node N1 and node N2. W is the
%         (positive numeric) weight of that segment.
%         If SEGMENTS is provided as Mx3, the W weight entry is assumed to
%         be 1.0 for all segments.
%     SID should be the ID of the starting node
%     FID (optional) should be the ID of the stopping node
% 
% Outputs:
%     DIST is the summed weight(s) of the shortest path(s).
%         If FID was specified, DIST will be a 1x1 double representing the
%             path of lowest total weight from SID to FID. DIST will have
%             a value of INF if there are no segments connecting SID and FID.
%         If FID was not specified, DIST will be a 1xN vector representing
%		      the total weight of each of the shortest paths from SID to
%		      all nodes. DIST will have a value of INF for any nodes that
%		      cannot be reached from SID.
%     PATH is a list of nodes visited on the shortest route
%         If FID was specified, PATH will be a 1xP vector of node IDs from
%             SID to FID. NAN will be returned if there are no segments
%             connecting SID to FID. 
%         If FID was not specified, PATH will be a 1xN cell of vectors
%             representing the shortest route from SID to all other nodes
%             on the map. PATH will have a value of NAN for any nodes that
%             cannot be reached along the segments of the map.
%     SEGMENTSUSED is a list of segments used on the shortest routes.
%         If FID was specified, SEGMENTSUSED will be a 1xP vector of
%             segment IDs which capture the transition from SID to FID. NAN
%             will be returned if there are no segments connecting SID to
%             FID.
%         If FID was not specified, SEGMENTSUSED will be a 1xN cell of
%             vectors representing the order of segment IDs to capture the
%             shortest route from SID to all other nodes on the map.
%             SEGMENTSUSED will have a value of NAN for any nodes that
%             cannot be reached along the segments of the map.
	
	
	if (nargin < 3)
		error('Not enough arguments.')
	end
	
    % Initializations
	node_ids = nodes(:);
    num_map_pts = numel(nodes);
	if size(segments,2) < 4
		segments(:,4) = 1;
	end
	if any(segments(:,4) < 0)
		error('Weights must be positive');
	end
	
	% Instantiate the storage objects
    table = sparse(num_map_pts,2);
    shortest_distance = Inf(num_map_pts,1);
    settled = zeros(num_map_pts,1);
    path = num2cell(NaN(num_map_pts,1));
	segmentsUsed = path;
	% Populate them on how they pertain to the starting index.
    col = 2;
    pidx = find(start_id == node_ids);
    shortest_distance(pidx) = 0;
    table(pidx,col) = 0;
    settled(pidx) = 1;
    path(pidx) = {start_id};
	segmentsUsed(pidx) = {[]};
	
	% Specify the stopping conditions for the loop.
    if (nargin < 4) % compute shortest path for all nodes
        while_check = @(settled) sum(~settled) > 0;
    else % terminate algorithm early
        zz = find(finish_id == node_ids);
		while_check = @(settled) settled(zz) == 0;
    end
    while while_check(settled)
        % update the table
        table(:,col-1) = table(:,col);
        table(pidx,col) = 0;
        % find neighboring nodes in the segments list
		availableSegments_L = node_ids(pidx) == segments(:,2); % left ID matches
		availableSegments_R = node_ids(pidx) == segments(:,3); % right ID matches
		segment_ids   = [segments(availableSegments_L,1);segments(availableSegments_R,1)];
        neighbor_ids  = [segments(availableSegments_L,3);segments(availableSegments_R,2)];
		neighborCosts = [segments(availableSegments_L,4);segments(availableSegments_R,4)];
        % calculate the distances to the neighboring nodes and keep track of the paths
        for k = 1:length(neighbor_ids)
            cidx = find(neighbor_ids(k) == node_ids);
            if ~settled(cidx)
                d = neighborCosts(k);
                if (table(cidx,col-1) == 0) || ...
                        (table(cidx,col-1) > (table(pidx,col-1) + d))
                    table(cidx,col) = table(pidx,col-1) + d; %#ok<*SPRIX>
                    path(cidx) = {[path{pidx}, neighbor_ids(k)]};
					segmentsUsed(cidx) = {[segmentsUsed{pidx}, segment_ids(k)]};
					fprintf('');
                else
                    table(cidx,col) = table(cidx,col-1);
                end
            end
        end
        % find the minimum non-zero value in the table and save it
        nidx = find(table(:,col));
        [~,ndx] = min(table(nidx,col));
        if isempty(ndx)
            break
        else
            pidx = nidx(ndx(1));
            shortest_distance(pidx) = table(pidx,col);
            settled(pidx) = 1;
        end
    end
    if (nargin < 4) % return the distance and path arrays for all of the nodes
        dist = shortest_distance';
        path = path';
		segmentsUsed = segmentsUsed';
    else % return the distance and path for the ending node
        dist = shortest_distance(zz);
        path = path{zz};
		segmentsUsed = segmentsUsed{1};
    end
end