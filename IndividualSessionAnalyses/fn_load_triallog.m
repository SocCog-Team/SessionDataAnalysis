function [ DataStruct, TrialSets ] = fn_load_triallog( SessionLogFQN )
%FN_LOAD_TRIALLOG Summary of this function goes here
%   Detailed explanation goes here

override_directive = 'local_code';


ForceParsingOfExperimentLog = 0; % rewrite the logfiles anyway
CleanOutputDir = 0;

% accept .sessiondir inputs
[tmp_PathStr, tmp_FileName, tmp_SessionLogExt] = fileparts(SessionLogFQN);
if strcmp(tmp_SessionLogExt, '.sessiondir')
    SessionLogFQN = fullfile(SessionLogFQN, [tmp_FileName, '.triallog']);
    disp(['Submitted .sessiondir, expanded to: ', SessionLogFQN]);
end    
[PathStr, FileName, SessionLogExt] = fileparts(SessionLogFQN);
 

if strcmp(SessionLogExt, '.triallog')
	% use magic .triallog extension to load the freshest version cheaply,
	% the logic moved into fnParseEventIDEReportSCPv06
	DataStruct = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName, SessionLogExt]), ';', '|', override_directive);
	FileName = [FileName, SessionLogExt]; % to meet old behaviour
elseif strcmp(SessionLogExt, '.txt')
	% check the current parser version
	[~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
	MatFilename = fullfile(PathStr, [FileName CurrentEventIDEReportParserVersionString '.mat']);
	% load if a mat file of the current parsed version exists, otherwise
	% reparse
	if exist(MatFilename, 'file') && ~(ForceParsingOfExperimentLog)
		tmpDataStruct = load(MatFilename);
		DataStruct = tmpDataStruct.report_struct;
		clear tmpDataStruct;
	else
		DataStruct = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName, SessionLogExt]), ';', '|', override_directive);
		%save(matFilename, 'DataStruct'); % fnParseEventIDEReportSCPv06 saves by default
	end
end

disp([mfilename, ': Processing: ', SessionLogFQN]);

% now do something

% generate indices for trialtype, effector, targetposition, choice
% position, rewards-payout (target preference) dualNHP trials
TrialSets = fnCollectTrialSets(DataStruct);
if isempty(TrialSets)
	disp([mfilename, ': Found zero trial records in ', SessionLogFQN, ' bailing out...']);
	return
end

end

