function [ output_args ] = fnAggregateAndPlotCoordinationMetricsByGroup_PNM19( session_metrics_datafile_fqn, group_struct_list, metrics_to_extract_list )
%FNAGGREGATEANDPLOTCOORDINATIONMETRICSBYGROUP Summary of this function goes here
%   Detailed explanation goes here

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


output_args = [];

if ~exist('session_metrics_datafile_fqn', 'var') || isempty(session_metrics_datafile_fqn)
    InputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2018');
    InputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2019');
    session_metrics_datafile_fqn = fullfile(InputPath, ['ALL_SESSSION_METRICS.late200.mat']);
    session_metrics_datafile_fqn = fullfile(InputPath, ['ALL_SESSSION_METRICS.last200.mat']);
end

[OutputPath, FileName, FileExt] = fileparts(session_metrics_datafile_fqn);

OutputPath = fullfile(InputPath, 'AggregatePlots');

OutputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'Projects', 'ProgressReportsAndPresentations', '2019_PrimateNeurobiologyMeeting_Goettingen', 'AggregatePlots');

if ~exist('metrics_to_extract_list', 'var') || isempty(metrics_to_extract_list)
    metrics_to_extract_list = {'AR'};
end

if ~exist('group_struct_list', 'var') || isempty(group_struct_list)
    group_struct_list = fn_get_session_group('BoS_human_monkey_2019');
end


% control variables
plot_avererage_reward_by_group = 0;
confidence_interval_alpha = 0.05;
plot_MI_space_scatterplot = 1;
MI_space_set_list = {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'HumansOpaque'}; % the set names to display
MI_space_set_list = {'Humans', 'Macaques_late', 'HumansOpaque', 'Humans50_50'}; % the set names to display
MI_space_set_list = {'GoodHumans', 'Macaques_late', 'BadHumans'}; % the set names to display
MI_space_set_list = {'HumansOpaque', 'Humans', 'Macaques_late', 'ConfederateTrainedMacaques'}; % the set names to display
MI_space_set_list = {'HumansOpaque', 'Humans', 'Macaques_late', 'ConfederateTrainedMacaquesBest'}; % the set names to display
MI_space_set_list = {'HumansOpaque', 'Humans', 'Humans50_50', 'Macaques_late', 'ConfederateTrainedMacaquesBest'}; % the set names to display
MI_space_set_list = {'HumansOpaque', 'HumansTransparent', 'Macaques_late', 'ConfederateTrainedMacaquesBest'}; % the set names to display


% cleaned up for the PNM poster
MI_jitter_x_on_collision = 1;
mark_flaffus_curius = 0;
MI_mark_all = 0;
MI_normalize_coordination_strength_50_50 = 1;
MI_threshold = 0.1;

plot_coordination_metrics_for_each_group = 1;
plot_coordination_metrics_for_each_group_graph_type = 'line';% bar or line

plot_AR_scatter_by_trainig_state = 1;

plot_blocked_confederate_data = 0;

XLabelRotation_degree = 45; % rotate the session labels to allow non-numeric labels on denser plots?
close_figures_at_end = 1;


copy_plots_to_outdir_by_group = 0;



project_name = 'SfN208';
CollectionName = 'BoS_human_monkey_2019';
project_line_width = 0.5;
OutPutType = 'pdf'; % this currently also saves pdf and fig
%OutPutType = 'pdf';
DefaultAxesType = 'PNM2019'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
DefaultPaperSizeType = 'SfN2018.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
output_rect_fraction = 0.5; % default 0.5
InvisibleFigures = 0;

if ~exist('fnFormatDefaultAxes')
    set(0, 'DefaultAxesLineWidth', 0.5, 'DefaultAxesFontName', 'Arial', 'DefaultAxesFontSize', 12, 'DefaultAxesFontWeight', 'normal');
end

if (InvisibleFigures)
    figure_visibility_string = 'off';
else
    figure_visibility_string = 'on';
end





% TODO, load the ALL_SESSION_METRICS.mat and extract the desired metric
% for each member session of each set, return a list of those for
% further

% load the coordination_metrics_table
load(session_metrics_datafile_fqn);

% extract the subsets of rows for the sessions in each group
n_groups = length(group_struct_list);
metrics_by_group_list = cell(size(group_struct_list));
for i_group = 1 : n_groups
    current_group = group_struct_list{i_group};
    % find the row indices for the current group members:
    [current_session_in_group_ldx, LocB] = ismember(coordination_metrics_table.key, current_group.filenames);
    % this is unfortunately unsorted, but we want to keep current_group.filenames order...
    current_session_in_group_idx = find(current_session_in_group_ldx);
    %order_idx = LocB(current_session_in_group_idx);
    % this will only work if each session ID is unique...
    [~, sort_key_2_filenames_order_idx] = sort(LocB(current_session_in_group_idx), 'ascend');
    %coordination_metrics_table.key(current_session_in_group_idx(I))'
    %current_group.filenames'
    metrics_by_group_list{i_group} = coordination_metrics_table.data(current_session_in_group_idx(sort_key_2_filenames_order_idx), :);
end


if (copy_plots_to_outdir_by_group)
    for i_group = 1 : n_groups
        current_group = group_struct_list{i_group};
        current_setname = current_group.setLabel;
        outdir = fullfile(OutputPath, '..', 'SessionSetPlots', current_setname);
        if ~exist(outdir, 'dir')
            mkdir(outdir)
        end
        % loop over all files
        current_session_id_list = current_group.filenames;
        for i_stem = 1 : length(current_session_id_list)
            current_proto_stem = current_session_id_list{i_stem};
            current_proto_stem = regexprep(current_proto_stem, '_IC_JointTrials.isOwnChoice_sideChoice$', '');
            current_stem = regexprep(current_proto_stem, '^DATA_', '');
            disp(['Processing: ', current_stem]);
            [status, message] = copyfile(fullfile(InputPath, [current_stem, '*']), [outdir, filesep]);
        end
    end
    disp('Copied all plots...');
    return
end


TitleSetDescriptorString = '';

% create the plot for averaged average reward per group
if (plot_avererage_reward_by_group)
    % collect the actual data
    AvgRewardByGroup_list = cell(size(group_struct_list)); % the actual reward values
    AvgRewardByGroup.mean = zeros(size(group_struct_list));
    AvgRewardByGroup.stddev = zeros(size(group_struct_list));
    AvgRewardByGroup.n = zeros(size(group_struct_list));
    AvgRewardByGroup.sem = zeros(size(group_struct_list));
    AvgRewardByGroup.ci_halfwidth = zeros(size(group_struct_list));
    AvgRewardByGroup.group_names = cell(size(group_struct_list));
    AvgRewardByGroup.group_labels = cell(size(group_struct_list));
    
    % now collect the
    for i_group = 1 : n_groups
        AvgRewardByGroup.group_names{i_group} = group_struct_list{i_group}.setName;
        AvgRewardByGroup.group_labels{i_group} = group_struct_list{i_group}.label;
        current_group_data = metrics_by_group_list{i_group};
        AvgRewardByGroup_list{i_group} = current_group_data(:, coordination_metrics_table.cn.averReward); % the actual reward values
        AvgRewardByGroup.mean(i_group) = mean(current_group_data(:, coordination_metrics_table.cn.averReward));
        AvgRewardByGroup.stddev(i_group) = std(current_group_data(:, coordination_metrics_table.cn.averReward));
        AvgRewardByGroup.n(i_group) = size(current_group_data, 1);
        AvgRewardByGroup.sem(i_group) = AvgRewardByGroup.stddev(i_group)/sqrt(AvgRewardByGroup.n(i_group));
    end
    AvgRewardByGroup.ci_halfwidth = calc_cihw(AvgRewardByGroup.stddev, AvgRewardByGroup.n, confidence_interval_alpha);
    
    FileName = CollectionName;
    Cur_fh_avg_reward_by_group = figure('Name', 'Average reward by group', 'visible', figure_visibility_string);
    fnFormatDefaultAxes(DefaultAxesType);
    [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    legend_list = {};
    %hold on
    
    for i_group = 1 : n_groups
        current_group_name = group_struct_list{i_group}.setName;
        
        % to display all individial values as scatter plots randomize the
        % positions for each group
        scatter_width = 0.6;
        x_list = ones(size(AvgRewardByGroup_list{i_group})) * i_group;
        scatter_offset_list = (scatter_width * rand(size(AvgRewardByGroup_list{i_group}))) - (scatter_width * 0.5);
        if (length(x_list) > 1)
            x_list = x_list + scatter_offset_list;
        end
        
        hold on
        bar(i_group, AvgRewardByGroup.mean(i_group), 'FaceColor', group_struct_list{i_group}.color, 'EdgeColor', [0.25 0.25 0.25]);
        errorbar(i_group, AvgRewardByGroup.mean(i_group), AvgRewardByGroup.ci_halfwidth(i_group), 'Color', [0.25 0.25 0.25]);
        
        %
        ScatterSymbolSize = 25;
        ScatterLineWidth = 0.75;
        current_scatter_color = group_struct_list{i_group}.color;
        current_scatter_color = [0.5 0.5 0.5];
        if group_struct_list{i_group}.FilledSymbols
            scatter(x_list, AvgRewardByGroup_list{i_group}, ScatterSymbolSize, current_scatter_color, group_struct_list{i_group}.Symbol, 'filled', 'LineWidth', ScatterLineWidth);
        else
            scatter(x_list, AvgRewardByGroup_list{i_group}, ScatterSymbolSize, current_scatter_color, group_struct_list{i_group}.Symbol, 'LineWidth', ScatterLineWidth);
        end
        
        if (mark_flaffus_curius)
            if strcmp(group_struct_list{i_group}.setName, 'Macaques early') || strcmp(group_struct_list{i_group}.setName, 'Macaques late')
                for i_session = 1 : length(group_struct_list{i_group}.filenames)
                    if ~isempty(strfind(group_struct_list{i_group}.filenames{i_session}, 'A_Flaffus.B_Curius'))
                        dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
                        text(x_list(i_session)+dx, AvgRewardByGroup_list{i_group}(i_session)+dy, {num2str(i_session)},'Color', current_scatter_color, 'Fontsize', 8);
                    end
                end
            end
        end
        if (MI_mark_all)
            for i_session = 1 : length(group_struct_list{i_group}.filenames)
                dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
                text(x_list(i_session)+dx, AvgRewardByGroup_list{i_group}(i_session)+dy, {num2str(i_session)},'Color', current_scatter_color, 'Fontsize', 8);
            end
        end
        
        
        hold off
    end
    
    
    xlabel('Grouping', 'Interpreter', 'none');
    ylabel('Average Reward', 'Interpreter', 'none');
    set(gca, 'XLim', [1-0.8 (n_groups)+0.8]);
    set(gca, 'XTick', []);
    %set(gca, 'XTick', (1:1:n_groups));
    %set(gca, 'XTickLabel', AvgRewardByGroup.group_labels, 'TickLabelInterpreter', 'none');
    
    set(gca(), 'YLim', [0.9, 4.1]);
    set(gca(), 'YTick', [1 1.5 2 2.5 3 3.5 4]);
    %     if (PlotLegend)
    %         legend(legend_list, 'Interpreter', 'None');
    %     end
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', OutPutType]);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', 'pdf']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', 'fig']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
end


if (plot_MI_space_scatterplot)
    % collect the actual data
    MIs_by_group_miside_list = cell(size(group_struct_list)); % the actual MIside values per group
    MIs_by_group_mitarget_list = cell(size(group_struct_list)); % the actual MItarget values per group
    
    MIs_by_group.group_names = cell(size(group_struct_list));
    MIs_by_group.group_labels = cell(size(group_struct_list));
    MIs_by_group.vectorlength = cell(size(group_struct_list));
    MIs_by_group.atan = cell(size(group_struct_list));
    
    % now collect the
    for i_group = 1 : n_groups
        MIs_by_group.group_names{i_group} = group_struct_list{i_group}.setName;
        MIs_by_group.group_labels{i_group} = group_struct_list{i_group}.label;
        current_group_data = metrics_by_group_list{i_group};
        MIs_by_group_miside_list{i_group} = current_group_data(:, coordination_metrics_table.cn.miSide);
        MIs_by_group_mitarget_list{i_group} = current_group_data(:, coordination_metrics_table.cn.miTarget);
        MIs_by_group.vectorlength{i_group} = sqrt(MIs_by_group_miside_list{i_group}.^2 + MIs_by_group_mitarget_list{i_group}.^2);
        tmp = atan(MIs_by_group_miside_list{i_group} ./ MIs_by_group_mitarget_list{i_group});
        % since division by zero is undefined we need to special case of
        % MI target == 0, here we just clamp to the extreme right value
        tmp(MIs_by_group_mitarget_list{i_group} == 0) = pi()/2;
        MIs_by_group.atan{i_group} = tmp;
    end
    
    FileName = CollectionName;
    Cur_fh_avg_reward_by_group = figure('Name', 'mutual information space plot', 'visible', figure_visibility_string);
    fnFormatDefaultAxes(DefaultAxesType);
    [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    legend_list = {};
    hold on
    
    for i_group = 1 : n_groups
        
        current_group_label = group_struct_list{i_group}.setLabel;
        if ~ismember(current_group_label, MI_space_set_list)
            continue;
        end
        
        if strcmp(group_struct_list{i_group}.Symbol, 'none')
            % skip sets no symbol, as scatter does not tolerate 
           continue 
        end
        current_group_name = group_struct_list{i_group}.setName;
        legend_list{end+1} = current_group_name;        
        
        ScatterSymbolSize = 50;
        ScatterLineWidth = 0.75;
        current_scatter_color = group_struct_list{i_group}.color;
        %current_scatter_color = [0.5 0.5 0.5];
        x_list = MIs_by_group.atan{i_group};
        y_list = MIs_by_group.vectorlength{i_group};

        orig_x_list = x_list;
        if (MI_jitter_x_on_collision)
            % to display all individial values as scatter plots randomize the
            % positions for each group
            scatter_width = 0.1;
            scatter_offset_list = (scatter_width * rand(size(x_list))) - (scatter_width * 0.5);
            
            if (length(x_list) > 1)
                x_list = x_list + scatter_offset_list;
                negative_x_idx = find(x_list < 0);
                x_list(negative_x_idx) = 0;
            end
        end
        
        orig_y_list = y_list;
        if (MI_normalize_coordination_strength_50_50)
            for i_x = 1 : length(orig_x_list)
                cur_orig_x = orig_x_list(i_x);
                cur_y_adjust_factor = sqrt(tan(min([cur_orig_x, (0.5 * pi - cur_orig_x)])) + 1);
                y_list(i_x) = orig_y_list(i_x) / cur_y_adjust_factor;
            end         
        end
        
        if group_struct_list{i_group}.FilledSymbols
            scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, group_struct_list{i_group}.Symbol, 'filled', 'LineWidth', ScatterLineWidth, 'MarkerEdgeColor', [0.5 0.5 0.5]);
        else
            scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, group_struct_list{i_group}.Symbol, 'LineWidth', ScatterLineWidth);
        end
        
        if (mark_flaffus_curius)
            if strcmp(group_struct_list{i_group}.setName, 'Macaques early') || strcmp(group_struct_list{i_group}.setName, 'Macaques late')
                for i_session = 1 : length(group_struct_list{i_group}.filenames)
                    if ~isempty(strfind(group_struct_list{i_group}.filenames{i_session}, 'A_Flaffus.B_Curius'))
                        dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
                        text(x_list(i_session)+dx, y_list(i_session)+dy, {num2str(i_session)},'Color', current_scatter_color, 'Fontsize', 8);
                    end
                end
            end
        end
        
        if (MI_mark_all)
            for i_session = 1 : length(group_struct_list{i_group}.filenames)
                dx = 0.02; dy = 0.02; % displacement so the text does not overlay the data points
                text(x_list(i_session)+dx, y_list(i_session)+dy, {num2str(i_session)},'Color', current_scatter_color, 'Fontsize', 8);
            end     
        end
        
        
    end
    if ~isempty(MI_threshold)
       plot([-0.05, pi()/2+0.1], [MI_threshold, MI_threshold], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--'); 
    end
    
    hold off
    axis([-0.05, pi()/2+0.1, -0.05, 1.4]);
    ylabel('Coordination strength (MI magnitude) [a.u.]', 'Interpreter', 'none');
    if (MI_normalize_coordination_strength_50_50)
        axis([-0.05, pi()/2+0.1, -0.05, 1.05]);
        ylabel('normalized coordination strength', 'Interpreter', 'none');
    end
    xlabel('Coordination type [a.u.]', 'Interpreter', 'none');
    set( gca, 'xTick', [0, pi()/4, pi()/2], 'xTickLabel', {'Side-based', 'Trial-by-trial', 'Target-based'});
    
    %     if (PlotLegend)
    %         legend(legend_list, 'Interpreter', 'None');
    %     end
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    if (MI_mark_all)
        if isempty(CurrentTitleSetDescriptorString)
            CurrentTitleSetDescriptorString = 'IDlabel';
        else
            CurrentTitleSetDescriptorString = [CurrentTitleSetDescriptorString, '.', 'IDlabel'];
        end
    end
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.', OutPutType]);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.', 'pdf']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.', 'fig']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    
    legend(legend_list, 'Interpreter', 'None', 'Box', 'off', 'Location', 'southwest');
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.legend.', OutPutType]);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.legend.', 'pdf']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.MIspaceCooordinates.legend.', 'fig']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
end

if (plot_AR_scatter_by_trainig_state)
    % for early and late macaques plot AR_late versus AR_early
    
    for i_group = 1 : n_groups
        current_group_label = group_struct_list{i_group}.setLabel;
        if ~ismember(current_group_label, {'Macaques_early', 'Macaques_late'})
            % nothing to do here
            continue
        end
        % collect the data lines for the current group
        current_group_data = metrics_by_group_list{i_group};
        % now collect the actual data of interest
        % averaged reward
        AVG_rewardA = current_group_data(:, coordination_metrics_table.cn.playerReward_A);
        AVG_rewardB = current_group_data(:, coordination_metrics_table.cn.playerReward_B);
        AVG_rewardAB = current_group_data(:, coordination_metrics_table.cn.averReward);
        
        if strcmp(current_group_label, 'Macaques_early')
           early_AVG_rewardAB = AVG_rewardAB;
        end
        if strcmp(current_group_label, 'Macaques_late')
           late_AVG_rewardAB = AVG_rewardAB;
        end
    end
    % create the plot
    FileName = CollectionName;
    Cur_fh_cAvgRewardScatter_for_naive_macaques = figure('Name', 'AverageReward early/ate scatter-plot', 'visible', figure_visibility_string);
    fnFormatDefaultAxes(DefaultAxesType);
    [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
    set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
    legend_list = {};
    hold on
    
    ScatterSymbolSize = 25;
    ScatterLineWidth = 0.75;
    ScatterMaker = 'o';
    current_scatter_color = group_struct_list{i_group}.color;
    %current_scatter_color = [0.5 0.5 0.5];
    x_list = early_AVG_rewardAB;
    y_list = late_AVG_rewardAB;
    
    scatter(x_list, y_list, ScatterSymbolSize, current_scatter_color, ScatterMaker, 'LineWidth', ScatterLineWidth);
    plot([0.9 3.6], [0.9 3.6], 'Color', [0.5 0.5 0.5], 'LineStyle', '--');
    axis equal
    xlabel('average reward early session', 'Interpreter', 'none');
    ylabel('average reward late session', 'Interpreter', 'none');
    %set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
    set(gca, 'Ylim', [0.9 3.6]);
    set(gca, 'XLim', [0.9 3.6]);
    
    hold off
    % save out the results
    current_group_label = 'naive_macaques';
    CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label];
    if ~strcmp(OutPutType, 'pdf')
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', OutPutType]);
        write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
    end
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', 'pdf']);
    write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardScatter.', 'fig']);
    write_out_figure(Cur_fh_cAvgRewardScatter_for_naive_macaques, outfile_fqn);
    
end



if (plot_blocked_confederate_data)
    for i_group = 1 : n_groups
        current_group_label = group_struct_list{i_group}.setLabel;
        cur_plot_coordination_metrics_for_each_group_graph_type = plot_coordination_metrics_for_each_group_graph_type;
        
        % here we only want to ook at the blocked experiments
        if ~ismember(current_group_label, {'ConfederateSMCuriusBlocked', 'ConfederateSMFlaffusBlocked'})
            continue
        end
        
        
        %if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'ConfederateTrainedMacaques'})
        if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'HumansOpaque', ...
                'Humans50_55__80_20', 'Humans50_50', 'GoodHumans', 'BadHumans'})
            cur_plot_coordination_metrics_for_each_group_graph_type = 'bar';
        else
            disp('Doh...');
        end
        
        
        % collect the data lines for the current group
        current_group_data = metrics_by_group_list{i_group};
        % now collect the actual data of interest
        
        error('Not impleented yet');
        
        
        % Share of Own Choices
        SOC_targetA = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_A);
        SOC_targetB = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_B);
        SOC_sideA = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_A);
        SOC_sideB = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_B);
        % Mutual Informatin
        MI_side = current_group_data(:, coordination_metrics_table.cn.miSide);
        MI_target = current_group_data(:, coordination_metrics_table.cn.miTarget);
        % averaged reward
        AVG_rewardA = current_group_data(:, coordination_metrics_table.cn.playerReward_A);
        AVG_rewardB = current_group_data(:, coordination_metrics_table.cn.playerReward_B);
        AVG_rewardAB = current_group_data(:, coordination_metrics_table.cn.averReward);
        % non-random reward component
        Non_random_reward = current_group_data(:, coordination_metrics_table.cn.dltReward);
        Non_random_reward_significance = current_group_data(:, coordination_metrics_table.cn.dltSignif);
        Non_random_reward_CI_lower = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Lower);
        Non_random_reward_CI_upper = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Upper);
        Non_random_reward_CI_hw = (Non_random_reward_CI_upper - Non_random_reward);
        
        % create the plot
        FileName = CollectionName;
        Cur_fh_coordination_metrics_for_each_group = figure('Name', 'Coordination Metrics plot', 'visible', figure_visibility_string);
        fnFormatDefaultAxes(DefaultAxesType);
        [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
        legend_list = {};
        %hold on
        
        % SOC target
        current_axis_h = subplot(2, 3, 1);
        x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
        y_vec_arr = [SOC_targetA, SOC_targetB];
        instance_list = {'SOC_targetA', 'SOC_targetB'};
        color_list = {[1,0,0], [0,0,1]};
        symbol_list = {'o', 's'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Share of Own Choices', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % SOC side
        current_axis_h = subplot(2, 3, 2);
        x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
        y_vec_arr = [SOC_sideA, SOC_sideB];
        instance_list = {'SOC_sideA', 'SOC_sideB'};
        color_list = {[1,0,0], [0,0,1]};
        symbol_list = {'o', 's'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Share of obj. left Choices', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        
        % AVG reward
        current_axis_h = subplot(2, 3, 3);
        x_vec_arr = [(1:1:length(AVG_rewardA));(1:1:length(AVG_rewardAB)); (1:1:length(AVG_rewardB)); ]';
        y_vec_arr = [AVG_rewardA, AVG_rewardAB, AVG_rewardB];
        instance_list = {'AVG_rewardA', 'AVG_rewardAB', 'AVG_rewardB'};
        color_list = {[1,0,0], [0.5,0,0.5], [0,0,1]};
        symbol_list = {'o', 'none', 's'};
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Average reward', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0.9 4.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % MI target
        current_axis_h = subplot(2, 3, 4);
        x_vec_arr = [(1:1:length(MI_target))]';
        y_vec_arr = [MI_target];
        instance_list = {'MI_target'};
        color_list = {[0.5,0,0.5]};
        symbol_list = {'d'};
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('MI target', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % MI side
        current_axis_h = subplot(2, 3, 5);
        x_vec_arr = [(1:1:length(MI_side))]';
        y_vec_arr = [MI_side];
        instance_list = {'MI_side'};
        color_list = {[0.5,0,0.5]};
        symbol_list = {'d'};
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('MI side', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % non-random reward
        current_axis_h = subplot(2, 3, 6);
        x_vec_arr = [(1:1:length(Non_random_reward))]';
        y_vec_arr = [Non_random_reward];
        instance_list = {'Non_random_reward'};
        color_list = {[0.5,0,0.5]};
        symbol_list = {'d'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0 0], 'Color', [0 0 0], 'Marker', 'none');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Non-random reward', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [-0.2 1.2]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        % add the CI
        hold on
        errorbar(x_vec_arr, y_vec_arr, Non_random_reward_CI_hw, 'LineStyle', 'none', 'Color', [0,0,0], 'LineWidth', 1.0);
        hold off
        
        
        % save out the results
        current_group_name = group_struct_list{i_group}.setName;
        CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label, '.', cur_plot_coordination_metrics_for_each_group_graph_type];
        if ~strcmp(OutPutType, 'pdf')
            outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', OutPutType]);
            write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        end
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'pdf']);
        write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'fig']);
        write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        
        %         legend(legend_list, 'Interpreter', 'None');
        %         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', OutPutType]);
        %         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        %         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'pdf']);
        %         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        %         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'fig']);
        %         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
    end
end
%
if (plot_coordination_metrics_for_each_group)
    for i_group = 1 : n_groups
        current_group_label = group_struct_list{i_group}.setLabel;
        cur_plot_coordination_metrics_for_each_group_graph_type = plot_coordination_metrics_for_each_group_graph_type;
        
        % here we only want to ook at the blocked experiments
        if ismember(current_group_label, {'ConfederateSMCuriusBlocked', 'ConfederateSMFlaffusBlocked'})
            continue
        end
        
        %if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late', 'ConfederateTrainedMacaques'})
        if ismember(current_group_label, {'Humans', 'Macaques_early', 'Macaques_late', 'ConfederatesMacaques_early', 'ConfederatesMacaques_late'})
            cur_plot_coordination_metrics_for_each_group_graph_type = 'bar';
        else
            disp('Doh...');
        end
        
        
        % collect the data lines for the current group
        current_group_data = metrics_by_group_list{i_group};
        % now collect the actual data of interest
        % Share of Own Choices
        SOC_targetA = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_A);
        SOC_targetB = current_group_data(:, coordination_metrics_table.cn.shareOwnChoices_B);
        SOC_sideA = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_A);
        SOC_sideB = current_group_data(:, coordination_metrics_table.cn.shareLeftChoices_B);
        % Mutual Informatin
        MI_side = current_group_data(:, coordination_metrics_table.cn.miSide);
        MI_target = current_group_data(:, coordination_metrics_table.cn.miTarget);
        % averafed reward
        AVG_rewardA = current_group_data(:, coordination_metrics_table.cn.playerReward_A);
        AVG_rewardB = current_group_data(:, coordination_metrics_table.cn.playerReward_B);
        AVG_rewardAB = current_group_data(:, coordination_metrics_table.cn.averReward);
        % non-random reward component
        Non_random_reward = current_group_data(:, coordination_metrics_table.cn.dltReward);
        Non_random_reward_significance = current_group_data(:, coordination_metrics_table.cn.dltSignif);
        Non_random_reward_CI_lower = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Upper);
        Non_random_reward_CI_upper = current_group_data(:, coordination_metrics_table.cn.dltConfInterval_Lower);
        Non_random_reward_CI_hw = (Non_random_reward_CI_upper - Non_random_reward);
        
        % create the plot
        FileName = CollectionName;
        Cur_fh_coordination_metrics_for_each_group = figure('Name', 'Coordination Metrics plot', 'visible', figure_visibility_string);
        fnFormatDefaultAxes(DefaultAxesType);
        [output_rect] = fnFormatPaperSize(DefaultPaperSizeType, gcf, output_rect_fraction);
        set(gcf(), 'Units', 'centimeters', 'Position', output_rect, 'PaperPosition', output_rect);
        legend_list = {};
        %hold on
        
        % SOC target
        current_axis_h = subplot(2, 3, 1);
        x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
        y_vec_arr = [SOC_targetA, SOC_targetB];
        instance_list = {'SOC_targetA', 'SOC_targetB'};
        color_list = {[1,0,0], [0,0,1]};
        symbol_list = {'o', 's'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Share of Own Choices', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % SOC side
        current_axis_h = subplot(2, 3, 2);
        x_vec_arr = [(1:1:length(SOC_sideA)); (1:1:length(SOC_sideB))]';
        y_vec_arr = [SOC_sideA, SOC_sideB];
        instance_list = {'SOC_sideA', 'SOC_sideB'};
        color_list = {[1,0,0], [0,0,1]};
        symbol_list = {'o', 's'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0.5 0.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Share of obj. left Choices', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        
        % AVG reward
        current_axis_h = subplot(2, 3, 3);
        x_vec_arr = [(1:1:length(AVG_rewardA));(1:1:length(AVG_rewardAB)); (1:1:length(AVG_rewardB)); ]';
        y_vec_arr = [AVG_rewardA, AVG_rewardAB, AVG_rewardB];
        instance_list = {'AVG_rewardA', 'AVG_rewardAB', 'AVG_rewardB'};
        color_list = {[1,0,0], [0.5,0,0.5], [0,0,1]};
        symbol_list = {'o', 'none', 's'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [3.5 3.5], 'Color', [0 0 0], 'Marker', 'none', 'LineStyle', '--');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Average reward', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0.9 4.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % MI target
        current_axis_h = subplot(2, 3, 4);
        x_vec_arr = [(1:1:length(MI_target))]';
        y_vec_arr = [MI_target];
        instance_list = {'MI_target'};
        color_list = {[0.5,0,0.5]};
        symbol_list = {'d'};
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('MI target', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % MI side
        current_axis_h = subplot(2, 3, 5);
        x_vec_arr = [(1:1:length(MI_side))]';
        y_vec_arr = [MI_side];
        instance_list = {'MI_side'};
        color_list = {[0.5,0,0.5]};
        symbol_list = {'d'};
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('MI side', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [0 1.1]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        
        % non-random reward
        current_axis_h = subplot(2, 3, 6);
        x_vec_arr = [(1:1:length(Non_random_reward))]';
        y_vec_arr = [Non_random_reward];
        instance_list = {'Non_random_reward'};
        color_list = {[0.5,0,0.5]};
        symbol_list = {'d'};
        plot([(0.2) (size(x_vec_arr, 1)+0.9)], [0 0], 'Color', [0 0 0], 'Marker', 'none');
        [current_axis_h] = fn_plot_type_to_axis(current_axis_h, cur_plot_coordination_metrics_for_each_group_graph_type, x_vec_arr, y_vec_arr, color_list, symbol_list);
        % label the axes
        ylabel('Non-random reward', 'Interpreter', 'none');
        xlabel('Session ID', 'Interpreter', 'none');
        set(gca, 'XTick', (1:1:size(x_vec_arr, 1)), 'xTickLabel', group_struct_list{i_group}.Captions, 'XTickLabelRotation', XLabelRotation_degree, 'TickLabelInterpreter', 'none');
        set(gca, 'Ylim', [-0.2 1.2]);
        set(gca, 'XLim', [(0.2) (size(x_vec_arr, 1)+0.9)]);
        % add the CI
        hold on
        errorbar(x_vec_arr, y_vec_arr, Non_random_reward_CI_hw, 'LineStyle', 'none', 'Color', [0,0,0], 'LineWidth', 1.0);
        hold off
        
        
        % save out the results
        current_group_name = group_struct_list{i_group}.setName;
        CurrentTitleSetDescriptorString = [TitleSetDescriptorString, '.', current_group_label, '.', cur_plot_coordination_metrics_for_each_group_graph_type];
        if ~strcmp(OutPutType, 'pdf')
            outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', OutPutType]);
            write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        end
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'pdf']);
        write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.', 'fig']);
        write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        
        %         legend(legend_list, 'Interpreter', 'None');
        %         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', OutPutType]);
        %         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        %         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'pdf']);
        %         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        %         outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.CoordinationMetrics.legend.', 'fig']);
        %         write_out_figure(Cur_fh_coordination_metrics_for_each_group, outfile_fqn);
        
    end
end

% close all figues?
if (close_figures_at_end)
    close all;
end

% how long did it take?
timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end

function [ output_rect ] = fnFormatPaperSize( type, gcf_h, fraction, do_center_in_paper )
%FNFORMATPAPERSIZE Set the paper size for a plot, also return a reasonably
%tight output_rect.
% 20070827sm: changed default output formatting to allow pretty paper output
% Example usage:
%     Cur_fh = figure('Name', 'Test');
%     fnFormatDefaultAxes('16to9slides');
%     [output_rect] = fnFormatPaperSize('16to9landscape', gcf);
%     set(gcf(), 'Units', 'centimeters', 'Position', output_rect);


if nargin < 3
    fraction = 1;	% fractional columns?
end
if nargin < 4
    do_center_in_paper = 0;	% center the rectangle in the page
end


nature_single_col_width_cm = 8.9;
nature_double_col_width_cm = 18.3;
nature_full_page_width_cm = 24.7;

A4_w_cm = 21.0;
A4_h_cm = 29.7;
% defaults
left_edge_cm = 1;
bottom_edge_cm = 2;

switch type
    
    case {'PrimateNeurobiology2018DPZ0.5', 'SfN2018.5'}
        left_edge_cm = 0.05;
        bottom_edge_cm = 0.05;
        dpz_column_width_cm = 38.6 * 0.5 * 0.8;   % the columns are 38.6271mm, but the imported pdf in illustrator are too large (0.395)
        rect_w = (dpz_column_width_cm - 2*left_edge_cm) * fraction;
        rect_h = ((dpz_column_width_cm * 610/987) - 2*bottom_edge_cm) * fraction; % 610/987 approximates the golden ratio
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm*fraction rect_h+2*bottom_edge_cm*fraction], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
        
        
    case 'PrimateNeurobiology2018DPZ'
        left_edge_cm = 0.05;
        bottom_edge_cm = 0.05;
        dpz_column_width_cm = 38.6 * 0.8;   % the columns are 38.6271mm, but the imported pdf in illustrator are too large (0.395)
        rect_w = (dpz_column_width_cm - 2*left_edge_cm) * fraction;
        rect_h = ((dpz_column_width_cm * 610/987) - 2*bottom_edge_cm) * fraction; % 610/987 approximates the golden ratio
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm*fraction rect_h+2*bottom_edge_cm*fraction], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
    case 'DPZ2017Evaluation'
        left_edge_cm = 0.05;
        bottom_edge_cm = 0.05;
        dpz_column_width_cm = 34.7 * 0.8;   % the columns are 347, 350, 347 mm, but the imported pdf in illustrator are too large (0.395)
        rect_w = (dpz_column_width_cm - 2*left_edge_cm) * fraction;
        rect_h = ((dpz_column_width_cm * 610/987) - 2*bottom_edge_cm) * fraction; % 610/987 approximates the golden ratio
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm*fraction rect_h+2*bottom_edge_cm*fraction], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
        
    case '16to9portrait'
        left_edge_cm = 1;
        bottom_edge_cm = 1;
        rect_w = (9 - 2*left_edge_cm) * fraction;
        rect_h = (16 - 2*bottom_edge_cm) * fraction;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm rect_h+2*bottom_edge_cm], 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters');
        
    case '16to9landscape'
        left_edge_cm = 1;
        bottom_edge_cm = 1;
        rect_w = (16 - 2*left_edge_cm) * fraction;
        rect_h = (9 - 2*bottom_edge_cm) * fraction;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        set(gcf_h, 'PaperSize', [rect_w+2*left_edge_cm rect_h+2*bottom_edge_cm], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
    case 'ms13_paper'
        rect_w = nature_single_col_width_cm * fraction;
        rect_h = nature_single_col_width_cm * fraction;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        %set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        % try to manage plots better
        set(gcf_h, 'PaperSize', [rect_w rect_h], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
    case 'ms13_paper_unitdata'
        rect_w = nature_single_col_width_cm * fraction;
        rect_h = nature_single_col_width_cm * fraction;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        % configure the format PaperPositon [left bottom width height]
        %set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        set(gcf_h, 'PaperSize', [rect_w rect_h], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
    case 'ms13_paper_unitdata_halfheight'
        rect_w = nature_single_col_width_cm * fraction;
        rect_h = nature_single_col_width_cm * fraction * 0.5;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        % configure the format PaperPositon [left bottom width height]
        %set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        set(gcf_h, 'PaperSize', [rect_w rect_h], 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters');
        
        
    case 'fp_paper'
        rect_w = 4.5 * fraction;
        rect_h = 1.835 * fraction;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_w_cm - rect_w) * 0.5;
            bottom_edge_cm = (A4_h_cm - rect_h) * 0.5;
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        % configure the format PaperPositon [left bottom width height]
        set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'sfn_poster'
        rect_w = 27.7 * fraction;
        rect_h = 12.0 * fraction;
        % configure the format PaperPositon [left bottom width height]
        if (do_center_in_paper)
            left_edge_cm = (A4_h_cm - rect_w) * 0.5;	% landscape!
            bottom_edge_cm = (A4_w_cm - rect_h) * 0.5;	% landscape!
        end
        output_rect = [left_edge_cm bottom_edge_cm rect_w rect_h];	% left, bottom, width, height
        %output_rect = [1.0 2.0 27.7 12.0];	% full width
        % configure the format PaperPositon [left bottom width height]
        set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'sfn_poster_0.5'
        output_rect = [1.0 2.0 (25.9/2) 8.0];	% half width
        output_rect = [1.0 2.0 11.0 10.0];	% height was (25.9/2)
        % configure the format PaperPositon [left bottom width height]
        %set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'sfn_poster_0.5_2012'
        output_rect = [1.0 2.0 (25.9/2) 8.0];	% half width
        output_rect = [1.0 2.0 11.0 9.0];	% height was (25.9/2)
        % configure the format PaperPositon [left bottom width height]
        %set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'europe'
        output_rect = [1.0 2.0 27.7 12.0];
        set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'europe_portrait'
        output_rect = [1.0 2.0 20.0 27.7];
        set(gcf_h, 'PaperType', 'A4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'default'
        % letter 8.5 x 11 ", or 215.9 mm ? 279.4 mm
        output_rect = [1.0 2.0 19.59 25.94];
        set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    case 'default_portrait'
        output_rect = [1.0 2.0 25.94 19.59];
        set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
    otherwise
        output_rect = [1.0 2.0 25.9 12.0];
        set(gcf_h, 'PaperType', 'usletter', 'PaperOrientation', 'landscape', 'PaperUnits', 'centimeters', 'PaperPosition', output_rect);
        
end

return
end


function [ group_struct_list ] = fn_get_session_group( group_collection_name )
group_struct_list = [];

switch group_collection_name
    case {'oxford2018', 'sfn2018', 'SfN2018', 'BoS_human_monkey_2019'}
        % define the session sets:
        % Oxford, SfN2018
        
        HumansOpaque.setName = 'Humans opaque';
        HumansOpaque.setLabel = 'HumansOpaque';
        HumansOpaque.label = {'Humans', 'Opaque', ''};
        HumansOpaque.filenames = {...            
            'DATA_20170425T160951.A_21001.B_22002.SCP_00.triallog.A.21001.B.22002_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20170426T102304.A_21003.B_22004.SCP_00.triallog.A.21003.B.22004_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20170426T133343.A_21005.B_12006.SCP_00.triallog.A.21005.B.12006_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20170427T092352.A_21007.B_12008.SCP_00.triallog.A.21007.B.12008_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20170427T132036.A_21009.B_12010.SCP_00.triallog.A.21009.B.12010_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        HumansOpaque.Captions = {...
            '01vs02', ...
            '03vs04', ...
            '05vs06', ...
            '07vs08', ...
            '09vs10', ...
            };
        HumansOpaque.color = ([142 205 253]/255);
        HumansOpaque.Symbol = 'd';
        HumansOpaque.FilledSymbols = 1;

        Humans.setName = 'Humans';
        Humans.setLabel = 'Humans';
        Humans.label = {'Humans', '', ''};
        Humans.filenames = {...
            'DATA_20171113T162815.A_20011.B_10012.SCP_01.triallog.A.20011.B.10012_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171115T165545.A_20013.B_10014.SCP_01.triallog.A.20013.B.10014_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171116T164137.A_20015.B_10016.SCP_01.triallog.A.20015.B.10016_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171121T165717.A_10018.B_20017.SCP_01.triallog.A.10018.B.20017_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171123T165158.A_20019.B_10020.SCP_01.triallog.A.20019.B.10020_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171127T164730.A_20021.B_20022.SCP_01.triallog.A.20021.B.20022_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171128T165159.A_20024.B_10023.SCP_01.triallog.A.20024.B.10023_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171130T145412.A_20025.B_20026.SCP_01.triallog.A.20025.B.20026_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171130T164300.A_20027.B_10028.SCP_01.triallog.A.20027.B.10028_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171205T163542.A_20029.B_10030.SCP_01.triallog.A.20029.B.10030_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        Humans.Captions = {...
            '11vs12', ...
            '13vs14', ...
            '15vs16', ...
            '18vs17', ...
            '19vs20', ...
            '21vs22', ...
            '24vs23', ...
            '25vs26', ...
            '27vs28', ...
            '29vs30', ...
            };
        Humans.color = ([142 205 253]/255);
        Humans.Symbol = 's';
        Humans.FilledSymbols = 1;

        % excluded: 'DATA_20171113T162815.A_20011.B_10012.SCP_01.triallog.A.20011.B.10012_IC_JointTrials.isOwnChoice_sideChoice', ...
        % no solo training
        HumansTransparent.setName = 'Humans transparent';
        HumansTransparent.setLabel = 'HumansTransparent';
        HumansTransparent.label = {'Humans', '', ''};
        HumansTransparent.filenames = {...
            'DATA_20171115T165545.A_20013.B_10014.SCP_01.triallog.A.20013.B.10014_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171116T164137.A_20015.B_10016.SCP_01.triallog.A.20015.B.10016_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171121T165717.A_10018.B_20017.SCP_01.triallog.A.10018.B.20017_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171123T165158.A_20019.B_10020.SCP_01.triallog.A.20019.B.10020_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171127T164730.A_20021.B_20022.SCP_01.triallog.A.20021.B.20022_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171128T165159.A_20024.B_10023.SCP_01.triallog.A.20024.B.10023_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171130T145412.A_20025.B_20026.SCP_01.triallog.A.20025.B.20026_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171130T164300.A_20027.B_10028.SCP_01.triallog.A.20027.B.10028_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171205T163542.A_20029.B_10030.SCP_01.triallog.A.20029.B.10030_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181030T155123.A_181030ID0061S1.B_181030ID0062S1.SCP_01.triallog.A.181030ID0061S1.B.181030ID0062S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T135826.A_181031ID63S1.B_181031ID64S1.SCP_01.triallog.A.181031ID63S1.B.181031ID64S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T170224.A_181031ID65S1.B_181031ID66S1.SCP_01.triallog.A.181031ID65S1.B.181031ID66S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181101T133927.A_181101ID67S1.B_181101ID68S1.SCP_01.triallog.A.181101ID67S1.B.181101ID68S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181102T131833.A_181102ID69S1.B_181102ID70S1.SCP_01.triallog.A.181102ID69S1.B.181102ID70S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        HumansTransparent.Captions = {...
            '13vs14', ...
            '15vs16', ...
            '18vs17', ...
            '19vs20', ...
            '21vs22', ...
            '24vs23', ...
            '25vs26', ...
            '27vs28', ...
            '29vs30', ...
            '61v62_50', ...
            '63v64_50', ...
            '65v66_50', ...
            '67v68_50', ...
            '69v70_50', ...
            };
        HumansTransparent.color = ([142 205 253]/255);
        HumansTransparent.Symbol = 's';
        HumansTransparent.FilledSymbols = 1;        
        
        Humans50_55__80_20.setName = 'Humans 50_55 80_20';
        Humans50_55__80_20.setLabel = 'Humans50_55__80_20';
        Humans50_55__80_20.label = {'Humans', '', ''};
        Humans50_55__80_20.filenames = {...        
            'DATA_20181030T155123.A_181030ID0061S1.B_181030ID0062S1.SCP_01.triallog.A.181030ID0061S1.B.181030ID0062S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181030T164218.A_181030ID0061S1.B_181030ID0062S1.SCP_01.triallog.A.181030ID0061S1.B.181030ID0062S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T135826.A_181031ID63S1.B_181031ID64S1.SCP_01.triallog.A.181031ID63S1.B.181031ID64S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T144100.A_181031ID63S1.B_181031ID64S1.SCP_01.triallog.A.181031ID63S1.B.181031ID64S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T170224.A_181031ID65S1.B_181031ID66S1.SCP_01.triallog.A.181031ID65S1.B.181031ID66S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T175346.A_181031ID65S1.B_181031ID66S1.SCP_01.triallog.A.181031ID65S1.B.181031ID66S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181101T133927.A_181101ID67S1.B_181101ID68S1.SCP_01.triallog.A.181101ID67S1.B.181101ID68S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181101T142430.A_181101ID67S1.B_181101ID68S1.SCP_01.triallog.A.181101ID67S1.B.181101ID68S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181102T131833.A_181102ID69S1.B_181102ID70S1.SCP_01.triallog.A.181102ID69S1.B.181102ID70S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181102T135956.A_181102ID69S1.B_181102ID70S1.SCP_01.triallog.A.181102ID69S1.B.181102ID70S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
         Humans50_55__80_20.Captions = {...
            '81030_50', ...
            '81030_80', ...
            '81031_50', ...
            '81031_80', ...
            '81031_50', ...
            '81031_80', ...
            '81101_50', ...
            '81101_80', ...
            '81102_50', ...
            '81102_80', ...
            };
        Humans50_55__80_20.color = ([142 205 253]/255);
        Humans50_55__80_20.Symbol = '+';
        Humans50_55__80_20.FilledSymbols = 0;       
 
        Humans50_50.setName = 'Humans';
        Humans50_50.setLabel = 'Humans50_50';
        Humans50_50.label = {'Humans', '', ''};
        Humans50_50.filenames = {...        
            'DATA_20181030T155123.A_181030ID0061S1.B_181030ID0062S1.SCP_01.triallog.A.181030ID0061S1.B.181030ID0062S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T135826.A_181031ID63S1.B_181031ID64S1.SCP_01.triallog.A.181031ID63S1.B.181031ID64S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T170224.A_181031ID65S1.B_181031ID66S1.SCP_01.triallog.A.181031ID65S1.B.181031ID66S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181101T133927.A_181101ID67S1.B_181101ID68S1.SCP_01.triallog.A.181101ID67S1.B.181101ID68S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181102T131833.A_181102ID69S1.B_181102ID70S1.SCP_01.triallog.A.181102ID69S1.B.181102ID70S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
         Humans50_50.Captions = {...
            '81030_50', ...
            '81031_50', ...
            '81031_50', ...
            '81101_50', ...
            '81102_50', ...
            };
        Humans50_50.color = ([142 205 253]/255) * 1/5;
        Humans50_50.color = ([142 205 253]/255) ;
        Humans50_50.Symbol = 'v';
        Humans50_50.FilledSymbols = 0;    

        % these are selected on the basis of havin understood the color to
        % value associations, either from solo training or from later joint
        % trials
        GoodHumans.setName = 'GoodHumans';
        GoodHumans.setLabel = 'GoodHumans';
        GoodHumans.label = {'Humans', '', ''};
        GoodHumans.filenames = {...
            'DATA_20171116T164137.A_20015.B_10016.SCP_01.triallog.A.20015.B.10016_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171123T165158.A_20019.B_10020.SCP_01.triallog.A.20019.B.10020_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171127T164730.A_20021.B_20022.SCP_01.triallog.A.20021.B.20022_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171128T165159.A_20024.B_10023.SCP_01.triallog.A.20024.B.10023_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171130T164300.A_20027.B_10028.SCP_01.triallog.A.20027.B.10028_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171205T163542.A_20029.B_10030.SCP_01.triallog.A.20029.B.10030_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181030T155123.A_181030ID0061S1.B_181030ID0062S1.SCP_01.triallog.A.181030ID0061S1.B.181030ID0062S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T170224.A_181031ID65S1.B_181031ID66S1.SCP_01.triallog.A.181031ID65S1.B.181031ID66S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181101T133927.A_181101ID67S1.B_181101ID68S1.SCP_01.triallog.A.181101ID67S1.B.181101ID68S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181102T131833.A_181102ID69S1.B_181102ID70S1.SCP_01.triallog.A.181102ID69S1.B.181102ID70S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        GoodHumans.Captions = {...
            '15vs16', ...
            '19vs20', ...
            '21vs22', ...
            '24vs23', ...
            '27vs28', ...
            '29vs30', ...
            '81030_50', ...
            '81031_50', ...
            '81101_50', ...
            '81102_50', ...
            };
        GoodHumans.color = ([142 205 253]/255) * 1/5;
        GoodHumans.Symbol = '+';
        GoodHumans.FilledSymbols = 0;        
        
      
        BadHumans.setName = 'BadHumans';
        BadHumans.setLabel = 'BadHumans';
        BadHumans.label = {'BadHumans', '', ''};
        BadHumans.filenames = {...
            'DATA_20171113T162815.A_20011.B_10012.SCP_01.triallog.A.20011.B.10012_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171115T165545.A_20013.B_10014.SCP_01.triallog.A.20013.B.10014_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171121T165717.A_10018.B_20017.SCP_01.triallog.A.10018.B.20017_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171130T145412.A_20025.B_20026.SCP_01.triallog.A.20025.B.20026_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181031T135826.A_181031ID63S1.B_181031ID64S1.SCP_01.triallog.A.181031ID63S1.B.181031ID64S1_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        BadHumans.Captions = {...
            '11vs12', ...
            '13vs14', ...
            '18vs17', ...
            '25vs26', ...
            '81031_50', ...
            };
        BadHumans.color = [1 0 0]; %([142 205 253]/255) * 1/5;
        BadHumans.Symbol = '+';
        BadHumans.FilledSymbols = 0;        
        
        
        Macaques_early.setName = 'Macaques early';
        Macaques_early.setLabel = 'Macaques_early';
        Macaques_early.label = {'Macaques', 'early', ''};
        Macaques_early.filenames = {...
            'DATA_20181127T122556.A_Curius.B_Linus.SCP_01.triallog.A.Curius.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180516T090940.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180504T114516.A_Tesla.B_Flaffus.SCP_01.triallog.A.Tesla.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180525T091512.A_Tesla.B_Curius.SCP_01.triallog.A.Tesla.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180605T091549.A_Curius.B_Elmo.SCP_01.triallog.A.Curius.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171108T140407.A_Magnus.B_Curius.SCP_01.triallog.A.Magnus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171019T132932.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171129T100056.A_Magnus.B_Flaffus.SCP_01.triallog.A.Magnus.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        Macaques_early.Captions = { ...
            'C.L', ...
            'T.E', ...
            'T.F', ...
            'T.C', ...
            'C.E', ...
            'M.C', ...
            'F.C', ...
            'M.F', ...
            };
        Macaques_early.color = [253 178 143]/255;
        Macaques_early.Symbol = 'o';
        Macaques_early.FilledSymbols = 0;
        
        % exchanged DATA_20180531T104356.A_Tesla.B_Curius.SCP_01.triallog.A.Tesla.B.Curius_IC_JointTrials.isOwnChoice_sideChoice
        % with
        % DATA_20180530T153325.A_Tesla.B_Curius.SCP_01.triallog.A.Tesla.B.Curius_IC_JointTrials.isOwnChoice_sideChoice,
        % as the former only has ~120 trials while the latter has 250 
        % exchanged DATA_20171107T131228.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice
        % with DATA_20171103T143324.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice
        % the latter has a change of effector hand that interferred with
        % behavior
        Macaques_late.setName = 'Macaques transparent';
        Macaques_late.setLabel = 'Macaques_late';
        Macaques_late.label = {'Macaques', 'late', ''};
        Macaques_late.filenames = {...
            'DATA_20181211T134136.A_Curius.B_Linus.SCP_01.triallog.A.Curius.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180524T103704.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180509T122330.A_Tesla.B_Flaffus.SCP_01.triallog.A.Tesla.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180530T153325.A_Tesla.B_Curius.SCP_01.triallog.A.Tesla.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180615T111344.A_Curius.B_Elmo.SCP_01.triallog.A.Curius.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180214T171119.A_Magnus.B_Curius.SCP_01.triallog.A.Magnus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171103T143324.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180125T155742.A_Magnus.B_Flaffus.SCP_01.triallog.A.Magnus.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        Macaques_late.Captions = { ...
            'C.L', ...
            'T.E', ...
            'T.F', ...
            'T.C', ...
            'C.E', ...
            'M.C', ...
            'F.C', ...
            'M.F', ...
            };
        Macaques_late.color = [192 157 169]/255;
        Macaques_late.Symbol = 'o';
        Macaques_late.FilledSymbols = 1;
        
        
        ConfederatesMacaques_early.setName = 'Confederates-macaques early';
        ConfederatesMacaques_early.setLabel = 'ConfederatesMacaques_early';
        ConfederatesMacaques_early.label = {'Confederates', 'macaques', 'early'};
        ConfederatesMacaques_early.filenames = {...
            'DATA_20171206T141710.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180131T155005.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180620T095959.A_JK.B_Elmo.SCP_01.triallog.A.JK.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180601T122747.A_Tesla.B_SM.SCP_01.triallog.A.Tesla.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederatesMacaques_early.Captions = { ...
            'Conf.C',...
            'Conf.F',...
            'Conf.E',...
            'T.Conf',...
            };
        ConfederatesMacaques_early.color = [253 178 143]/255;
        ConfederatesMacaques_early.Symbol = 's';
        ConfederatesMacaques_early.FilledSymbols = 1;
        
        
        ConfederatesMacaques_late.setName = 'Confederates-macaques late';
        ConfederatesMacaques_late.setLabel = 'ConfederatesMacaques_late';
        ConfederatesMacaques_late.label = {'Confederates', 'macaques', 'late'};
        ConfederatesMacaques_late.filenames = {...
            'DATA_20180423T162330.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180228T132647.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederatesMacaques_late.Captions = { ...
            'Conf.C',...
            'Conf.F',...
            };
        ConfederatesMacaques_late.color = [192 157 169]/255;
        ConfederatesMacaques_late.Symbol = 's';
        ConfederatesMacaques_late.FilledSymbols = 1;
        
        
        ConfederateTrainedMacaques.setName = 'Confederate-trained macaques';
        ConfederateTrainedMacaques.setLabel = 'ConfederateTrainedMacaques';
        ConfederateTrainedMacaques.label = {'Confederate', 'trained', 'macaques'};
        ConfederateTrainedMacaques.filenames = {...
            'DATA_20180418T143951.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180424T121937.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180425T133936.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180426T171117.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180427T142541.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateTrainedMacaques.Captions = { ...
            '80418',...
            '80419', ...
            '80424', ...
            '80425', ...
            '80426', ...
            '80427', ...
            };
        ConfederateTrainedMacaques.color = [128 73 142]/255;
        ConfederateTrainedMacaques.Symbol = 'd';
        ConfederateTrainedMacaques.FilledSymbols = 0;
        
        ConfederateTrainedMacaquesBest.setName = 'Confederate-trained macaques';
        ConfederateTrainedMacaquesBest.setLabel = 'ConfederateTrainedMacaquesBest';
        ConfederateTrainedMacaquesBest.label = {'Confederate', 'trained', 'macaques'};
        ConfederateTrainedMacaquesBest.filenames = {...
            'DATA_20180419T141311.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateTrainedMacaquesBest.Captions = { ...
            '80419', ...
            };
        ConfederateTrainedMacaquesBest.color = [128 73 142]/255;
        ConfederateTrainedMacaquesBest.Symbol = 'h';
        ConfederateTrainedMacaquesBest.FilledSymbols = 1;

        
        
        ConfederateSMCurius.setName = 'Confederate Curius';
        ConfederateSMCurius.setLabel = 'ConfederateCurius';
        ConfederateSMCurius.label = {'Confederate', 'trained', 'Curius'};
        ConfederateSMCurius.filenames = {...
            'DATA_20171206T141710.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171208T140548.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171211T110911.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171212T104819.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180111T130920.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180112T103626.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180118T120304.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180423T162330.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateSMCurius.Captions = {...
            '71206', ...
            '71208', ...
            '71211', ...
            '71212', ...
            '80111', ...
            '80112', ...
            '80118', ...
            '80423', ...
            };
        ConfederateSMCurius.color = [192 157 169]/255;
        ConfederateSMCurius.Symbol = 'none';
        ConfederateSMCurius.FilledSymbols = 1;
        
        
        ConfederateSMCuriusBlocked.setName = 'Confederate Curius Blocked';
        ConfederateSMCuriusBlocked.setLabel = 'ConfederateSMCuriusBlocked';
        ConfederateSMCuriusBlocked.label = {'Confederate', 'trained', 'Curius'};
        ConfederateSMCuriusBlocked.filenames = {...
            'DATA_20171213T112521.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171215T122633.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171221T135010.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171222T104137.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180119T123000.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180123T132012.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180124T141322.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180125T140345.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180126T132629.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...'
            };
        ConfederateSMCuriusBlocked.Captions = {...
            '71213', ...
            '71215', ...
            '71221', ...
            '71222', ...
            '80119', ...
            '80123', ...
            '80124', ...
            '80125', ...
            '80126'...
            };
        ConfederateSMCuriusBlocked.color = [192 157 169]/255;
        ConfederateSMCuriusBlocked.Symbol = 'none';
        ConfederateSMCuriusBlocked.FilledSymbols = 1;
        
        
        ConfederateSMFlaffus.setName = 'Confederate Flaffus';
        ConfederateSMFlaffus.setLabel = 'ConfederateFlaffus';
        ConfederateSMFlaffus.label = {'Confederate', 'trained', 'Flaffus'};
        ConfederateSMFlaffus.filenames = {...
            'DATA_20180131T155005.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180201T162341.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180202T144348.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180205T122214.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180209T145624.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180213T133932.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180214T141456.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180215T131327.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180216T140913.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180220T133215.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180221T133419.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180222T121106.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180223T143339.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180227T151756.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180228T132647.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateSMFlaffus.Captions = {...
            '80131', ...
            '80201', ...
            '80202', ...
            '80205', ...
            '80209', ...
            '80213', ...
            '80214', ...
            '80215', ...
            '80216', ...
            '80220', ...
            '80221', ...
            '80222', ...
            '80223', ...
            '80227', ...
            '80228', ...
            };
        ConfederateSMFlaffus.color = [192 157 169]/255;
        ConfederateSMFlaffus.Symbol = 'none';
        ConfederateSMFlaffus.FilledSymbols = 1;
        
        
        ConfederateSMFlaffusBlocked.setName = 'Confederate Flaffus Blocked';
        ConfederateSMFlaffusBlocked.setLabel = 'ConfederateSMFlaffusBlocked';
        ConfederateSMFlaffusBlocked.label = {'Confederate', 'trained', 'Flaffus'};
        ConfederateSMFlaffusBlocked.filenames = {...
            'DATA_20180301T122505.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180302T151740.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180306T112342.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180307T100718.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180308T121753.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180309T110024.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateSMFlaffusBlocked.Captions = {...
            '80301', ...
            '80302', ...
            '80306', ...
            '80307', ...
            '80308', ...
            '80309' ...
            };
        ConfederateSMFlaffusBlocked.color = [192 157 169]/255;
        ConfederateSMFlaffusBlocked.Symbol = 'none';
        ConfederateSMFlaffusBlocked.FilledSymbols = 1;
        
        
        % sets for the CNL retreat 2018
        teslaElmoNaive.setName = 'TeslaElmoNaive';
        teslaElmoNaive.setLabel = 'Tesla Elmo Naive';
        teslaElmoNaive.label = {'Tesla', 'naive', 'Elmo'};
        teslaElmoNaive.filenames = {...
            'DATA_20180516T090940.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180517T085104.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180518T104104.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180522T101558.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180523T092531.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180524T103704.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        teslaElmoNaive.Captions = {...
            '80516', ...
            '80517', ...
            '80518', ...
            '80522', ...
            '80523', ...
            '80524', ...
            };
        teslaElmoNaive.color = [192 157 169]/255;
        teslaElmoNaive.Symbol = 'none';
        teslaElmoNaive.FilledSymbols = 1;
        
        
        FlaffusCuriusNaive.setName = 'Flaffus Curius Naive';
        FlaffusCuriusNaive.setLabel = 'FlaffusCuriusNaive';
        FlaffusCuriusNaive.label = {'Flaffus', 'naive', 'Curius'};
        FlaffusCuriusNaive.filenames = {...
            'DATA_20171019T132932.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171020T124628.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171026T150942.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171027T145027.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171031T124333.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171101T123413.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171102T102500.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171103T143324.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171107T131228.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        FlaffusCuriusNaive.Captions = {...
            '2017.10.19', ...
            '2017.10.20', ...
            '2017.10.26', ...
            '2017.10.27',...
            '2017.10.31',...
            '2017.11.01', ...
            '2017.11.02',...
            '2017.11.03',...
            '2017.11.07', ...
            };
        FlaffusCuriusNaive.color = [192 157 169]/255;
        FlaffusCuriusNaive.Symbol = 'none';
        FlaffusCuriusNaive.FilledSymbols = 1;
        
        
        ConfederateElmoSM.setName = 'Confederate Elmo SM';
        ConfederateElmoSM.setLabel = 'ConfederateElmoSM';
        ConfederateElmoSM.label = {'Elmo', 'confederate', 'SM_JK'};
        ConfederateElmoSM.filenames = {...
            'DATA_20181121T091506.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181122T103832.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181123T121605.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181126T120147.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181127T093819.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181128T094141.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181129T092325.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181130T083319.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181210T113325.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181211T095631.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181212T100154.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181213T092017.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181214T141308.A_Elmo.B_TN.SCP_01.triallog.A.Elmo.B.TN_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181217T102931.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20181218T102152.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190124T072138.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190125T072506.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190129T072514.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190130T103717.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190131T084122.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190201T084158.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190208T083436.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190207T083916.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190206T090116.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190205T085347.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190212T082221.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190213T100854.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190214T092512.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190215T085907.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190218T121447.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190220T090318.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190222T144413.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190225T093605.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190226T095145.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190227T092114.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190228T085108.A_Elmo.B_JK.SCP_01.triallog.A.Elmo.B.JK_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190301T093255.A_Elmo.B_SM.SCP_01.triallog.A.Elmo.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateElmoSM.Captions = {...
            '81121', ...
            '81122', ...
            '81123', ...
            '81126', ...
            '81127', ...
            '81128', ...
            '81129', ...
            '81130JK', ...
            '81210', ...
            '81211', ...
            '81212', ...
            '81213', ...
            '81213TN', ...
            '81217', ...
            '81218', ...
            '90124JK', ...
            '90125JK', ...
            '90129JK', ...
            '90130JK', ...
            '90131JK', ...
            '90201JK', ...
            '90208JK', ...
            '90207JK', ...
            '90206JK', ...
            '90205JK', ...
            '90212JK', ...
            '90213SM', ...
            '90214JK', ...
            '90215JK_20_80', ...
            '90218SM_20_80', ...
            '90219JK_20_80', ...
            '90222SM_50_50', ...
            '90225JK', ...
            '90226JK', ...
            '90227JK', ...
            '90228JK', ...
            '90301SM', ...
            };
        ConfederateElmoSM.color = [192 157 169]/255;
        ConfederateElmoSM.Symbol = 'none';
        ConfederateElmoSM.FilledSymbols = 1;
        
        
        ConfederateTNLinus.setName = 'Confederate TN Linus';
        ConfederateTNLinus.setLabel = 'ConfederateTNLinus';
        ConfederateTNLinus.label = {'TN', 'confederate', 'Linus'};
        ConfederateTNLinus.filenames = {...
            'DATA_20190129T122449.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190130T124921.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190131T114745.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190131T125816.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190201T123249.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190204T123208.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190211T142714.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190212T125846.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190213T151302.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190214T135105.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190215T132350.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190218T144912.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190219T134152.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190220T112728.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190225T110752.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190226T134808.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190227T140358.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20190228T114901.A_TN.B_Linus.SCP_01.triallog.A.TN.B.Linus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederateTNLinus.Captions = {...
            '90129', ...
            '90130', ...
            '90131', ...
            '90131', ...
            '90201', ...
            '90204', ...
            '90211', ...
            '90212', ...
            '90213', ...
            '90214', ...
            '90215', ...
            '90218', ...
            '90219', ...
            '90220', ...
            '90225', ...
            '90226', ...
            '90227', ...
            '90228', ...
            };
        ConfederateTNLinus.color = [192 157 169]/255;
        ConfederateTNLinus.Symbol = 'none';
        ConfederateTNLinus.FilledSymbols = 1;
               
        
        group_struct_list = {Humans, Macaques_early, teslaElmoNaive, ...
            ConfederatesMacaques_early, ConfederatesMacaques_late, ConfederateTrainedMacaques, ...
            ConfederateSMCurius, ConfederateSMFlaffus, ConfederateSMCuriusBlocked, ConfederateSMFlaffusBlocked, ...
            FlaffusCuriusNaive, ConfederateElmoSM, ConfederateTNLinus, Humans50_55__80_20, Humans50_50, GoodHumans, BadHumans, ...
            HumansTransparent, HumansOpaque, Macaques_late, ConfederateTrainedMacaquesBest};
    otherwise
        disp(['Encountered unhandled group_collection_name: ', group_collection_name]);
end
return
end

function [current_axis_h] = fn_plot_type_to_axis(current_axis_h, graph_type, x_vec_arr, y_vec_arr, color_list, marker_list)

% how many things to loop over
n_instances = size(y_vec_arr, 2);
n_groups = size(y_vec_arr, 1);

if strcmp(graph_type, 'bar')
    hold on
    bh = bar(y_vec_arr, 'grouped');
    for i_instance = 1 : n_instances
        if ~isempty(color_list)
            bh(i_instance).FaceColor = color_list{i_instance};
        end
    end
    %set('XLim', [0.1, (n_groups+0.9)]);
    hold off
    return
end

hold on
for i_instance = 1 : n_instances
    cur_x_vec = x_vec_arr(:, i_instance);
    cur_y_vec = y_vec_arr(:, i_instance);
    if ~isempty(color_list)
        cur_color = color_list{i_instance};
    else
        cur_color = [0 0.4470 0.7410];% default
    end
    if ~isempty(marker_list)
        cur_marker = marker_list{i_instance};
    else
        cur_marker = 'none';% default
    end
    switch graph_type
        case 'bar'
            bar(cur_x_vec, cur_y_vec);
        case 'line'
            plot(cur_x_vec, cur_y_vec, 'Color', cur_color, 'Marker', cur_marker);
        otherwise
            error(['Unknown graph_type: ', graph_type]);
    end
end
hold off

return
end
