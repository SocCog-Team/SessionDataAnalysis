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
  if (freeSession(iFile).nCorrectTrial < endSize)
    continue;
  end  
  for iPlayer = 1:basicSessionData(iFile).nPlayer
    if (basicSessionData(iFile).nPlayer > 1)
      sideOfPlayer = iPlayer;
    else
      sideOfPlayer = 0;
    end
    
    if (nSubject > 0)
      iSubject = find(strcmp({subject.name}, basicSessionData(iFile).playerName{iPlayer}));
      if (isempty(iSubject))
        iSubject = 0;
      end  
    end  
    if (iSubject == 0)
      nSubject = nSubject + 1;
      subject(nSubject) = struct('name', basicSessionData(iFile).playerName{iPlayer}, ...
                                 'sessionIndex', iFile, ...
                                 'sessionType', sideOfPlayer, ...
                                 'nSession', 1);
    else
      subject(iSubject).sessionIndex = [subject(iSubject).sessionIndex, iFile];
      subject(iSubject).sessionType = [subject(iSubject).sessionType, sideOfPlayer];
      subject(iSubject).nSession = subject(iSubject).nSession + 1;
    end  
  end
end

contigencyMatrix = zeros(2);
contigencyMatrixEnd = zeros(2);
for iSubject = 1:nSubject
  currSubject = subject(iSubject);
  partnerList = cell(currSubject.nSession, 1);
  isAssociation = zeros(currSubject.nSession);
  isAssociationEnd = zeros(currSubject.nSession);
  for iSession = 1:currSubject.nSession
    currSessionIndex = currSubject.sessionIndex(iSession);
    if (currSubject.sessionType(iSession) > 0)
      sideOfPartner = bitxor(currSubject.sessionType(iSession), 3); %bitxor(1,3) = 2, bitxor(2,3) = 1
      partnerList(iSession) = basicSessionData(currSessionIndex).playerName{sideOfPartner};
    else  
      partnerList{iSession} = 'none';
    end
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
  f = figure;
  t = uitable(f,'Data',isAssociation, 'RowName', partnerList, 'ColumnName',partnerList);
  t.Position = [0, 10, t.Extent(3), t.Extent(4)];
  tableTitle = ['Association table for ', currSubject.name, ' sessions'];
  uicontrol('Style', 'text', 'Position', [0 t.Extent(4) + 10 500 30], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
  
  f = figure;
  t = uitable(f,'Data',isAssociationEnd, 'RowName',partnerList, 'ColumnName', partnerList);
  t.Position = [0, t.Extent(4) - 20, t.Extent(3), t.Extent(4)];
  tableTitle = ['Association table for last ', num2str(endSize), ' trials of ', currSubject.name, ' sessions'];
  uicontrol('Style', 'text', 'Position', [0 t.Extent(4) + 10 500 30], 'String', tableTitle, 'fontsize', FontSize, 'FontName', 'Times');
end  

