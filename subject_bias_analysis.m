clear variables;
N_PLAYERS = 2;
  FontSize = 18;
  LineWidth = 1.2;
  
experimentFolder = '201705ReachBiasData\\SCP-CTRL-01\\SESSIONLOGS\\';
experimentFile = find_all_files(experimentFolder, '*SCP_01.log');                            
nFiles = length(experimentFile);

w = 8; 
endSize = 100;

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

%compute remaining fields of subjects
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

%compute inter-session statistics for each subject
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
  f = figure;
  t2 = uitable(f,'Data',isAssociationEnd, 'RowName',currSubject.partner, 'ColumnName', currSubject.partner);
  t2.Position = [0, 10, t2.Extent(3), t2.Extent(4)];
  tableTitle = ['Association table for last ', num2str(endSize), ' trials of ', currSubject.name, ' sessions'];
  uicontrol('Style', 'text', 'Position', [0 t2.Extent(4) + 10 t2.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');

  t1 = uitable(f,'Data',isAssociation, 'RowName', currSubject.partner, 'ColumnName',currSubject.partner);
  t1.Position = [0, t2.Extent(4) + 50, t1.Extent(3), t1.Extent(4)];
  tableTitle = ['Association table for ', currSubject.name, ' sessions'];
  uicontrol('Style', 'text', 'Position', [0 t2.Extent(4) + t1.Extent(4) + 60 t1.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
  set(f, 'Position', [30 200 max([t1.Extent(3), t2.Extent(3)]) t2.Extent(4) + t1.Extent(4) + 100]);
  
  set( gcf, 'PaperUnits','centimeters' );
  xSize = 30; ySize = 25;
  xLeft = 0; yTop = 0;
  set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
  print ( '-depsc', '-r300', [currSubject.name '_ChoiceDifferenceTables.eps']); 
end  


%plot share of choces
figure;
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
print ( '-depsc', '-r300', 'subjectBias_shareOfChoices.eps'); 

figure;
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
print ( '-depsc', '-r300', 'subjectBias_shareOfChoicesEnd.eps');   

%plot mean and median RT
figure;
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
print ( '-depsc', '-r300', 'subjectBias_RT.eps'); 



%plot median RT for left and right targets
figure;
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
print ( '-depsc', '-r300', 'subjectBias_RTbias.eps'); 



%correlations of RT
figure;
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
print ( '-depsc', '-r300', 'subjectBias_RTcorr.eps'); 

figure;
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
print ( '-depsc', '-r300', 'subjectBias_RTcorrEnd.eps'); 


tableRowsName = {'corr. reaction time', ...
                 'corr. reaction time (last 100)', ...
                 'corr. release time', ...
                 'corr. release time (last 100)', ...
                 'corr. reaction time for joint trials', ...
                 'corr. release time for joint trials', ...
                 'corr. jointChoice With DeltaReactionTime', ...
                 'corr. jointChoice With DeltaReactionTime (last 100)', ...
                 'corr. jointChoice With DeltaReleaseTime', ...
                 'corr. jointChoice With DeltaReleaseTime (last 100)'};
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
  
  textHeight = 30;
  f = figure;
  t = uitable(f,'Data',dataTable,  'ColumnName', currSubject.partner(subject(iSubject).sessionType > 0), 'RowName', tableRowsName);
  t.Position = [0, 10, t.Extent(3), t.Extent(4)];
  tableTitle = ['Parameters for the dual sessions of ', currSubject.name, ' sessions'];
  uicontrol('Style', 'text', 'Position', [0 t.Extent(4) + 10 t.Extent(3) textHeight], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
  set(f, 'Position', [30 200 t.Extent(3) t.Extent(4) + 100]);

  set( gcf, 'PaperUnits','centimeters' );
  xSize = 30; ySize = 25;
  xLeft = 0; yTop = 0;
  set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ], 'PaperPositionMode', 'auto' );
  print ( '-depsc', '-r300', [currSubject.name '_OtherParameters.eps']); 
end  
%{
%}
