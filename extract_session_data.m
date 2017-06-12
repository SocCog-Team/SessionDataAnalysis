%{
INPUT:  
  fileName - the name of the file with the path but without extention
  isVerticalTest - temporally used to indicate whether targets were aligned vertically 
                   (vertical BoS game) or horizontally (free choice trials)
OUTPUT:
  session -  structure with fields
    TARGET_TYPE - structure with named fields storing types of target presented during session;
    TARGET_POS - structure with positions where targets were presented during session,
                 contains named field for each of the target as well as a list of targets 'ALL';
                 (currently not provided in files and is determed using 'isVerticalTest' input variable) 
    TRIAL_TYPE - structure with possible trial types. Taken from the file, defauld values are:
              0 - 'NONE', 1 - 'INSTRUCTED', 2 - 'FREE', 3 - 'INFORMED';
    TRIAL_STATUS - structure with possible trial statuses: 
              1 - 'SUCCESS', 0 - 'OTHER', -1 - 'ERROR';
    name - name associated with the session;   
    nPlayer - number of players (either 1 or 2), 
              corresponds to the length of the 2nd dimension for the arrays below
    nTrial - number of trials 
              corresponds to the length of the 1st dimension for the arrays below
    playerName - initially entered names of players;       
    releaseTime - array of times from presentation of the target till fixation point release
    moveTime - array of times from fixation point release till target reach
    reward - array of Rewards for trials
    chosenTarget - array of chosen target type indices (temporally is not used)
    chosenPos - array of chosen target positions indices
    trialType - array of trial types (with values from to TRIAL_TYPE);
    trialStatus - array of trial statuses (with values from to TRIAL_STATUS);
%}

function session = extract_session_data(fullFileName, isVerticalTest)
  [pathStr, fileName, ~] = fileparts(fullFileName); 

  matFilename = [pathStr '\\' fileName '.mat'];
  if exist(matFilename, 'file')
    load(matFilename, 'logData');      
  else
    logData = fnParseEventIDEReportSCPv06([pathStr '\\' fileName '.log']);
    save(matFilename, 'logData'); 
  end  
  
  %OUTCOME_REWARD = getValue(logData.Enums.Outcomes.EnumStruct, 'REWARD');
  [numTrial, ~] = size(logData.data); %first dimension corresponds to number of trials

  
  %determine number of players (1 or 2)
  subject = {logData.StartUpVariables.Subject_A, logData.StartUpVariables.Subject_B};
  noSubject1 = (strcmp(subject{1}, 'none') || strcmp(subject{1}, ''));
  noSubject2 = (strcmp(subject{2}, 'none') || strcmp(subject{2}, ''));
  if noSubject1 || noSubject2
    nSubject = 1; 
    if noSubject2
      indexPlayer1 = 1;
      indexPlayer2 = 1;
    else
      indexPlayer1 = 2;
      indexPlayer2 = 2;
    end    
  else    
    nSubject = 2;
    indexPlayer1 = 1;
    indexPlayer2 = 2;     
  end  


  session = struct('TARGET_TYPE', struct('TYPE1', 0, 'TYPE2', 1), ...
                   'TARGET_POS', struct('ALL', [0, 0]), ...
                   'TRIAL_TYPE', struct('NONE', 0, 'INSTRUCTED', 1, 'FREE', 2, 'INFORMED', 3), ...
                   'TRIAL_STATUS', struct('SUCCESS', 1, 'OTHER', 0, 'ERROR', -1), ...
                   'nPlayer', nSubject, ...
                   'nTrial', numTrial, ...
                   'name', ' ', ... 
                   'releaseTime', zeros(nSubject, numTrial),...                    
                   'moveTime', zeros(nSubject, numTrial), ...                    
                   'reward', zeros(nSubject, numTrial), ...
                   'chosenTarget', zeros(nSubject, numTrial), ...
                   'chosenPos', zeros(nSubject, numTrial),...
                   'trialType', zeros(1, numTrial), ...                   
                   'trialStatus', zeros(1, numTrial));     
  session.playerName = cell(nSubject, 1);
                 
  %fill TRIAL_TYPES with actual values
  session.TRIAL_TYPE.NONE = getValue(logData.Enums.TrialTypes.EnumStruct, 'None'); 
  session.TRIAL_TYPE.INSTRUCTED = getValue(logData.Enums.TrialTypes.EnumStruct, 'DirectFreeGazeReaches');
  session.TRIAL_TYPE.FREE = getValue(logData.Enums.TrialTypes.EnumStruct, 'DirectFreeGazeFreeChoice');
  session.TRIAL_TYPE.INFORMED = getValue(logData.Enums.TrialTypes.EnumStruct, 'InformedChoice');

                 
  %change dots to underscores to avoid problems with multiple extentions
  session.name = strrep(fileName, '.', '_'); 
  playerPrefix = {'A', 'B'};
  iPlayer = 1;
  for i = indexPlayer1:indexPlayer2
    session.playerName{iPlayer} = subject{i};

    prefix = playerPrefix{i};
      
    tTargetAppear = getValue(logData, [prefix '_TargetOnsetTime_ms']);
    tInitRelease = getValue(logData, [prefix '_InitialFixationReleaseTime_ms']); 
    tReach = getValue(logData, [prefix '_TargetTouchTime_ms']);
    session.releaseTime(iPlayer, :) = tInitRelease - tTargetAppear;
    session.moveTime(iPlayer, :) = tReach - tInitRelease;
    
    session.reward(iPlayer, :) = getValue(logData, [prefix '_NumberRewardPulsesDelivered_HIT']);
    if (isVerticalTest)
      session.chosenPos(iPlayer, :) = getValue(logData, [prefix '_TouchSelectedTargetPosition_Y']);
      session.TARGET_POS = struct('TOP', 219, 'BOTTOM', 782, 'ALL', [219, 782]);
    else  
      targetXvalues = getValue(logData, [prefix '_TouchSelectedTargetPosition_X']);    
      initXvalues = getValue(logData, [prefix '_TouchInitialFixationPosition_X']); 
      if (i == 1) %player A has basic orientation
        session.chosenPos(iPlayer, targetXvalues < initXvalues) = -1;
        session.chosenPos(iPlayer, targetXvalues > initXvalues) = 1;
      else        %player B has inversed orientation  
        session.chosenPos(iPlayer, targetXvalues < initXvalues) = 1;
        session.chosenPos(iPlayer, targetXvalues > initXvalues) = -1;
      end  
      session.TARGET_POS = struct('LEFT', -1, 'RIGHT', 1, 'ALL', [-1, 1]);
    end  
    
    %NO_OUTCOME, REWARD, ABORT, ABORT_BY_OTHER
    
%  ind3 = find(ismember(report_struct.header, 'A_RandomizedTargetPosition_X'));
%  ind4 = find(ismember(report_struct.header, 'A_RandomizedTargetPosition_Y'));
    iPlayer = iPlayer + 1;
  end  
  session.trialType(:) = getValue(logData, [playerPrefix{indexPlayer1} '_TrialType']);
  trialStatusData = getValue(logData, [playerPrefix{indexPlayer1} '_Outcome']);
  session.trialStatus(session.reward(1, :) > 0) = session.TRIAL_STATUS.SUCCESS;
  session.trialStatus(sum(session.reward(1:nSubject, :)) == 0) = session.TRIAL_STATUS.ERROR;  
end



function value = getValue(s, label)
  value = s.data(:, ismember(s.header, label));
end  