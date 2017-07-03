function [ output ] = fnAnalyseIndividualSCPSession( SessionLogFQN )
%I Summary of this function goes here
%   Detailed explanation goes here
output = [];

[PathStr, FileName, ~] = fileparts(SessionLogFQN);
% check the current parser version
[~, CurrentEventIDEReportParserVersionString] = fnParseEventIDEReportSCPv06([]);
MatFilename = fullfile(PathStr, [FileName CurrentEventIDEReportParserVersionString '.mat']);
% load if a mat file of the current parsed version exists, otherwise
% reparse
if exist(MatFilename, 'file')
	tmplogData = load(MatFilename);
	logData = tmplogData.report_struct;
	clear tmplogData;
else
	logData = fnParseEventIDEReportSCPv06(fullfile(PathStr, [FileName '.log']));
	%save(matFilename, 'logData'); % fnParseEventIDEReportSCPv06 saves by default
end

% now do something

% generate indices for trialtype, effector, targetposition, choice
% position, rewards-payout (target preference) dualNHP trials
TrialIndices = fnCollectTrialSets(logData);





return
end

