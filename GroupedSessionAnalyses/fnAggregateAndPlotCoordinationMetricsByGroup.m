function [ output_args ] = fnAggregateAndPlotCoordinationMetricsByGroup( session_metrics_datafile_fqn, group_struct_list, metrics_to_extract_list )
%FNAGGREGATEANDPLOTCOORDINATIONMETRICSBYGROUP Summary of this function goes here
%   Detailed explanation goes here

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


output_args = [];

if ~exist('session_metrics_datafile_fqn', 'var') || isempty(session_metrics_datafile_fqn)
    OutputPath = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'ANALYSES', 'hms-beagle2', '2018');
    session_metrics_datafile_fqn = fullfile(OutputPath, ['ALL_SESSSION_METRICS.mat']);
end

[OutputPath, FileName, FileExt] = fileparts(session_metrics_datafile_fqn);


if ~exist('metrics_to_extract_list', 'var') || isempty(metrics_to_extract_list)
    metrics_to_extract_list = {'AR'};
end

if ~exist('group_struct_list', 'var') || isempty(group_struct_list)
    group_struct_list = fn_get_session_group('oxford2018');
end


% control variables
plot_avererage_reward_by_group = 1;
confidence_interval_alpha = 0.05;

project_name = 'SfN208';
CollectionName = 'Oxford2018';
project_line_width = 0.5;
OutPutType = 'png';
%OutPutType = 'pdf';
DefaultAxesType = 'SfN2018'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
DefaultPaperSizeType = 'SfN2018.5'; % DPZ2017Evaluation, PrimateNeurobiology2018DPZ
output_rect_fraction = 0.5; % default 0.5
InvisibleFigures = 0;

if ~exist('fnFormatDefaultAxes')
    set(0, 'DefaultAxesLineWidth', 0.5, 'DefaultAxesFontName', 'Arial', 'DefaultAxesFontSize', 6, 'DefaultAxesFontWeight', 'normal');
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
    current_session_in_group_ldx = ismember(coordination_metrics_table.key, current_group.filenames);
    metrics_by_group_list{i_group} = coordination_metrics_table.data(current_session_in_group_ldx, :);
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
    Cur_fh_avg_reward_by_group = figure('Name', 'RewardOverTrials', 'visible', figure_visibility_string);
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
    %     set(gca(),'TickLabelInterpreter','none');
    %     xlabel( 'Number of trial');
    %     ylabel( 'Reward units');
    %     if (PlotLegend)
    %         legend(legend_list, 'Interpreter', 'None');
    %     end
    CurrentTitleSetDescriptorString = TitleSetDescriptorString;
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', OutPutType]);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
    outfile_fqn = fullfile(OutputPath, [FileName, '.', CurrentTitleSetDescriptorString, '.AvgRewardByGroup.', 'pdf']);
    write_out_figure(Cur_fh_avg_reward_by_group, outfile_fqn);
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
    case {'oxford2018', 'sfn2018', 'SfN2018'}
        % define the session sets:
        % Oxford, SfN2018
        Humans.setName = 'Humans';
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
        Humans.color = [142 205 253]/255;
        Humans.Symbol = '+';
        Humans.FilledSymbols = 0;
        
        Macaques_early.setName = 'Macaques early';
        Macaques_early.label = {'Macaques', 'early', ''};
        Macaques_early.filenames = {...
            'DATA_20180516T090940.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180504T114516.A_Tesla.B_Flaffus.SCP_01.triallog.A.Tesla.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180525T091512.A_Tesla.B_Curius.SCP_01.triallog.A.Tesla.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180605T091549.A_Curius.B_Elmo.SCP_01.triallog.A.Curius.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171108T140407.A_Magnus.B_Curius.SCP_01.triallog.A.Magnus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171019T132932.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171129T100056.A_Magnus.B_Flaffus.SCP_01.triallog.A.Magnus.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        Macaques_early.Captions = { ...
            'Tesla.Elmo', ...
            'Tesla.Flaffus', ...
            'Tesla.Curius', ...
            'Curius.Elmo', ...
            'Magnus.Curius', ...
            'Flaffus.Curius', ...
            'Magnus.Flaffus', ...
            };
        Macaques_early.color = [253 178 143]/255;
        Macaques_early.Symbol = 'o';
        Macaques_early.FilledSymbols = 0;
        
        Macaques_late.setName = 'Macaques late';
        Macaques_late.label = {'Macaques', 'late', ''};
        Macaques_late.filenames = {...
            'DATA_20180524T103704.A_Tesla.B_Elmo.SCP_01.triallog.A.Tesla.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180509T122330.A_Tesla.B_Flaffus.SCP_01.triallog.A.Tesla.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180531T104356.A_Tesla.B_Curius.SCP_01.triallog.A.Tesla.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180615T111344.A_Curius.B_Elmo.SCP_01.triallog.A.Curius.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180214T171119.A_Magnus.B_Curius.SCP_01.triallog.A.Magnus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20171107T131228.A_Flaffus.B_Curius.SCP_01.triallog.A.Flaffus.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180125T155742.A_Magnus.B_Flaffus.SCP_01.triallog.A.Magnus.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        Macaques_late.Captions = { ...
            'Tesla.Elmo', ...
            'Tesla.Flaffus', ...
            'Tesla.Curius', ...
            'Curius.Elmo', ...
            'Magnus.Curius', ...
            'Flaffus.Curius', ...
            'Magnus.Flaffus', ...
            };
        Macaques_late.color = [192 157 169]/255;
        Macaques_late.Symbol = 'o';
        Macaques_late.FilledSymbols = 0;
        
        ConfederatesMacaques_early.setName = 'Confederates-macaques early';
        ConfederatesMacaques_early.label = {'Confederates', 'macaques', 'early'};
        ConfederatesMacaques_early.filenames = {...
            'DATA_20171206T141710.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180131T155005.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180620T095959.A_JK.B_Elmo.SCP_01.triallog.A.JK.B.Elmo_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180601T122747.A_Tesla.B_SM.SCP_01.triallog.A.Tesla.B.SM_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederatesMacaques_early.Captions = { ...
            'Confederate.Curius',...
            'Confederate.Flaffus',...
            'Confederate.Elmo',...
            'Tesla.Confederate',...
            };
        ConfederatesMacaques_early.color = [253 178 143]/255;
        ConfederatesMacaques_early.Symbol = 's';
        ConfederatesMacaques_early.FilledSymbols = 1;
        
        ConfederatesMacaques_late.setName = 'Confederates-macaques late';
        ConfederatesMacaques_late.label = {'Confederates', 'macaques', 'late'};
        ConfederatesMacaques_late.filenames = {...
            'DATA_20180423T162330.A_SM.B_Curius.SCP_01.triallog.A.SM.B.Curius_IC_JointTrials.isOwnChoice_sideChoice', ...
            'DATA_20180228T132647.A_SM.B_Flaffus.SCP_01.triallog.A.SM.B.Flaffus_IC_JointTrials.isOwnChoice_sideChoice', ...
            };
        ConfederatesMacaques_late.Captions = { ...
            'Confederate.Curius',...
            'Confederate.Flaffus',...
            };
        ConfederatesMacaques_late.color = [192 157 169]/255;
        ConfederatesMacaques_late.Symbol = 's';
        ConfederatesMacaques_late.FilledSymbols = 1;
        
        ConfederateTrainedMacaques.setName = 'Confederate-trained macaques';
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
            '180418',...
            '180419', ...
            '180424', ...
            '180425', ...
            '180426', ...
            '180427', ...
            };
        ConfederateTrainedMacaques.color = [128 73 142]/255;
        ConfederateTrainedMacaques.Symbol = 'd';
        ConfederateTrainedMacaques.FilledSymbols = 0;

        
        group_struct_list = {Humans, Macaques_early, Macaques_late, ConfederatesMacaques_early, ConfederatesMacaques_late, ConfederateTrainedMacaques};
    otherwise
        disp(['Encountered unhandled group_collection_name: ', group_collection_name]);
end
return
end
