function [ fh_cur_contingency_table, cur_group_names ] = fnPlotContingencyTable_stacked( table, row_names, column_names, group_by_string, title_string, plot_type, Psymbol_by_group, cols_idx_per_symbol, img_fqn_by_group_list )
%PLOT_CONTINGENCY_TABLE Summary of this function goes here
%   Detailed explanation goes here
% TODO implement mosaic plots as option?
% plot a bar for each group giving the proportion of outcomes
%	also plot the group names as well as total n per group
% TODO:
%	change color scheme to somethinh less ghastly
%	position significance comparison bars in fewer bands...


if ~exist('Psymbol_by_group', 'var') || isempty(Psymbol_by_group)
	Psymbol_by_group = {};
end

if ~exist('cols_idx_per_symbol', 'var') || isempty(cols_idx_per_symbol)
	cols_idx_per_symbol = [];
end

if ~exist('img_fqn_by_group_list', 'var') || isempty(img_fqn_by_group_list)
	img_fqn_by_group_list = {};
end

% if the last column is just chance, exclude it from the plots?
show_chance = 0;
show_xlabels = 1;
ReplaceGroupNamesByGroupNumbers = 0;
AddNumTrialsToLabel = 1;

%stacked_bars = 0;
bar_type = 'norm'; % norm, stacked, grouped

bar_type = 'stacked_bars';


switch group_by_string
	case 'row'
		%row_names = row_names(1:end - 1);
		%table = table(1:end-1, :);
		group_names = row_names;
	case 'column'
		%column_names = column_names(1:end -1);
		%table = table(:, 1:end-1);
		group_names = column_names;
	otherwise
		error([group_by_string, ' is not handeled yet']);
end


if ~(show_chance) && (strcmp('chance', row_names(end)) || strcmp('chance', column_names(end)))
	switch group_by_string
		case 'row'
			row_names = row_names(1:end - 1);
			table = table(1:end-1, :);
			group_names = row_names;
		case 'column'
			column_names = column_names(1:end -1);
			table = table(:, 1:end-1);
			group_names = column_names;
		otherwise
			error([group_by_string, ' is not handeled yet']);
	end
	% NOTE: we can have more or less images than groups, but if equal assume one for chance... 
	if ~isempty(img_fqn_by_group_list) && (length(img_fqn_by_group_list) == length(group_names) + 1)
		img_fqn_by_group_list = img_fqn_by_group_list(1:end-1);
	end
	
	if ~isempty(Psymbol_by_group)
		Psymbol_by_group = Psymbol_by_group(1:end-1);
	end
	if ~isempty(cols_idx_per_symbol)
		cols_idx_per_symbol = cols_idx_per_symbol(:, 1:end-1);
	end
end

n_types = 2;
% if ~isempty(cell2mat(regexp(group_names, '_MSC02')))
% 	n_types = n_types + 2;
% end
% if ~isempty(cell2mat(regexp(group_names, '_MSC10')))
% 	n_types = n_types + 2;
% end
% if ~isempty(cell2mat(regexp(group_names, '_MSC12')))
% 	n_types = n_types + 2;
% end

if strcmp(title_string, 'outcome by_trialtype')
	bar_type = 'grouped'; % norm, stacked, grouped
	%n_types = 4;
	% if all cues were stimulated we need more bars
	tmp_list = regexp(group_names, '_MSC12');
% 	if ~isempty(cell2mat(regexp(group_names, '_MSC12')))
% 		n_types = 8;
% 	end
end	

% try black on grayish levels, avoid pure black and white
symbol_color = [0.0 0.0 0.0]; %[0.5 0.5 0.5];

n_outcomes = size(table, 2);
% tmp_custom_bar_color_scheme = bone(n_outcomes + 2);	% leave empty to use default color schme, otherwise give the name of the color function
% custom_bar_color_scheme = tmp_custom_bar_color_scheme(2:end-1, :);

tmp_custom_bar_color_scheme = ones([n_outcomes 3]);
tmp_custom_bar_color_scheme(1, :) = [0.5 0.5 0.5];
custom_bar_color_scheme = tmp_custom_bar_color_scheme;
custom_bar_color_scheme = [0.33 0.33 0.33; 0.33 0.0 0.0; 0.66 0.66 0.66; 1.0 0.0 0.0];	% diff is red, light is MS
custom_bar_color_scheme = [0.33 0.33 0.33; 0.66 0.66 0.66; 0.50 0.0 0.0; 1.0 0.0 0.0];	% diff is light, MS is red
if (n_types == 8)
	custom_bar_color_scheme = [0.33 0.33 0.33; 0.66 0.66 0.66; 0.50 0.50 0.00; 1.00 1.00 0.00; 0.00 0.50 0.00; 0.00 1.00 0.00; 0.50 0.00 0.00; 1.00 0.00 0.00];	% diff is light, MS is red
end

switch title_string
	case 'value'
		custom_bar_color_scheme = [1.0 0.0 0.0; 0.0 0.0 1.0; 1.0 0.0 1.0; 0.0 1.0 0.0];	% diff is red, light is MS
	case 'side'
		custom_bar_color_scheme = [1.0 0.0 0.0; 0.0 1.0 0.0; 1.0 1.0 0.0; 0.0 0.0 1.0];	% (both) left is red, (both) right is green
	case 'sameness'
		custom_bar_color_scheme = [0.0 1.0 0.0; 1.0 0.0 0.0];	% same: green, different: red
end

%custom_bar_color_scheme = [0.0 0.5 0.0; 0.33 0.33 0.33; 0.0 1.0 0.0; 0.66 0.66 0.66];	% same is green, light is MS

% inverted color scheme
%custom_bar_color_scheme = tmp_custom_bar_color_scheme((size(tmp_custom_bar_color_scheme, 1)-1:-1:2), :);


% shape the data
switch group_by_string
	case 'row'
		group_totals = sum(table, 2);
		outcome_totals = sum(table, 1);
		pct_table = (table ./ repmat(group_totals, [1, size(table, 2)])) * 100;
		group_names = row_names;
		legend_string = column_names;
	case 'column'
		group_totals = sum(table, 1);
		outcome_totals = sum(table, 2);
		pct_table = (table ./ repmat(group_totals, [size(table, 1), 1])) * 100;
		%pct_table = (table ./ repmat(group_totals, [1, size(table, 1)])) * 100;
		pct_table = pct_table';
		group_names = column_names;
		legend_string = row_names;
	otherwise
		error([group_by_string, ' is not handeled yet']);
end

% x_limits = get(gca(), 'XLim');
% y_limits = get(gca(), 'YLim');

% long names and/or many groups make the xlabel unreadable
cur_group_names = group_names;
cur_x_group_names = group_names;
cur_NumTrials_list = group_names;
for i_group = 1 : length(group_names)
	cur_x_group_names{i_group} = num2str(i_group, '%02d');
	cur_group_names{i_group} = [num2str(i_group, '%02d'), '_', group_names{i_group}];
	if (AddNumTrialsToLabel)
		cur_NumTrials_list{i_group} = num2str(group_totals(i_group));
	end	
end

if ~(ReplaceGroupNamesByGroupNumbers)
    cur_x_group_names = cur_group_names;
end

if (AddNumTrialsToLabel)
	cur_x_group_names = [cur_x_group_names; cur_NumTrials_list];
end	

%group_names_and_n = cur_x_group_names;
% for i_group = 1 : size(group_totals, 1)
% 	group_names_and_n{2, i_group} = group_names{i_group};
% 	group_names_and_n{1, i_group} = ['n:', num2str(group_totals(i_group))];
% end

%TODO put the staggerer into its own function, taking in an already
%multilined label set
% only go multiline, if required...
MaxXLabelChars = 0;
for iGroup = 1 : length(cur_group_names)
    MaxXLabelChars = max([MaxXLabelChars, length(cur_group_names{iGroup})]);
end

if (length(group_names) > 10) || (MaxXLabelChars >= 20)
	lines_per_label = 2;
	lines_per_label = 1;	% for sfn13
	n_staggered_label_groups = 2;
	%n_staggered_label_groups = ceil(length(group_names) / 6);	% to keep things readable
	%for i_group = 1 : size(table, 1)
    % make this work for columns and rows...
    for i_group = 1 : length(group_totals)
		cur_group_mod = mod(i_group, n_staggered_label_groups);
		if ~cur_group_mod
			cur_group_mod = n_staggered_label_groups;	% we want to cycle through n_staggered_label_groups
		end
		for i_label_group = 1 : (n_staggered_label_groups * lines_per_label)
			group_names_and_n{i_label_group, i_group} = '';%['n:', num2str(group_totals(i_group))];
		end
		label_group_offset = (cur_group_mod - 1) * lines_per_label;
		if (lines_per_label == 1)
			group_names_and_n{label_group_offset + 1, i_group} = cur_x_group_names{i_group};
		else
			group_names_and_n{label_group_offset + 1, i_group} = ['n:', num2str(group_totals(i_group))];
			%group_names_and_n{label_group_offset + 2, i_group} = row_names{i_group};
			group_names_and_n{label_group_offset + 2, i_group} = cur_x_group_names{i_group};
		end
	end
else
	group_names_and_n = cur_x_group_names;
end



if strcmp('subplot', plot_type)
	fh_cur_contingency_table = gca();
else
	fh_cur_contingency_table = figure;
end

x_limits = get(gca(), 'XLim');
y_limits = get(gca(), 'YLim');

hold on

switch bar_type
	case  'stacked_bars'
		plot_data = pct_table;
		bar_handle = bar(plot_data, 'stacked', 'DisplayName','table', 'BarWidth', 0.7);
		bar_xpos_list = (1:1:size(plot_data, 1));%get(gca(), 'XTick');
		%bar_xpos_list = fnGetXposListForGroupedBars(size(plot_data, 1), size(plot_data, 2));
		ylabel_text = 'Trials [%]';
	case 'norm'
		% just show percent correct
		plot_data = pct_table(:, 1);
		bar_handle = bar(plot_data, 'DisplayName', 'table', 'BarWidth', 0.7);
		bar_xpos_list = fnGetXposListForGroupedBars(size(plot_data, 1), size(plot_data, 2));
		ylabel_text = 'Trials [%]';
	case 'grouped'
		half_xpos_list = 0;
		% just show percent correct
		plot_data = pct_table(:, 1);
		if mod(size(plot_data, 1), n_types)
			disp('Warning: not all expected groups found in data, leaving plot empty...');
			return
		end
		plot_data = reshape(plot_data, [n_types, size(plot_data, 1)/n_types])';
		if size(plot_data, 1) == 1	% plot unhelpfully does not group vector data, only arrays
			plot_data = [plot_data; zeros(1,length(plot_data))];
			half_xpos_list = 1;
		end
		bar_handle = bar(plot_data, 'grouped', 'DisplayName', 'table', 'BarWidth', 0.7);
		bar_xpos_list = fnGetXposListForGroupedBars(size(plot_data, 1), size(plot_data, 2));
		if (half_xpos_list)
			bar_xpos_list = bar_xpos_list(1:length(bar_xpos_list)*0.5);
		end
		%in_group_bar_dist = (bar_xpos_list(end) - bar_xpos_list(end-1)) * 0.5;
		in_group_bar_dist = max(diff(bar_xpos_list)) * 0.5;	% take inter group distance if more than one group
		set(gca(), 'XLim', [bar_xpos_list(1)-in_group_bar_dist bar_xpos_list(end)+in_group_bar_dist]);
		ylabel_text = 'Trials [%]';
end
%errorbar((1:1:size(pct_table, 1)), ones([1 size(pct_table, 1)])*100, zeros([1 size(pct_table, 1)]), 'k', 'linestyle', 'none', 'LineWidth', 0.1, 'Marker', 'none', 'Markersize', 1);


if ~isempty(custom_bar_color_scheme)
	% create a better color scheme?
	colormap(custom_bar_color_scheme);
    
    switch bar_type
	case  'stacked_bars'
        for i_stack = 1 : size(plot_data, 2)
            %bar_handle(i_stack).CData = custom_bar_color_scheme(i_stack, :);
            bar_handle(i_stack).FaceColor = custom_bar_color_scheme(i_stack, :);
        end
    end
end

set(gca(), 'XTick', (1:1:size(pct_table, 1)));

switch size(cur_x_group_names, 2)
	case {1 2 3 4 5 6 7 8 9 10 11 12}
		TickLabel_fontsize = 12;
	case {13 14 15 16 17 18 19 20 21 23}
		TickLabel_fontsize = 10;
	case {24 25 26 27 28 29 30 31 32 33}
		TickLabel_fontsize = 9;
	otherwise
		TickLabel_fontsize = 3;
end
% for the paper keep font sizes the same
TickLabel_fontsize = 12;

if (show_xlabels)
    set(gca,'TickLabelInterpreter','none');
	set(gca(), 'XTickLabel', cur_x_group_names, 'FontSize', TickLabel_fontsize, 'FontWeight', 'normal');
	%ah_cur = rotateXLabels( gca, 45);	% would be nice but is fickle under R2011b macosx
	switch size(group_names_and_n, 2)
		case {1 2 3 4 5 6 7 8 9 10 11 12}
			multiline_axisticks_fontsize = 12;
		case {13 14 15 16 17 18 19 20 21 23}
			multiline_axisticks_fontsize = 9;
		otherwise
			multiline_axisticks_fontsize = 6;
	end
	xVerticalOffset = (abs(y_limits(1)) + diff(y_limits))/100 * 3;	% sm needs to be smarter
	if (size(group_names_and_n, 1)) > 1 && (ReplaceGroupNamesByGroupNumbers)
		center_col = floor(median(1:1:size(group_names_and_n, 2)));
		group_names_and_n{end + 1, center_col} = 'Group Numbers';
	end
	% for the paper keep font sizes the same
	multiline_axisticks_fontsize = 12;
	
	fnMultiLineAxisTicks2( gca(), 'X', group_names_and_n, multiline_axisticks_fontsize, xVerticalOffset, -0.0);	% 0.1, 0.6
end
%multiline_axisticks( gca(), 'X', group_names_and_n, multiline_axisticks_fontsize, 0.1, 0.6);

if (~show_xlabels)
	set(gca(), 'XTickLabel', {});
end
	

set(gca(), 'YLim', [0 100]);
%ylabel('Percent correct trials', 'FontSize', 18, 'FontWeight', 'bold');
ylabel(ylabel_text, 'FontSize', 14, 'FontWeight', 'bold');


if (size(group_names_and_n, 1) == 1) && (show_xlabels)
	xlabel('Group Numbers', 'FontSize', 14, 'FontWeight', 'bold');
end
%xlabel('Group Names');	% will interfere with multiline XTickLabels...
% if strcmp(version('-release'), '2007b')
% 	legend(legend_string, 'Interpreter', 'None', 'Location', 'EastOutside');
% else
% 	legend(legend_string, 'Interpreter', 'None', 'Location', 'EastOutside');
% end

%legend(legend_string, 'Interpreter', 'None', 'Location', 'EastOutside');
%legend('boxoff');

% for sfn2012
legend(legend_string, 'Interpreter', 'None', 'Location', 'SouthWest');
legend('boxoff');

% for sDMS_MS no legend

% display the symbol per group
if ~isempty(Psymbol_by_group)
	y_offset = 0.04;
	set(gca(), 'YLim', [0 150]); % make some room for the bars
	set(gca(), 'YTick', [0 50 100]); % but limit to 100%
	
	switch size(group_names_and_n, 2)
		case {1 2 3 4 5 6}
			symbol_font_size = 10;
			y_row_offset_factor = 0.09;%0.09;	% fraction of plot space to give to each y symbol row
			col_pair_connection_line_width = 1.0;% 2.0;
		case {7 8 9 10 11 12}
			symbol_font_size = 10;
			y_row_offset_factor = 0.07;	% fraction of plot space to give to each y symbol row
			col_pair_connection_line_width = 1.0; %1.5;
		case {13 14 15 16 17 18 19 20}
			symbol_font_size = 10;
			y_row_offset_factor = 0.06;	% fraction of plot space to give to each y symbol row
			col_pair_connection_line_width = 0.9; %1.0;
		case {21 23 24 25 26 27 28 29 30}
			symbol_font_size = 10;
			y_row_offset_factor = 0.04;	% fraction of plot space to give to each y symbol row
			col_pair_connection_line_width = 0.75;
		otherwise
			symbol_font_size = 6;
			y_row_offset_factor = 0.04;	% fraction of plot space to give to each y symbol row
			col_pair_connection_line_width = 0.5;
	end
	% for the paper keep font sizes the same
	symbol_font_size = 12;
	y_row_offset_factor = 0.06;
	
	% for the sDMS_MS paper the scaled plots look bad otherwise
	col_pair_connection_line_width = 0.75;
	
	y_lim = get(gca(), 'YLim');
	y_range = diff(y_lim);
	xs_lists = bar_xpos_list; %get(gca(), 'XTick');
	%ys_list = ones(size(xs_lists)) * 0.80 * y_range;
	sig_pair_idx = find(~strcmp('', Psymbol_by_group));
	if ~isempty(cols_idx_per_symbol) && (sum(cols_idx_per_symbol(:)) >= 1) && ~isempty(sig_pair_idx)
		%sig_pair_idx = find(cols_idx_per_symbol(1,:));
		n_sig_group_pairs = length(sig_pair_idx);
		% TODO find minimal non-overlapping set of lines to keep the 
		% the stacking of the symbols
		ys_list = ones(size(sig_pair_idx)) * y_range;
		n_data_cols = length(Psymbol_by_group);
		n_data_cols = length(bar_xpos_list);
		ys_list = find_min_nonoverlapped_ys(cols_idx_per_symbol(:, sig_pair_idx), ys_list, y_row_offset_factor, n_data_cols);
		
		ys_list = ys_list + (y_offset * y_range);
		% at what column to place the symbols
		%xs_lists = mean(cols_idx_per_symbol(:, sig_pair_idx));	
		xs_lists = mean(xs_lists(cols_idx_per_symbol(:, sig_pair_idx)));	

			
		hold on
		for i_sig_group = 1 : n_sig_group_pairs
			%ys_list(i_sig_group) = ys_list(i_sig_group) - ((y_range * y_row_offset_factor) * i_sig_group);
			i_group = sig_pair_idx(i_sig_group);
			% the line
			plot(bar_xpos_list(cols_idx_per_symbol(:, i_group)), [ys_list(i_sig_group), ys_list(i_sig_group)], 'Color', symbol_color, 'LineWidth', col_pair_connection_line_width);
			
			% the symbol
			text(xs_lists(i_sig_group), ys_list(i_sig_group), Psymbol_by_group{i_group}, ...
				'HorizontalAlignment','center','VerticalAlignment','baseline', ...
				'Interpreter', 'None', 'FontSize', symbol_font_size, 'FontWeight', 'bold', 'Color', symbol_color);			
			
		end
		hold off
	else
		ys_list = ones(size(xs_lists)) * 0.85 * y_range;
		ys_list = ys_list + (y_offset * y_range);
% 		for i_group = 1 : length(Psymbol_by_group)
% 			text(xs_lists(i_group), ys_list(i_group), Psymbol_by_group{i_group}, ...
% 				'HorizontalAlignment','center','VerticalAlignment','middle', ...
% 				'Interpreter', 'None', 'FontSize', symbol_font_size, 'FontWeight', 'bold', 'Color', symbol_color);
% 		end
	end
	%title(title_string, 'Interpreter', 'None', 'FontSize', 18, 'FontWeight', 'bold');
end

% show the contingency table data for the current percentage column
if (strcmp(plot_type, 'DPZContTable'))
    xs_lists = bar_xpos_list;
    y_lim = get(gca(), 'YLim');
	y_range = diff(y_lim);
    ys_list = ones(size(xs_lists)) * 0.05 * y_range;
    symbol_font_size = 12;
    switch group_by_string
        case 'row'
            for iBar = 1 : length(xs_lists)
                text(xs_lists(iBar), ys_list(iBar), {num2str(table(iBar, 2)), num2str(table(iBar, 1))}, ...
                    'HorizontalAlignment','center','VerticalAlignment','middle', ...
                    'Interpreter', 'None', 'FontSize', symbol_font_size, 'FontWeight', 'bold', 'Color', symbol_color);
            end
        case 'column'
            for iBar = 1 : length(xs_lists)
                text(xs_lists(iBar), ys_list(iBar), {num2str(table(2, iBar)), num2str(table(1, iBar))}, ...
                    'HorizontalAlignment','center','VerticalAlignment','middle', ...
                    'Interpreter', 'None', 'FontSize', symbol_font_size, 'FontWeight', 'bold', 'Color', symbol_color);
            end           
    end
end

set(gca(), 'YTick', [0 50 100]);
set(gca(),'FontSize', 12);

main_axes_h = gca();
cur_xlim = get(gca(), 'XLim');		% x axis is evenly spaced in n_group equal segments
n_groups = length(group_names);
if (cur_xlim(2) > n_groups + 0.5)
	set(gca, 'XLim', [0.5 (n_groups + 0.5)]);
end

%axis square;						% now the fist and last segment are increased, does not work with image labels...
%set(gca, 'XLim', cur_xlim);		% and now we are back at equal segments (needed for images)
hold off;

% the following will remove the x labels...
if ~(show_xlabels)
    set(gca(), 'XTick', []);
end

% potentially use images as labels...
if ~isempty(img_fqn_by_group_list)
	label_plot_with_imgs(gca, img_fqn_by_group_list, 'top');
else
	if ~isempty(title_string)
		title(title_string, 'Interpreter', 'None', 'FontSize', 14, 'FontWeight', 'bold');
	end
end

% cur_xlim = get(gca(), 'XLim');		% x axis is evenly spaced in n_group equal segments
% axes(main_axes_h);
% axis square;						% now the fist and last segment are increased, does not work with image labels...
% set(main_axes_h, 'XLim', cur_xlim);		% and now we are back at equal segments (needed for images)

return
end

function [ ys_list ] = find_min_nonoverlapped_ys( col_endpoints, ys_list, y_row_offset_factor, n_data_cols )
% find the smallest set of lines that allow all symbol bars without overlap
n_pairs = size(col_endpoints, 2);
% get the row y_values for the worst case, we want to actually use less
max_y = ys_list(1);
y_per_row_offset = y_row_offset_factor * max_y;
y_row_offset_list = zeros(size(ys_list));
for i_pair = 1 : n_pairs
	y_row_offset_list(i_pair) = max_y - (y_per_row_offset * i_pair); % the y coordinate for each row...
end
% here we mark the used positions per row
taboo_cols_per_row = zeros([n_pairs, n_data_cols]);

% for each pair find the first row it fits in without overlap
for i_pair = 1 : n_pairs
	for i_row = 1 : length(ys_list)
		% which columns does the current line span over?
		cur_cols_idx_list = (col_endpoints(1, i_pair):1:col_endpoints(2, i_pair));
		cur_row_overlap_count = sum(taboo_cols_per_row(i_row, cur_cols_idx_list));
		if (cur_row_overlap_count)
			% not all required columns are free, so we overlap, try next
			% row
		else
			% this line fits in this row, mark it properly and select this
			% rows offset
			taboo_cols_per_row(i_row, cur_cols_idx_list) = 1;
			ys_list(i_pair) = y_row_offset_list(i_row);
			break
		end
	end
end	

return
end