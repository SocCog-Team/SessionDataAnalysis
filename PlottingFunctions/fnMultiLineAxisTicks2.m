function [  ] = multiline_axisticks2( cur_axis_handle, dim_string, new_multiline_ticklabel_string, fontsize, VerticalOffset, HorizontalOffset)
%MULTILINE_AXISTICKS replace [X|Y]TickLabels with multiline text at the
%same position
%   Detailed explanation goes here
% taken from http://www.mathworks.com/support/solutions/en/data/1-D47WBX/index.html?product=ML&solution=1-D47WBX

%% Create figure and remove ticklabels
%plot(1:10);
cur_interpreter = 'none'; % 'none' or 'latex'

if nargin > 3
	change_fontsize = 1;
else
	change_fontsize = 0;
end

if nargin < 5
	switch dim_string
		case 'X'
			VerticalOffset = 0.6;
		case 'Y'
			VerticalOffset = 0.1;
	end
end
if nargin < 6
	switch dim_string
		case 'X'
			HorizontalOffset = 0.0;
		case 'Y'
			HorizontalOffset = 0.6;
	end
end

if size(new_multiline_ticklabel_string, 1) == 1
	% oops the ticklabel has only one line, so just bailout
	disp('oops the ticklabel has only one line, so just bailout');
	return
end

switch dim_string
	case 'X'
		set(cur_axis_handle, 'xticklabel', []) %Remove tick labels
		do_x = 1;
	case 'Y'
		set(cur_axis_handle, 'yticklabel', []) %Remove tick labels
		do_x = 0;
	otherwise
		error([dim_string, ' is not handdeled as dim_string...']);
end
do_y = ~do_x;


%% Get tick positions
yTicks = get(cur_axis_handle,'ytick');
xTicks = get(cur_axis_handle, 'xtick');

%% Reset the YTicklabels onto multiple lines, 2nd line being twice of first
minX = min(xTicks);
% You will have to adjust the offset based on the size of figure
% VerticalOffset = 0.1;
% HorizontalOffset = 0.6;
if (do_y)
	for yy = 1:length(yTicks)
		% Create a text box at every Tick label position
		% package new_multiline_ticklabel_string into the body of the latex array definition
		if strcmp(cur_interpreter, 'latex')
			cur_string = '$$\begin{array}{c}';
			for i_line = 1 : size(new_multiline_ticklabel_string, 1)
				cur_string = [cur_string, new_multiline_ticklabel_string{i_line, yy}, '\\'];
			end
			cur_string = cur_string(1:end-2);	% chop off the last '\\'
			cur_string = [cur_string, '\end{array}$$'];
		else
			cur_string = new_multiline_ticklabel_string(:, yy);
		end
		
		if (change_fontsize)
			text(minX - HorizontalOffset, yTicks(yy) - VerticalOffset, cur_string, 'Interpreter', cur_interpreter, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontSize', fontsize);
		else			
		% String is specified as LaTeX string and other appropriate properties are set
		text(minX - HorizontalOffset, yTicks(yy) - VerticalOffset, cur_string, 'Interpreter', cur_interpreter, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
		% {c} specifies that the elements of the different lines will be center
		% aligned. It may be replaced by {l} or {r} for left or right alignment
		end
	end
end
%% Reset the XTicklabels onto multiple lines, 2nd line being twice of first
minY = min(yTicks);
% You will have to adjust the offset based on the size of figure
% VerticalOffset = 0.6;
% HorizontalOffset = 0.0;
if (do_x)
	for xx = 1:length(xTicks)
		% Create a text box at every Tick label position
		% package new_multiline_ticklabel_string into the body of the latex array definition
		if strcmp(cur_interpreter, 'latex')
			cur_string = '$$\begin{array}{c}'
			for i_line = 1 : size(new_multiline_ticklabel_string, 1)
				cur_string = [cur_string, new_multiline_ticklabel_string{i_line, xx}, '\\'];
			end
			cur_string = cur_string(1:end-2);	% chop off the last '\\'
			cur_string = [cur_string, '\end{array}$$'];
		else
			cur_string = new_multiline_ticklabel_string(:, xx);
		end
		if (change_fontsize)
			text(xTicks(xx) - HorizontalOffset, minY - VerticalOffset, cur_string, 'Interpreter', cur_interpreter, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', fontsize);
		else	
			% String is specified as LaTeX string and other appropriate properties are set
			text(xTicks(xx) - HorizontalOffset, minY - VerticalOffset, cur_string, 'Interpreter', cur_interpreter, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
			% {c} specifies that the elements of the different lines will be center
			% aligned. It may be replaced by {l} or {r} for left or right alignment
		end
	end
end

return

end

