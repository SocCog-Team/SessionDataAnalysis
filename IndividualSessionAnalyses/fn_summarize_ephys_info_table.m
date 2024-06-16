function [ ] = fn_summarize_ephys_info_table( all_session_info_table_FQSTEM, extension_string, ephys_subject_list )
%FN_SUMMARIZE_EPHYS_INFO_TABLE Summary of this function goes here
%   Detailed explanation goes here

if ~exist('all_session_info_table_FQSTEM', 'var') || isempty(all_session_info_table_FQSTEM)
	all_session_info_table_FQSTEM = fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', 'All_session_summary_table.V2');
end

if ~exist('extension_string', 'var') || isempty(extension_string)
	extension_string = '.xlsx';
	extension_string = '.table.mat';
end

if ~exist('ephys_subject_list', 'var') || isempty(ephys_subject_list)
	ephys_subject_list = {'Elmo', 'Curius'};
end
version_number = 1;
output_stem = ['Ephys_summary_table.V', num2str(version_number)];



[input_dir, tmp_input_name, tmp_input_ext] = fileparts(all_session_info_table_FQSTEM);
input_stem = [tmp_input_name, tmp_input_ext];

table_fqn = fullfile(input_dir, [input_stem, extension_string]);




% load the data
switch extension_string
	case '.xlsx'
		data_sheetnames = sheetnames(table_fqn);
		data = readtable(table_fqn, 'Sheet', 'Sheet1', 'VariableNamesRow', 1, 'VariableDescriptionsRow', 2, "VariableNamingRule","preserve");
	case {'.mat', '.table.mat'}
		load(table_fqn, 'output_data_table');
		data = output_data_table;
	otherwise
		error([mfilename, ': unhandled extension string encountered: ', extension_string]);
end

% remove all TOTAL lines...
combination_ldx = ismember(data.record_type, {'COMBINATION'});

% remove all non-ephys lines
ehpys_ldx = ~ismember(data.EPhysRecorded, {'0'});

ephys_session_data = data(combination_ldx & ehpys_ldx, :);

% find all unique trislsubtypes:
[unique_trial_subtypes, ~, ephys_session_data_to_unique_trialsubtype_mapping] = unique(ephys_session_data.effective_trial_subtype);


% dual recording sessions are split into two virtual sessions one per
% recorded subject, with the subject name appended to the tank ID
NHP_A_ldx = ismember(ephys_session_data.species_A, {'NHP'});
NHP_B_ldx = ismember(ephys_session_data.species_B, {'NHP'});
% for recording sessions all humans were confederates
ConfHP_A_ldx = ismember(ephys_session_data.species_A, {'HP'});
ConfHP_B_ldx = ismember(ephys_session_data.species_B, {'HP'});

% the actual cue randomisation methods
blocked_confederate_ldx = (ConfHP_A_ldx & ismember(ephys_session_data.CueRandomizationMethod_A, {'BLOCKED'})) | (ConfHP_B_ldx & ismember(ephys_session_data.CueRandomizationMethod_B, {'BLOCKED'}));
shuffled_confederate_ldx = (ConfHP_A_ldx & ismember(ephys_session_data.CueRandomizationMethod_A, {'SHUFFLED'})) | (ConfHP_B_ldx & ismember(ephys_session_data.CueRandomizationMethod_B, {'SHUFFLED'}));
% whether a partner was actually predictable
predictable_confederate_ldx = (ConfHP_A_ldx & (ephys_session_data.A_nonrandomValue_p < 0.001)) | (ConfHP_B_ldx & (ephys_session_data.B_nonrandomValue_p < 0.001));
% whether a partner was predicted...
predicted_partner_A_ldx = ephys_session_data.AgoB_A_depends_on_LastB_pval < 0.001;
%predicted_partner_A_ldx = ephys_session_data.AirtB_A_depends_on_LastB_pval < 0.001;
predicted_partner_B_ldx = ephys_session_data.BgoA_B_depends_on_LastA_pval < 0.001;
%predicted_partner_B_ldx = ephys_session_data.BirtA_B_depends_on_LastA_pval < 0.001;
predicted_partner_ldx = predicted_partner_A_ldx | predicted_partner_B_ldx;

% proto_dual_ephys_session
dual_NHP_ephys_session_ldx = NHP_A_ldx & NHP_B_ldx;
single_NHP_ephys_session_ldx = ~dual_NHP_ephys_session_ldx;

spike_sorted_combinations_ldx = ismember(ephys_session_data.EPhysSpikeSorted, {'1'});

%[ matching_item_ldx ] = fn_find_regexpmatch_entries_in_cell_list( ephys_session_data.TankID_list, regexp_match_pattern )

ephys_summary_table_struct = [];

% find the records per ephys_subject
for i_ephys_subject = 1 : length(ephys_subject_list)
	cur_ephys_subject = ephys_subject_list{i_ephys_subject};
	cur_ephys_subject_on_A_ldx = ismember(ephys_session_data.subject_A, cur_ephys_subject);
	cur_ephys_subject_on_B_ldx = ismember(ephys_session_data.subject_B, cur_ephys_subject);
	dual_NHP_session_with_cur_subject_ephys = fn_find_regexpmatch_entries_in_cell_list(ephys_session_data.TankID_list, ['_', cur_ephys_subject,'$'])';
	dual_NHP_session_without_cur_subject_ephys = dual_NHP_ephys_session_ldx & ~dual_NHP_session_with_cur_subject_ephys;
	% get all combination lines for the current subject
	cur_ephys_subject_combination_ldx = ((cur_ephys_subject_on_A_ldx | cur_ephys_subject_on_B_ldx) & single_NHP_ephys_session_ldx) | dual_NHP_session_with_cur_subject_ephys;

	
	for i_trialsubtype = 1 : length(unique_trial_subtypes)
		cur_trial_subtype = unique_trial_subtypes{i_trialsubtype};
		cur_trial_subtype_ldx = ephys_session_data_to_unique_trialsubtype_mapping == i_trialsubtype;

		cur_selected_combinations_ldx = cur_trial_subtype_ldx & cur_ephys_subject_combination_ldx;

		side_list = {'A', 'B'};
		for i_subject_on_side = 1 : length(side_list)
			cur_side = side_list{i_subject_on_side};

			cur_ephys_subject_on_X_ldx = cur_trial_subtype_ldx & ismember(ephys_session_data.(['subject_', cur_side]), cur_ephys_subject);


			cur_selected_combinations_A_ldx = cur_selected_combinations_ldx & cur_ephys_subject_on_A_ldx;
			cur_selected_combinations_B_ldx = cur_selected_combinations_ldx & cur_ephys_subject_on_B_ldx;


			cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
			cur_ephys_summary_table_struct.Side = cur_side;
			cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
			cur_ephys_summary_table_struct.Comment = ''; % fill in later
			cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx);
			cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx);
			cur_ephys_summary_table_struct.N_MUA = sum(cur_ephys_subject_on_X_ldx & ephys_session_data.(['MUA_', cur_side, '_exported']));% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
			cur_ephys_summary_table_struct.N_LFP = sum(cur_ephys_subject_on_X_ldx & ephys_session_data.(['LFP_', cur_side, '_exported']));%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);

			if isempty(ephys_summary_table_struct)
				ephys_summary_table_struct = cur_ephys_summary_table_struct;
			else
				ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;
			end

			switch cur_trial_subtype
				case {'SoloARewardAB', 'SoloA', 'SoloA_PresentB', 'SoloABlockedView', 'SoloAHighReward'}
					switch cur_side
						case 'A'
							ephys_summary_table_struct(end).Comment = 'active'; % fill in now
						case 'B'
							ephys_summary_table_struct(end).Comment = 'passive'; % fill in now
					end
				case {'SoloBRewardAB', 'SoloB', 'SoloB_PresentA', 'SoloBBlockedView', 'SoloBHighReward'}
					switch cur_side
						case 'A'
							ephys_summary_table_struct(end).Comment = 'passive'; % fill in now
						case 'B'
							ephys_summary_table_struct(end).Comment = 'active'; % fill in now
					end

				case {'Dyadic', 'DyadicBlockedView', 'SemiSolo'}
					% create subreports by confederate's
					% predictability/prediction
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'dual NHP'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & dual_NHP_ephys_session_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & dual_NHP_ephys_session_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['MUA_', cur_side, '_exported']));% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['LFP_', cur_side, '_exported']));%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;
					
					%unpredictable confederate - not predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'UC not predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & ~predictable_confederate_ldx & ~predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & ~predictable_confederate_ldx & ~predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['MUA_', cur_side, '_exported']) & ~predictable_confederate_ldx & ~predicted_partner_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['LFP_', cur_side, '_exported']) & ~predictable_confederate_ldx & ~predicted_partner_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%unpredictable confederate - predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'UC predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & ~predictable_confederate_ldx & predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & ~predictable_confederate_ldx & predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['MUA_', cur_side, '_exported']) & ~predictable_confederate_ldx & predicted_partner_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['LFP_', cur_side, '_exported']) & ~predictable_confederate_ldx & predicted_partner_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%predictable confederate - not predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'PC not predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & predictable_confederate_ldx & ~predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & predictable_confederate_ldx & ~predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['MUA_', cur_side, '_exported']) & predictable_confederate_ldx & ~predicted_partner_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['LFP_', cur_side, '_exported']) & predictable_confederate_ldx & ~predicted_partner_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;

					%predictable confederate - predicted
					cur_ephys_summary_table_struct.Subject = cur_ephys_subject;
					cur_ephys_summary_table_struct.Side = cur_side;
					cur_ephys_summary_table_struct.TrialType = cur_trial_subtype;
					cur_ephys_summary_table_struct.Comment = 'PC predicted'; % fill in later
					cur_ephys_summary_table_struct.N_rec = sum(cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & predictable_confederate_ldx & predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_sorted = sum(spike_sorted_combinations_ldx & cur_ephys_subject_on_X_ldx & ~dual_NHP_ephys_session_ldx & predictable_confederate_ldx & predicted_partner_ldx);
					cur_ephys_summary_table_struct.N_MUA = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['MUA_', cur_side, '_exported']) & predictable_confederate_ldx & predicted_partner_ldx);% sum(cur_selected_combinations_A_ldx & ephys_session_data.MUA_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.MUA_B_exported);
					cur_ephys_summary_table_struct.N_LFP = sum(~dual_NHP_ephys_session_ldx & cur_ephys_subject_on_X_ldx & ephys_session_data.(['LFP_', cur_side, '_exported']) & predictable_confederate_ldx & predicted_partner_ldx);%sum(cur_selected_combinations_A_ldx & ephys_session_data.LFP_A_exported) + sum(cur_selected_combinations_B_ldx & ephys_session_data.LFP_B_exported);
					ephys_summary_table_struct(end+1) = cur_ephys_summary_table_struct;
			end


		end
	end

end


out_FQN = fullfile(input_dir, [output_stem, '.mat']);

% save struct array as mat file:
disp(['Saving session info data as: ' out_FQN]);
save(out_FQN, 'ephys_summary_table_struct');

% now save as xlsx and csv
output_data_table = struct2table(ephys_summary_table_struct);
[out_dir, out_name, out_ext] = fileparts(out_FQN);

% save as excel file
disp(['Saving session info data as .xslx: ' fullfile(out_dir, [out_name, '.xlsx'])]);
try
	writetable(output_data_table, fullfile(out_dir, [out_name, '.xlsx']));
catch
	% likely open in blocking mode, save as emergency file with date time
	cur_datetime_string = char(datetime("now", 'Format', 'yyyyMMdd-HHmmss'));
	disp([mfilename, ': Excel table version of session info data, is not writable; saving instead as: ',  [out_name, '.', cur_datetime_string, '.xlsx']])
	writetable(output_data_table, fullfile(out_dir, [out_name, '.', cur_datetime_string, '.xlsx']));
end
	
	% save as TXT
disp(['Saving session info data as .txt: ' fullfile(out_dir, [out_name, '.txt'])]);
writetable(output_data_table, fullfile(out_dir, [out_name, '.txt']), 'Delimiter', ';');
% save as CSV
disp(['Saving session info data as .csv: ' fullfile(out_dir, [out_name, '.csv'])]);
writetable(output_data_table, fullfile(out_dir, [out_name, '.csv']), 'Delimiter', ',');

% save the matlab table as .table.mat file
disp(['Saving session info data as matlab table: ' fullfile(out_dir, [out_name, '.table.mat'])]);
save(fullfile(out_dir, [out_name, '.table.mat']), 'output_data_table');


end

