function [ out_figure_handle ] = fn_plot_RT_histogram_by_switches( in_figure_handle, RT_by_switch_struct_list, selected_switches_list, RT_by_switch_title_prefix_list, RT_by_switch_switch_pre_bins_list, RT_by_switch_switch_n_bins_list, RT_by_switch_color_list, aggregate_type_list)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

out_figure_handle = in_figure_handle;
n_data_structs = length(RT_by_switch_struct_list);


for i_switch_struct = 1 : n_data_structs
	current_data_struct = RT_by_switch_struct_list{i_switch_struct};
	current_prefix = RT_by_switch_title_prefix_list{i_switch_struct};
	current_switch_pre_bins = RT_by_switch_switch_pre_bins_list{i_switch_struct};
	current_switch_n_bins = RT_by_switch_switch_n_bins_list{i_switch_struct};
	current_data_color = RT_by_switch_color_list{i_switch_struct};
	current_aggregate_type = aggregate_type_list{i_switch_struct};
	
	plot_offset = ceil(current_switch_n_bins * 0.1);
	subplot(n_data_structs, 1, i_switch_struct)
	hold on
	current_xtick_pos = [];
	current_xtick_label = [];
	for i_switch = 1 : length(selected_switches_list)
		current_switch = selected_switches_list{i_switch};
		current_data = current_data_struct.(current_switch);
		current_switch_x_pos = plot_offset + current_switch_pre_bins + 1;
		current_xtick_pos(end+1) = current_switch_x_pos - 1;
		current_xtick_label{end+1} = current_switch;
		
		% is there something to plot?
		if ~isempty(current_data)
			current_x_vec = (plot_offset:1:(plot_offset + current_switch_n_bins - 1));
			plot(current_x_vec, current_data.(current_aggregate_type).mean, 'Color', current_data_color, 'Marker', '+', 'MarkerSize', 2, 'LineWidth', 0.66);
			
			%plot(current_x_vec, (current_data.(current_aggregate_type).mean - current_data.(current_aggregate_type).cihw), 'Color', current_data_color, 'Marker', '.', 'MarkerSize', 2, 'LineWidth', 0.5);
			%plot(current_x_vec, (current_data.(current_aggregate_type).mean + current_data.(current_aggregate_type).cihw), 'Color', current_data_color, 'Marker', '.', 'MarkerSize', 2, 'LineWidth', 0.5);
			inverse_index = (length(current_x_vec):-1:1);
			current_x_vec_patch = [current_x_vec, current_x_vec(inverse_index)];
			tmp_upper_ci = current_data.(current_aggregate_type).mean + current_data.(current_aggregate_type).cihw;
			tmp_lower_ci = current_data.(current_aggregate_type).mean - current_data.(current_aggregate_type).cihw;
			% the confidence intervals as transparent patch...
			patch('XData', current_x_vec_patch, 'YData', [tmp_upper_ci, tmp_lower_ci(inverse_index)], 'FaceColor', current_data_color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
		end
		plot_offset = plot_offset + current_switch_n_bins + ceil(current_switch_n_bins * 0.2);
		
		
	end
	hold off
	% scale the axis.
	set(gca(), 'XLim', [0, (plot_offset + ceil(current_switch_n_bins * 0.1))]);
	set(gca(), 'XTick', current_xtick_pos);
	set(gca(), 'XTickLabel', current_xtick_label)
	
end

return
end

