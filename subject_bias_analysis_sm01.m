clear variables;
N_PLAYERS = 2;
FontSize = 18;
LineWidth = 1.2;


ProcessNewestFirst = 1;
RunSingleSessionAnalysis = 1;

% human subjects
CurrentAnalysisSetName = 'SCP00';
% NHP subjects
CurrentAnalysisSetName = 'SCP01';
% %CurrentAnalysisSetName = 'LabRetreat2017';
% CurrentAnalysisSetName = 'LabRetreat2017FC';    % Free Choice
% CurrentAnalysisSetName = 'LabRetreat2017IC';    % Informed Choice
% 
% CurrentAnalysisSetName = 'Evaluation2017FC';    % Free Choice
% CurrentAnalysisSetName = 'Evaluation2017IC';    % Informed Choice


%experimentFolder = '201705ReachBiasData\\SCP-CTRL-01\\SESSIONLOGS\\';
%experimentFolder = fullfile('201705ReachBiasData', 'SCP-CTRL-01', 'SESSIONLOGS');
override_directive = 'local_code';
override_directive = 'local';

SCPDirs = GetDirectoriesByHostName(override_directive);
switch CurrentAnalysisSetName
    case {'SCP01'}
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS');
        LogFileWildCardString = '*SCP_01.log';
    case {'SCP00'}
        % the human data
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-00', 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS');
        LogFileWildCardString = '*SCP_00.log';
    case {'LabRetreat2017'}
        % data for the lab retreat 2017 presentation        
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'LabReatreat2017_BvS', 'LogFiles');
        LogFileWildCardString = '*.log';   
        
     case {'LabRetreat2017FC'}
        % data for the lab retreat 2017 presentation        
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'LabReatreat2017_BvS', 'LogFiles', 'FreeChoiceSessionLogs');
        LogFileWildCardString = '*.log';        

    case {'LabRetreat2017IC'}
        % data for the lab retreat 2017 presentation        
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'LabReatreat2017_BvS', 'LogFiles', 'InformedChoiceSessionLogs');
        LogFileWildCardString = '*.log';        

     case {'Evaluation2017FC'}
        % data for the lab retreat 2017 presentation        
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'CNL_Evaluation_2017', 'LogFiles', 'FreeChoiceSessionLogs');
        LogFileWildCardString = '*.log';        

    case {'Evaluation2017IC'}
        % data for the lab retreat 2017 presentation        
        experimentFolder = fullfile(SCPDirs.SCP_DATA_BaseDir, '..', 'Projects', 'CNL_Evaluation_2017', 'LogFiles', 'InformedChoiceSessionLogs');
        LogFileWildCardString = '*.log';
        
    otherwise
        error(['Encountered yet unhandled set up numer ', num2str(CurrentSetUpNum), ' stopping.']);
end

SCPDirs.OutputDir = fullfile(experimentFolder, 'ANALYSES', SCPDirs.CurrentShortHostName);
% no time information
TmpOutBaseDir = [];
% full time resolution
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmddTHHMMSS'));
% by day
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyymmdd'));
% by year
TmpOutBaseDir = fullfile(SCPDirs.OutputDir, datestr(now, 'yyyy'));
% for DPZEvaluation2017
%TmpOutBaseDir = SCPDirs.OutputDir;




Options.OutFormat = '.pdf';

% examples for development
% DAG_VERTICALCHOICE DirectFreeGazeReaches, no dual target trials
ExperimentFileFQN_list = {fullfile(experimentFolder, '20170531/20170531T145722.A_Magnus.B_None.SCP_01/20170531T145722.A_Magnus.B_None.SCP_01.log')};
% DAG_VERTICALCHOICE DirectFreeGazeFreeChoice
ExperimentFileFQN_list = {fullfile(experimentFolder, '20170602/20170602T151337.A_Magnus.B_None.SCP_01/20170602T151337.A_Magnus.B_None.SCP_01.log')};
ExperimentFileFQN_list = [];

if isempty(ExperimentFileFQN_list)
    disp(['Trying to find all logfiles in ', experimentFolder]);
    experimentFile = find_all_files(experimentFolder, LogFileWildCardString, 0);
else
    experimentFile = ExperimentFileFQN_list;
end    
% allow to ignore some sessions
%TODO fix up the parser to deal with older well-formed report files, switch
%to selective exclusion of individual days instead of whole months...
ExcludeWildCardList = {'_TESTVERSIONS', '20170106', '201701', '201702', '201703', 'A_SM-InactiveVirusScanner', 'A_Test', 'TestA', 'TestB', 'B_Test'};
ExcludeWildCardList = {'ANALYSES', '201701', '201702', '201703', 'A_SM-InactiveVirusScanner', 'A_Test', 'TestA', 'TestB', 'B_Test', '_PARKING', '_TESTVERSIONS'};

IncludedFilesIdx = [];
for iFile = 1 : length(experimentFile)
	TmpIdx = [];
	for iExcludeWildCard = 1 : length(ExcludeWildCardList)
		TmpIdx = [TmpIdx, strfind(experimentFile{iFile}, ExcludeWildCardList{iExcludeWildCard})];
	end
	if isempty(TmpIdx)
		IncludedFilesIdx(end+1) = iFile;
	end
end
experimentFile = experimentFile(IncludedFilesIdx);


nFiles = length(experimentFile);

% the newest sessions might of most interest
if (ProcessNewestFirst)
	experimentFile = experimentFile(end:-1:1);
end




out_list = {};

if (RunSingleSessionAnalysis)
	for iSession = 1 : length(experimentFile)
		CurentSessionLogFQN = experimentFile{iSession};
		out = fnAnalyseIndividualSCPSession(CurentSessionLogFQN, TmpOutBaseDir);
        if ~isempty(out)
            out_list{end+1} = out;
        end
	end
end

% collect the output from 
% loop over all cells of out and create meaningful performance plots (show perf in %)
disp(['Saving summary as ', fullfile(SCPDirs.OutputDir, [CurrentAnalysisSetName, '.Summary.mat'])]);
save(fullfile(SCPDirs.OutputDir, [CurrentAnalysisSetName, '.Summary.mat']), 'out_list');


return


w = 8;
endSize = 45;

iSubject = 0;
nSubject = 0;
isVerticalChoice = false;
for iFile = 1:nFiles
	basicSessionData(iFile) = extract_session_data(experimentFile{iFile}, isVerticalChoice);
	if (basicSessionData(iFile).nTrial < endSize)
		continue;
	end
	freeSession(iFile) = process_free_choice_session(basicSessionData(iFile), endSize, w);
	if (freeSession(iFile).nTrial < endSize)
		continue;
	end
	for iPlayer = 1:basicSessionData(iFile).nPlayer
		if (basicSessionData(iFile).nPlayer > 1)
			sideOfPlayer = iPlayer;
		else
			sideOfPlayer = 0;
		end
		sessionDateStr = basicSessionData(iFile).name(1:8);
		
		if (nSubject > 0)
			iSubject = find(strcmp({subject.name}, basicSessionData(iFile).playerName(iPlayer)));
			if (isempty(iSubject))
				iSubject = 0;
			end
		end
		if (iSubject == 0)
			nSubject = nSubject + 1;
			subject(nSubject) = struct('name', basicSessionData(iFile).playerName{iPlayer}, ...
				'sessionIndex', iFile, ...
				'sessionType', sideOfPlayer, ...
				'nSession', 1, ...
				'date', {sessionDateStr});
		else
			subject(iSubject).sessionIndex = [subject(iSubject).sessionIndex, iFile];
			subject(iSubject).sessionType = [subject(iSubject).sessionType, sideOfPlayer];
			subject(iSubject).date = [subject(iSubject).date, {sessionDateStr}];
			subject(iSubject).nSession = subject(iSubject).nSession + 1;
		end
	end
end

%% compute remaining fields of subjects
for iSubject = 1:nSubject
	%!!! Here we assume that the number of targets in every session is the same.
	%    This is not necessarily true!
	%TODO: resolve this issue!!!!
	nTargets = length(freeSession(subject(iSubject).sessionIndex(1)).shareChoiceOfPos(1, :));
	subject(iSubject).shareChoiceOfPos = zeros(subject(iSubject).nSession, nTargets);
	subject(iSubject).shareChoiceOfPosEnd  = zeros(subject(iSubject).nSession, nTargets);
	subject(iSubject).medianSideReactionTime = zeros(subject(iSubject).nSession, nTargets);
	subject(iSubject).medianSideReleaseTime = zeros(subject(iSubject).nSession, nTargets);
	
	subject(iSubject).medianReleaseTime = zeros(1, subject(iSubject).nSession);
	subject(iSubject).meanReleaseTime = zeros(1, subject(iSubject).nSession);
	subject(iSubject).medianReactionTime = zeros(1, subject(iSubject).nSession);
	subject(iSubject).meanReactionTime = zeros(1, subject(iSubject).nSession);
	
	subject(iSubject).partner = cell(1, subject(iSubject).nSession);
	subject(iSubject).dualSession = subject(iSubject).sessionIndex(subject(iSubject).sessionType > 0);
	
	subject(iSubject).corrReactionTimes = [freeSession(subject(iSubject).dualSession).corrReactionTimes];
	subject(iSubject).corrReactionTimesEnd = [freeSession(subject(iSubject).dualSession).corrReactionTimesEnd];
	subject(iSubject).corrReleaseTimes = [freeSession(subject(iSubject).dualSession).corrReleaseTimes];
	subject(iSubject).corrReleaseTimesEnd = [freeSession(subject(iSubject).dualSession).corrReleaseTimesEnd];
	subject(iSubject).corrJointChoiceWithDeltaReactionTime = [freeSession(subject(iSubject).dualSession).corrJointChoiceWithDeltaReactionTime];
	subject(iSubject).corrJointChoiceWithDeltaReactionTimeEnd = [freeSession(subject(iSubject).dualSession).corrJointChoiceWithDeltaReactionTimeEnd];
	subject(iSubject).corrJointChoiceWithDeltaReleaseTime = [freeSession(subject(iSubject).dualSession).corrJointChoiceWithDeltaReleaseTime];
	subject(iSubject).corrJointChoiceWithDeltaReleaseTimeEnd = [freeSession(subject(iSubject).dualSession).corrJointChoiceWithDeltaReleaseTimeEnd];
	
	ndualSession = length(subject(iSubject).dualSession);
	subject(iSubject).corrJointChoiceWithReactionTime = zeros(ndualSession, 1);
	subject(iSubject).corrJointChoiceWithReactionTimeEnd = zeros(ndualSession, 1);
	subject(iSubject).corrJointChoiceWithReleaseTime = zeros(ndualSession, 1);
	subject(iSubject).corrJointChoiceWithReleaseTimeEnd = zeros(ndualSession, 1);
	
	iDualSession = 1;
	for iSession = 1:subject(iSubject).nSession
		currSessionIndex = subject(iSubject).sessionIndex(iSession);
		if (subject(iSubject).sessionType(iSession) > 0)
			sideOfPartner = bitxor(subject(iSubject).sessionType(iSession), 3); %bitxor(1,3) = 2, bitxor(2,3) = 1
			subject(iSubject).partner{iSession} = basicSessionData(currSessionIndex).playerName{sideOfPartner};
		else
			subject(iSubject).partner{iSession} = 'none';
		end
		subjectIndex = max(1, subject(iSubject).sessionType(iSession));
		subject(iSubject).shareChoiceOfPos(iSession, :) = freeSession(currSessionIndex).shareChoiceOfPos(subjectIndex, :);
		subject(iSubject).shareChoiceOfPosEnd(iSession, :) = freeSession(currSessionIndex).shareChoiceOfPosEnd(subjectIndex, :);
		
		subject(iSubject).medianSideReactionTime(iSession, :) = freeSession(currSessionIndex).medianReactionTime(subjectIndex, :);
		subject(iSubject).medianSideReleaseTime(iSession, :) = freeSession(currSessionIndex).medianReleaseTime(subjectIndex, :);
		
		subject(iSubject).medianReleaseTime(iSession) = median(freeSession(currSessionIndex).releaseTime(subjectIndex, :));
		subject(iSubject).meanReleaseTime(iSession) = mean(freeSession(currSessionIndex).releaseTime(subjectIndex, :));
		subject(iSubject).medianReactionTime(iSession) = median(freeSession(currSessionIndex).reactionTime(subjectIndex, :));
		subject(iSubject).meanReactionTime(iSession) = mean(freeSession(currSessionIndex).reactionTime(subjectIndex, :));
		
		%subject(iSubject).shareChoiceOfPosEnd(iSession, :) = freeSession(currSessionIndex).shareChoiceOfPosEnd(subjectIndex, :);
		if (subject(iSubject).sessionType(iSession) > 0)
			subject(iSubject).corrJointChoiceWithReactionTime(iDualSession) = freeSession(currSessionIndex).corrJointChoiceWithReactionTime(subjectIndex);
			subject(iSubject).corrJointChoiceWithReactionTimeEnd(iDualSession) = freeSession(currSessionIndex).corrJointChoiceWithReactionTimeEnd(subjectIndex);
			subject(iSubject).corrJointChoiceWithReleaseTime(iDualSession) = freeSession(currSessionIndex).corrJointChoiceWithReleaseTime(subjectIndex);
			subject(iSubject).corrJointChoiceWithReleaseTimeEnd(iDualSession) = freeSession(currSessionIndex).corrJointChoiceWithReleaseTimeEnd(subjectIndex);
			iDualSession = iDualSession + 1;
		end
	end
end

%% compute inter-session statistics for each subject
contigencyMatrix = zeros(2);
contigencyMatrixEnd = zeros(2);
for iSubject = 1:nSubject
	currSubject = subject(iSubject);
	
	isAssociation = zeros(currSubject.nSession);
	isAssociationEnd = zeros(currSubject.nSession);
	for iSession = 1:currSubject.nSession
		currSessionIndex = currSubject.sessionIndex(iSession);
		subjectIndex = max(1, currSubject.sessionType(iSession));
		
		contigencyMatrix(1, :) = freeSession(currSessionIndex).numChoiceOfPos(subjectIndex, :);
		contigencyMatrixEnd(1, :) = freeSession(currSessionIndex).numChoiceOfPosEnd(subjectIndex, :);
		for jSession = iSession+1:currSubject.nSession
			subjectIndex = max(1, currSubject.sessionType(jSession));
			currSessionIndex = currSubject.sessionIndex(jSession);
			contigencyMatrix(2, :) = freeSession(currSessionIndex).numChoiceOfPos(subjectIndex, :);
			contigencyMatrixEnd(2, :) = freeSession(currSessionIndex).numChoiceOfPosEnd(subjectIndex, :);
			isAssociation(iSession, jSession) = fishertest(contigencyMatrix, 'Alpha',0.01);
			isAssociation(jSession, iSession) = isAssociation(iSession, jSession);
			isAssociationEnd(iSession, jSession) = fishertest(contigencyMatrixEnd, 'Alpha',0.01);
			isAssociationEnd(jSession, iSession) = isAssociationEnd(iSession, jSession);
		end
	end
	textHeight = 30;
	f = figure('Name', [currSubject.name, '_ChoiceDifferenceTables']);
	t2 = uitable(f, 'Data',isAssociationEnd, 'RowName',currSubject.partner, 'ColumnName', currSubject.partner);
	t2.Position = [0, 10, t2.Extent(3), t2.Extent(4)];
	tableTitle = ['Association table for last ', num2str(endSize), ' trials of ', currSubject.name, ' sessions'];
	uicontrol('Style', 'text', 'Position', [0 t2.Extent(4) + 10 t2.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	
	t1 = uitable(f,'Data',isAssociation, 'RowName', currSubject.partner, 'ColumnName',currSubject.partner);
	t1.Position = [0, t2.Extent(4) + 50, t1.Extent(3), t1.Extent(4)];
	tableTitle = ['Association table for ', currSubject.name, ' sessions'];
	uicontrol('Style', 'text', 'Position', [0 t2.Extent(4) + t1.Extent(4) + 60 t1.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	set(f, 'Position', [30 30 max([t1.Extent(3), t2.Extent(3)]) t2.Extent(4) + t1.Extent(4) + 100]);
	
	set( gcf, 'PaperUnits','centimeters' );
	xSize = 30; ySize = 25;
	xLeft = 0; yTop = 0;
	set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
	
	write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, '_ChoiceDifferenceTables', Options.OutFormat]));
	%print ( '-d c', '-r300', [currSubject.name '_ChoiceDifferenceTables.eps']);
end


%% compute inter-session statistics for RT of each subject
for iSubject = 1:nSubject
	currSubject = subject(iSubject);
	%we assume that number of targets is the same for
	nSubjectPos = 0;
	for iSession = 1:currSubject.nSession
		nSubjectPos = nSubjectPos + length(basicSessionData(currSubject.sessionIndex(iSession)).TARGET_POS.ALL);
	end
	subjectPosName = cell(nSubjectPos, 1);
	reactionTimeForPos = cell(nSubjectPos, 1);
	releaseTimeForPos = cell(nSubjectPos, 1);
	dualSectionPos = zeros(nSubjectPos, 1);
	iSubjectPos = 1;
	for iSession = 1:currSubject.nSession
		currSessionIndex = currSubject.sessionIndex(iSession);
		subjectIndex = max(1, currSubject.sessionType(iSession));
		
		nCurrentPos = length(basicSessionData(currSessionIndex).TARGET_POS.ALL);
		for iPos = 1:nCurrentPos
			posIndices = (freeSession(currSessionIndex).chosenPos(subjectIndex, :) ==  basicSessionData(currSessionIndex).TARGET_POS.ALL(iPos));
			if (nnz(posIndices) < 2)
				continue;
			end
			reactionTimeForPos{iSubjectPos} = freeSession(currSessionIndex).reactionTime(subjectIndex, posIndices);
			releaseTimeForPos{iSubjectPos} = freeSession(currSessionIndex).releaseTime(subjectIndex, posIndices);
			subjectPosName{iSubjectPos} = [currSubject.partner{iSession} ', pos' num2str(iPos)];
			
			if (isempty(find(currSubject.dualSession == currSessionIndex, 1)) ~= 1)
				dualSectionPos(iSubjectPos) = iSubjectPos;
			end
			iSubjectPos = iSubjectPos + 1;
		end
	end
	%compute true number of positions for the player. It may be lower than
	% nSubjectPos since at some sessions some positions can be never reached.
	nSubjectPos = iSubjectPos - 1;
	
	reactionTimeEquidistrib = zeros(nSubjectPos);
	releaseTimeEquidistrib = zeros(nSubjectPos);
	subjectPosName(iSubjectPos:end) = [];
	dualSectionPos(dualSectionPos == 0) = []; %leaveonly indices of pos in dual sections
	%tableColumnWidth = cell(1, nSubjectPos);
	tableColumnWidth = num2cell(6*cellfun('length', subjectPosName)' - 6);
	subjectPosName = strcat('<html><font size=-2>', subjectPosName);
	%tableColumnWidth(:) = {58};
	%tableColumnWidth{1} = 60;
	
	for iSubjectPos = 1:nSubjectPos
		for jSubjectPos = 1:nSubjectPos
			reactionTimeEquidistrib(iSubjectPos, jSubjectPos) = kstest2(reactionTimeForPos{iSubjectPos}, reactionTimeForPos{jSubjectPos}, 'Alpha',0.01);
			reactionTimeEquidistrib(jSubjectPos, iSubjectPos) = reactionTimeEquidistrib(iSubjectPos, jSubjectPos);
			releaseTimeEquidistrib(iSubjectPos, jSubjectPos) = kstest2(releaseTimeForPos{iSubjectPos}, releaseTimeForPos{jSubjectPos}, 'Alpha',0.01);
			releaseTimeEquidistrib(jSubjectPos, iSubjectPos) = releaseTimeEquidistrib(iSubjectPos, jSubjectPos);
		end
	end
	windowWidth = 5200;
	textHeight = 30;
	f = figure('Name', [currSubject.name, '_ReactionTimeDistribDifferenceTables']);
	t = uitable(f,'Data',reactionTimeEquidistrib, 'RowName',subjectPosName, 'ColumnName', subjectPosName, 'fontsize', FontSize/2, 'FontName', 'Times', 'ColumnWidth', tableColumnWidth);
	t.Position = [0, 10, t.Extent(3), t.Extent(4)];
	tableTitle = ['KS test oucomes for reaction times in ', currSubject.name, ' sessions'];
	uicontrol('Style', 'text', 'Position', [0 t.Extent(4) + 10 t.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	
	%changing the header column width
	%get the row header
	jscroll=findjobj(t);
	rowHeaderViewport=jscroll.getComponent(4);
	rowHeader=rowHeaderViewport.getComponent(0);
	%resize the row header
	newWidth = 75;
	rowHeaderViewport.setPreferredSize(java.awt.Dimension(newWidth,0));
	height=rowHeader.getHeight;
	rowHeader.setPreferredSize(java.awt.Dimension(newWidth,height));
	rowHeader.setSize(newWidth,height);
	
	set(f, 'Position', [30 50 min(t.Extent(3), windowWidth) t.Extent(4) + textHeight + 10]);
	set( gcf, 'PaperUnits','centimeters' );
	xSize = 30; ySize = 25;
	xLeft = 0; yTop = 0;
	set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
	write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, '_ReactionTimeDistribDifferenceTables', Options.OutFormat]));
	%print ( '-depsc', '-r300', [currSubject.name '_ReactionTimeDistribDifferenceTables.eps']);
	
	f = figure('Name', [currSubject.name, '_ReleaseTimeDistribDifferenceTables']);
	t = uitable(f,'Data',releaseTimeEquidistrib, 'RowName', subjectPosName, 'ColumnName',subjectPosName, 'fontsize', FontSize/2, 'FontName', 'Times', 'ColumnWidth', tableColumnWidth);
	t.Position = [0, 10, t.Extent(3), t.Extent(4)];
	tableTitle = ['KS test oucomes for release times in ', currSubject.name, ' sessions'];
	uicontrol('Style', 'text', 'Position', [0 t.Extent(4) + 10 t.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	%changing the header column width
	%get the row header
	jscroll=findjobj(t);
	rowHeaderViewport=jscroll.getComponent(4);
	rowHeader=rowHeaderViewport.getComponent(0);
	%resize the row header
	newWidth = 75;
	rowHeaderViewport.setPreferredSize(java.awt.Dimension(newWidth,0));
	height=rowHeader.getHeight;
	rowHeader.setPreferredSize(java.awt.Dimension(newWidth,height));
	rowHeader.setSize(newWidth,height);
	
	set(f, 'Position', [30 50 min(t.Extent(3), windowWidth) t.Extent(4) + textHeight + 10]);
	set( gcf, 'PaperUnits','centimeters' );
	xSize = 30; ySize = 25;
	xLeft = 0; yTop = 0;
	set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
	write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, '_ReleaseTimeDistribDifferenceTables', Options.OutFormat]));
	%print ( '-depsc', '-r300', [currSubject.name '_ReleaseTimeDistribDifferenceTables.eps']);
	
	
	nDualSectionPos = length(dualSectionPos);
	reactionTimeEquidistribDual = cell(nDualSectionPos);
	reactionTimeEquidistribDual(:, :) = {'same'};
	reactionTimeEquidistribDual(reactionTimeEquidistrib(dualSectionPos, dualSectionPos) == 1) = {'diff'};
	releaseTimeEquidistribDual = cell(nDualSectionPos);
	releaseTimeEquidistribDual(:, :) = {'same'};
	releaseTimeEquidistribDual(releaseTimeEquidistrib(dualSectionPos, dualSectionPos) == 1) = {'diff'};
	
	f = figure('Name', [currSubject.name, 'RTdualDistribDifferenceTables']);
	t2 = uitable(f,'Data',reactionTimeEquidistribDual, 'RowName',subjectPosName(dualSectionPos), 'ColumnName', subjectPosName(dualSectionPos));
	t2.Position = [0, 10, t2.Extent(3), t2.Extent(4)];
	tableTitle = ['KS test oucomes for reaction times in ', currSubject.name, ' dual sessions'];
	uicontrol('Style', 'text', 'Position', [0 t2.Extent(4) + 10 t2.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	
	t1 = uitable(f,'Data',releaseTimeEquidistribDual, 'RowName',subjectPosName(dualSectionPos), 'ColumnName', subjectPosName(dualSectionPos));
	t1.Position = [0, t2.Extent(4) + 50, t1.Extent(3), t1.Extent(4)];
	tableTitle = ['KS test oucomes for release times in ', currSubject.name, ' dual sessions'];
	uicontrol('Style', 'text', 'Position', [0 t2.Extent(4) + t1.Extent(4) + 60 t1.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	set(f, 'Position', [30 200 max([t1.Extent(3), t2.Extent(3)]) t2.Extent(4) + t1.Extent(4) + 100]);
	
	set( gcf, 'PaperUnits','centimeters' );
	xSize = 30; ySize = 25;
	xLeft = 0; yTop = 0;
	set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
	write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'RTdualDistribDifferenceTables', Options.OutFormat]));
	%print ( '-depsc', '-r300', [currSubject.name 'RTdualDistribDifferenceTables.eps']);
end

%% plot running mean of RT for left and right targets
for iSubject = 1:nSubject
	currSubject = subject(iSubject);
	f = figure('Name', [currSubject.name, 'average_RTbias']);
	set( axes,'fontsize', FontSize, 'FontName', 'Times');
	nDualSection = length(currSubject.dualSession);
	for iSession = 1:nDualSection
		currSessionIndex = currSubject.dualSession(iSession);
		sectionIndexForCurrentSubject = find(currSubject.sessionIndex == currSessionIndex);
		subjectIndex = max(1, currSubject.sessionType(sectionIndexForCurrentSubject));
		
		nCurrentPos = length(basicSessionData(currSessionIndex).TARGET_POS.ALL);
		
		for iPos = 1:nCurrentPos
			posIndices = (freeSession(currSessionIndex).chosenPos(subjectIndex, :) ==  basicSessionData(currSessionIndex).TARGET_POS.ALL(iPos));
			if (nnz(posIndices) < 2)
				continue;
			end
			x = find(posIndices == 1);
			y1 = freeSession(currSessionIndex).releaseTime(subjectIndex, posIndices);
			y1 = movmean(y1, w);
			y2 = freeSession(currSessionIndex).reactionTime(subjectIndex, posIndices);
			y2 = movmean(y2, w);
			
			subplot(nDualSection, nCurrentPos, (iSession-1)*nCurrentPos + iPos)
			hold on
			plot (x, y1, 'b--', 'linewidth', LineWidth);
			plot (x, y2, 'b', 'linewidth', LineWidth);
			hold off
			axis( [0, max(x), 0.3, 0.9] );
			title(['Left/Right average reaction times for ' subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
			set( gca, 'fontsize', FontSize, 'FontName', 'Times');
			xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
			ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');
			legend('Average release time ', 'Average reaction time', 'location', 'NorthEast');
		end
	end
	set( gcf, 'PaperUnits','centimeters' );
	xSize = 36; ySize = 30;
	xLeft = 0; yTop = 0;
	set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
	write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'average_RTbias', Options.OutFormat]));
	%print ( '-depsc', '-r300', [currSubject.name 'average_RTbias.eps']);
end



%% plot share of choices
f = figure('Name', [currSubject.name, 'subjectBias_shareOfChoices']);
set( axes,'fontsize', FontSize, 'FontName', 'Times');
for iSubject = 1:nSubject
	xLabels = strcat(subject(iSubject).date, '\newline', subject(iSubject).partner);
	subplot(nSubject, 1, iSubject);
	bar(subject(iSubject).shareChoiceOfPos(:, 1));
	axis( [0.2, numel(xLabels) + 0.8, 0, 1.1] );
	set(gca, 'XTickLabel',xLabels, 'XTick',1:numel(xLabels), 'fontsize', FontSize/2, 'FontName', 'Times')
	title(['Share of left choices for ' subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
end
set( gcf, 'PaperUnits','centimeters' );
xSize = 36; ySize = 30;
xLeft = 0; yTop = 0;
set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'subjectBias_shareOfChoices', Options.OutFormat]));
%print ( '-depsc', '-r300', 'subjectBias_shareOfChoices.eps');

f = figure('Name', 'subjectBias_shareOfChoicesEnd');
set( axes,'fontsize', FontSize, 'FontName', 'Times');
for iSubject = 1:nSubject
	xLabels = strcat(subject(iSubject).date, '\newline', subject(iSubject).partner);
	%xLabels = strcat(xLabels, subject(iSubject).partner)
	subplot(nSubject, 1, iSubject);
	bar(subject(iSubject).shareChoiceOfPosEnd(:, 1));
	axis( [0.2, numel(xLabels) + 0.8, 0, 1.1] );
	set(gca, 'XTickLabel',xLabels, 'XTick',1:numel(xLabels), 'fontsize', FontSize/2, 'FontName', 'Times')
	title(['Share of left choices for last ', num2str(endSize), ' trials of ', subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
end
set( gcf, 'PaperUnits','centimeters' );
xSize = 36; ySize = 30;
xLeft = 0; yTop = 0;
set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'subjectBias_shareOfChoicesEnd', Options.OutFormat]));
%print ( '-depsc', '-r300', 'subjectBias_shareOfChoicesEnd.eps');

%% plot mean and median RT
f = figure('Name', 'subjectBias_RT');
set( axes,'fontsize', FontSize, 'FontName', 'Times');
for iSubject = 1:nSubject
	xLabels = strcat(subject(iSubject).date, '\newline', subject(iSubject).partner);
	y = [subject(iSubject).medianReleaseTime; subject(iSubject).meanReleaseTime; ...
		subject(iSubject).medianReactionTime; subject(iSubject).meanReactionTime];
	subplot(nSubject, 1, iSubject);
	bar(y');
	axis( [0, numel(xLabels)+1, 0, max(max(y)) + 0.25] );
	set(gca, 'XTickLabel',xLabels, 'XTick',1:numel(xLabels), 'fontsize', FontSize/2, 'FontName', 'Times')
	title(['Reaction times for ' subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
	legend('Median Release time', 'Mean Release time', 'Median reaction time', 'Mean reaction time', 'location', 'NorthEast');
end
set( gcf, 'PaperUnits','centimeters' );
xSize = 36; ySize = 30;
xLeft = 0; yTop = 0;
set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'subjectBias_RT', Options.OutFormat]));
%print ( '-depsc', '-r300', 'subjectBias_RT.eps');



%% plot median RT for left and right targets
f = figure('Name', 'subjectBias_RTbias');
set( axes,'fontsize', FontSize, 'FontName', 'Times');
for iSubject = 1:nSubject
	xLabels = strcat(subject(iSubject).date, '\newline', subject(iSubject).partner);
	y = [subject(iSubject).medianSideReleaseTime(:, 1)'; subject(iSubject).medianSideReleaseTime(:, 2)'; ...
		subject(iSubject).medianSideReactionTime(:, 1)'; subject(iSubject).medianSideReactionTime(:, 2)'];
	
	subplot(nSubject, 1, iSubject);
	bar(y');
	axis( [0, numel(xLabels)+1, 0, max(max(y)) + 0.25] );
	set(gca, 'XTickLabel',xLabels, 'XTick',1:numel(xLabels), 'fontsize', FontSize/2, 'FontName', 'Times')
	title(['Left/Right reaction times for ' subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
	legend('Median release time left', 'Median release time right', 'Median reaction time left', 'Median reaction time right', 'location', 'NorthEast');
end
set( gcf, 'PaperUnits','centimeters' );
xSize = 36; ySize = 30;
xLeft = 0; yTop = 0;
set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'subjectBias_RTbias', Options.OutFormat]));
%print ( '-depsc', '-r300', 'subjectBias_RTbias.eps');


%% correlations of RT
f = figure('Name', 'subjectBias_RTcorr');
set( axes,'fontsize', FontSize, 'FontName', 'Times');
for iSubject = 1:nSubject
	xLabels = strcat(subject(iSubject).date, '\newline', subject(iSubject).partner);
	y = [subject(iSubject).corrReleaseTimes; subject(iSubject).corrReactionTimes];
	subplot(nSubject, 1, iSubject);
	bar(y');
	axis( [1, numel(xLabels), -0.4, 0.4] );
	set(gca, 'XTickLabel',xLabels, 'XTick',1:numel(xLabels), 'fontsize', FontSize/2, 'FontName', 'Times')
	title(['Correlations of reaction times with the partner for ', num2str(endSize), ' trials of ', subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
	legend('Release time', 'Total reaction time', 'location', 'SouthWest');
end
set( gcf, 'PaperUnits','centimeters' );
xSize = 24; ySize = 24;
xLeft = 0; yTop = 0;
set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'subjectBias_RTcorr', Options.OutFormat]));
%print ( '-depsc', '-r300', 'subjectBias_RTcorr.eps');

f = figure('Name', 'subjectBias_RTcorrEnd');
for iSubject = 1:nSubject
	xLabels = strcat(subject(iSubject).date, '\newline', subject(iSubject).partner);
	y = [subject(iSubject).corrReleaseTimesEnd; subject(iSubject).corrReactionTimesEnd];
	subplot(nSubject, 1, iSubject);
	bar(y');
	axis( [1, numel(xLabels), -0.4, 0.4] );
	set(gca, 'XTickLabel',xLabels, 'XTick',1:numel(xLabels), 'fontsize', FontSize/2, 'FontName', 'Times')
	title(['Correlations of reaction times with the partner for last ', num2str(endSize), ' trials of ', subject(iSubject).name, ' sessions'], 'fontsize', FontSize, 'FontName', 'Times');
	legend('Release time', 'Total reaction time', 'location', 'SouthWest');
end
set( gcf, 'PaperUnits','centimeters' );
xSize = 24; ySize = 24;
xLeft = 0; yTop = 0;
set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, 'subjectBias_RTcorrEnd', Options.OutFormat]));
%print ( '-depsc', '-r300', 'subjectBias_RTcorrEnd.eps');


tableRowsName = {'corr. reaction time', ...
	'corr. reaction time (last 100)', ...
	'corr. release time', ...
	'corr. release time (last 100)', ...
	'corr. reaction time for joint trials', ...
	'corr. release time for joint trials', ...
	'corr. jointChoice With DeltaReactionTime', ...
	'corr. jointChoice With DeltaReactionTime (last 100)', ...
	'corr. jointChoice With DeltaReleaseTime', ...
	'corr. jointChoice With DeltaReleaseTime (last 100)', ...
	'share of joint choices among own left', ...
	'share of joint choices among own left (last 100)', ...
	'share of joint choices among own right', ...
	'share of joint choices among own right (last 100)'};
nRow = numel(tableRowsName);
for iSubject = 1:nSubject
	currSubject = subject(iSubject);
	nDualSession = length(currSubject.dualSession);
	
	dataTable = zeros(nRow, nDualSession);
	
	dataTable(1, :) = [freeSession(currSubject.dualSession).corrReactionTimes];
	dataTable(2, :) = [freeSession(currSubject.dualSession).corrReactionTimesEnd];
	dataTable(3, :) = [freeSession(currSubject.dualSession).corrReleaseTimes];
	dataTable(4, :) = [freeSession(currSubject.dualSession).corrReleaseTimesEnd];
	dataTable(5, :) = [freeSession(currSubject.dualSession).corrJointReactionTimes];
	dataTable(6, :) = [freeSession(currSubject.dualSession).corrJointReleaseTimes];
	dataTable(7, :) = [freeSession(currSubject.dualSession).corrJointChoiceWithDeltaReactionTime];
	dataTable(8, :) = [freeSession(currSubject.dualSession).corrJointChoiceWithDeltaReactionTimeEnd];
	dataTable(9, :) = [freeSession(currSubject.dualSession).corrJointChoiceWithDeltaReleaseTime];
	dataTable(10, :) = [freeSession(currSubject.dualSession).corrJointChoiceWithDeltaReleaseTimeEnd];
	nDualSection = length(currSubject.dualSession);
	for iSession = 1:nDualSection
		currSessionIndex = currSubject.dualSession(iSession);
		sectionIndexForCurrentSubject = find(currSubject.sessionIndex == currSessionIndex);
		subjectIndex = max(1, currSubject.sessionType(sectionIndexForCurrentSubject));
		
		dataTable(11, iSession) = freeSession(currSessionIndex).shareOfJointChoiceWrtPosition(subjectIndex, 1);
		dataTable(12, iSession) = freeSession(currSessionIndex).shareOfJointChoiceWrtPositionEnd(subjectIndex, 1);
		dataTable(13, iSession) = freeSession(currSessionIndex).shareOfJointChoiceWrtPosition(subjectIndex, 2);
		dataTable(14, iSession) = freeSession(currSessionIndex).shareOfJointChoiceWrtPositionEnd(subjectIndex, 2);
	end
	
	textHeight = 30;
	f = figure('Name', '_OtherParameters');
	t = uitable(f, 'Data',dataTable,  'ColumnName', currSubject.partner(subject(iSubject).sessionType > 0), 'RowName', tableRowsName);
	t.Position = [0, 10, t.Extent(3), t.Extent(4)];
	tableTitle = ['Parameters for the dual sessions of ', currSubject.name, ' sessions'];
	uicontrol('Style', 'text', 'Position', [0 t.Extent(4) + 10 t.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
	set(f, 'Position', [30 200 t.Extent(3) t.Extent(4) + 100]);
	
	set( gcf, 'PaperUnits','centimeters' );
	xSize = 30; ySize = 25;
	xLeft = 0; yTop = 0;
	set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
	write_out_figure(f, fullfile(SCPDirs.OutputDir, [currSubject.name, '_OtherParameters', Options.OutFormat]));
	%print ( '-depsc', '-r300', [currSubject.name '_OtherParameters.eps']);
end
%{
%}
