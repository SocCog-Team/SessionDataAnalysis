function [ bar_xpos_list ] = fnGetXposListForGroupedBars( n_groups, n_bars_per_group )
%GET_XPOS_LIST_FOR_GROUPED_BARS in grouped bar plots, the bar groups are
%centered around the XTicks, but to label each bar one needs the xp
%-position of each bar, so try to calculate that
%   Detailed explanation goes here (implementation lifted from barweb)

bar_xpos_list = zeros([1 (n_groups * n_bars_per_group)]);
% what if there is only one group of bars
if (n_groups == 1)
	n_groups = n_bars_per_group;
	n_bars_per_group = 1;
end	

groupwidth = min(0.8, n_bars_per_group / (n_bars_per_group + 1.5));
for i = 1:n_bars_per_group
	cur_i_bar_idx = i:n_bars_per_group:length(bar_xpos_list);
	bar_xpos_list(cur_i_bar_idx) = (1:n_groups) - groupwidth / 2 + (2 * i - 1) * groupwidth / (2 * n_bars_per_group);
end

return
end

