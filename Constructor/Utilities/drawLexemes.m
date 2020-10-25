 
matlabFile = 'code_source.m';
% matlabFile = 'E:\Projects\Local Message App\LocalMessage.m';

global T draw 
m = mtree_interface(matlabFile,'-file');
T = m.relations;
C = m.labels;
charLineRefs = m.lineStarts;

N = m.lexemeTypes; % node type names

numNodes = size(T,1);
draw = struct();
draw(numNodes).width = [];
draw(numNodes).depth = [];
draw(numNodes).edge  = [];


width = getWidth(1,1,0);

figure();
axes('YDir','reverse','Units','normalized','Position',[0,0,1,1]);
hold on;
xlim([0,width]+[-1,1]*0.5);
ylim([1,max([draw.depth])]+[-1,1]*0.5 + [0,0.5])

Y = [linspace(0,1,100),nan];
X = 10*Y.^3 - 15*Y.^4 + 6*Y.^5;  % 3*Y.^2-2*Y.^3;


for node = 1:numNodes
	draw(node).x = draw(node).edge + draw(node).width/2;
	draw(node).y = draw(node).depth;
end

hasLine = T(:,13)~=0; numLines = sum(hasLine);
x0 = [draw(hasLine).x];
y0 = [draw(hasLine).y];
deltax = [draw(T(hasLine,13)).x] - x0;
deltay = [draw(T(hasLine,13)).y] - y0;

x_ = x0'+deltax'.*X;
y_ = y0'+deltay'.*Y;
plot(reshape(x_',[],1),reshape(y_',[],1),'Color','k');
for node = 1:numNodes
	
	string = N{T(node,1)};
	switch string
		case 'ID'
			color = [1,0.3,0.3];
		case 'FIELD'
			color = [0.3,0.3,1];
		case 'CALL'
			color = [0.3,1,0.3];
		otherwise
			color = 'w';
	end
	if T(node,8) ~= 0
		string = [string,': "',C{T(node,8)},'"']; %#ok<AGROW>
	end
	text(draw(node).x,draw(node).y,string,...
		'HorizontalAlignment','center',...
		'VerticalAlignment','middle',...
		'Color','k',...
		'EdgeColor','k',...
		'BackgroundColor',color,...
		'Interpreter','none',...
		'Visible','on',...
		'Rotation',22.5);
end

set(gcf,'ResizeFcn',@resizedFig)

% Create slider
slider = uicontrol('Style', 'slider',...
	'Min',0,'Max',width,'Value',width/2,...
	'Units','normalized',...
	'Position',[0,0,1,0.05],...
	'Callback',@horzSlider,...
	'SliderStep',[0.3,5]/width);
addlistener(slider ,'Value', 'PostSet', @(~,~)horzSlider(slider,[]));

resizedFig(gcf,[]);



function width = getWidth(startNode,depth,startEdge)
	
	global T draw
	
	node = startNode;
	edge = startEdge;
	width = 0;
	while true
		if all(T(node,2:3) == 0) % no direct children
			subWidth = 1;
		else % At least one direct child
			subWidth = 0;
			if T(node,2) ~= 0 % A left child exists
				subWidth = subWidth + getWidth(T(node,2),depth+1,edge); % Add the width of the left side
			end
			if T(node,3) ~= 0 % A right child exists
				subWidth = subWidth + getWidth(T(node,3),depth+1,edge+subWidth); % Add the width of the right side
			end
		end
		
		draw(node).width = subWidth;
		draw(node).depth = depth;
		draw(node).edge  = edge;
		
		width = width + subWidth;
		edge = edge + subWidth; % Grows the same as width, but is affected by its neighbors and parent
		
		if T(node,4) ~= 0
			node = T(node,4);
		else % == 0, no next indirect node
			break
		end
	end
	
end

function resizedFig(obj,~)
	ax = obj.Children(2);
	pbaspect_ = pbaspect(ax);
	xRange = range(ylim(ax)) * pbaspect_(1) / pbaspect_(2);
	xlim(ax,mean(xlim(ax))+[-1,1]/2*xRange);
	ax.UserData.xRange = xRange;
end
function horzSlider(obj,~)
	ax = obj.Parent.Children(2);
	center = obj.Value;
	xlim(ax,center+[-1,1]/2*ax.UserData.xRange);
end
