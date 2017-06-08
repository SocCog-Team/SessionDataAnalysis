%{
function process_free_choice_session computes characteristics of free sessions where
  either 1 or 2 players select between two horizontally aligned equivalent targets.
  The statistics computed here can be computed for informed trials as well
INPUT:
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
    decisionTime - array of times from presentation of the target till fixation point release
    moveTime - array of times from fixation point release till target reach
    reward - array of Rewards for trials
    chosenTarget - array of chosen target type indices
    chosenPos - array of chosen target positions indices
    trialType - array of trial types (with values from to TRIAL_TYPE);
    trialStatus - array of trial statuses (with values from to TRIAL_STATUS);    
  
  endSize - number of "stationary" successful trials taken from the end of the session
  w - window length for averaging
  
OUTPUT:    
  res - structure with information on the informed trials outcomes
    nTrial - number of successful free choice or informed trials trials 
              corresponds to the length of the 1st dimension for the arrays below              
  (the following fields contain info on successful free choice or informed trials only)
    'ownChoice' - whether own (more benefitial target) was selected;
    'reactionTime' - time from target onset to reaching the target;
    'decisionTime' - time from target onset to fixation release;
    'dltReactionTime' - reactionTime of Player 1 - reactionTime of Player 2
    'dltDecisionTime' - decisionTime of Player 1 - decisionTime of Player 2
    'jointChoice' - whether the same target was selected;
   
    'jointChoiceAverage' - rate of selecting the same target,
                           computed in overlapping windows of 'w' trials;

   (values in the following fields are computed either over all trials or over 
   the last 'endSize' trials, the latter case is indicated by suffix 'End')    
    'numChoiceOfPos'
    'numChoiceOfPosEnd'  - number of choices of target in a given position (for statistical analysis);
    'shareChoiceOfPos'
    'shareChoiceOfPosEnd'  - share number of choices of target in a given position;
    'numJointChoice' 
    'numJointChoiceEnd' - number of joint choices                     
    'shareFirstChoices'
    'shareFirstChoicesEnd',  - share of trials where Player 1 reached the target earlier;       
    'corrReactionTimes', 
    'corrReactionTimesEnd' - correlation of reaction times
    'corrDecisionTimes', 
    'corrDecisionTimesEnd' - correlation of sum of reaction times and move times    
   (correlations of jount choices with ...) 
    'corrJointChoiceWithReactionTime' 
    'corrJointChoiceWithReactionTimeEnd' - ... reaction times for each player
    'corrJointChoiceWithDecisionTime', 
    'corrJointChoiceWithDecisionTimeEnd'  - total reach times for each player
    'corrJointChoiceWithDeltaReactionTime', 
    'corrJointChoiceWithDeltaReactionTimeEnd'  - ... Player 1 reaction time - Player 2 reaction time     
    'corrJointChoiceWithDeltaDecisionTime', 
    'corrJointChoiceWithDeltaDecisionTimeEnd'  - Player 1 total reach time - Player 2 total reach time    
 
!!!Please, note that some of the fields are defined only for 2 players 
%}
function res = process_free_choice_session(session, endSize, w)
  MA_filter = ones(1, w);
  FontSize = 18;
  LineWidth = 1.2;
  
  %consider only successful informed trials (they are the same for both)        
  correctIndices = find((session.trialStatus(1, :) == session.TRIAL_STATUS.SUCCESS) & ...
                        ((session.trialType(1, :) == session.TRIAL_TYPE.FREE) | ...
                         (session.trialType(1, :) == session.TRIAL_TYPE.INFORMED) ) );                       
  nCorrectTrial = length(correctIndices);
  endSize = min(endSize, nCorrectTrial);
  nAveragedTrial = nCorrectTrial - w + 1;
  
  nTarget = length(session.TARGET_POS.ALL);

  res = struct('nTrial',nCorrectTrial, ...
               'reactionTime', zeros(session.nPlayer, nCorrectTrial), ...
               'decisionTime', zeros(session.nPlayer, nCorrectTrial), ...
               'dltReactionTime', zeros(1, nCorrectTrial), ...
               'dltDecisionTime', zeros(1, nCorrectTrial), ...               
               'jointChoice', zeros(1, nCorrectTrial),...     
               'jointChoiceAverage', zeros(1, nAveragedTrial),... 
               'numChoiceOfPos', zeros(session.nPlayer, nTarget), ...               
               'numChoiceOfPosEnd', zeros(session.nPlayer, nTarget), ...
               'shareChoiceOfPos', zeros(session.nPlayer, nTarget), ...
               'shareChoiceOfPosEnd', zeros(session.nPlayer, nTarget), ...           
               'numJointChoice', 0, ... 
               'numJointChoiceEnd', 0, ... 
               'shareFirstChoice', 0, ... 
               'shareFirstChoiceEnd', 0, ...                 
               'corrReactionTimes', 0, ... 
               'corrReactionTimesEnd', 0, ... 
               'corrDecisionTimes', 0, ...                                
               'corrDecisionTimesEnd', 0, ...                                
               'corrJointChoiceWithReactionTime', 0, ... 
               'corrJointChoiceWithReactionTimeEnd', 0, ... 
               'corrJointChoiceWithDecisionTime', 0, ... 
               'corrJointChoiceWithDecisionTimeEnd', 0, ... 
               'corrJointChoiceWithDeltaReactionTime', 0,...       
               'corrJointChoiceWithDeltaReactionTimeEnd', 0);       
               'corrJointChoiceWithDeltaDecisionTime', 0,...       
               'corrJointChoiceWithDeltaDecisionTimeEnd', 0);       
  
  % compute reaction times in sec
  res.reactionTime = (session.moveTime(:, correctIndices) + session.decisionTime(:, correctIndices))/1000;
  res.decisionTime = session.decisionTime(:, correctIndices)/1000;
  
  endIndices = end-endSize+1:end;
  pos = session.chosenPos(:, correctIndices);
  for iPlayer = 1:session.nPlayer
    for iPos = 1:length(session.TARGET_POS.ALL)
      res.numChoiceOfPos(iPlayer, iPos) = nnz(pos(iPlayer, :) == session.TARGET_POS.ALL(iPos));
      res.numChoiceOfPosEnd(iPlayer, iPos) = nnz(pos(iPlayer, endIndices) == session.TARGET_POS.ALL(iPos));
    end
  end
  res.shareChoiceOfPos = res.numChoiceOfPos/nCorrectTrial;
  res.shareChoiceOfPosEnd = res.numChoiceOfPosEnd/endSize;
  
  if (session.nPlayer > 1)    
    %set jointChoice to 1 for those trials where chosen target positions are the same
    res.jointChoice(pos(1, :) == pos(2, :)) = 1;
    res.numJointChoice = nnz(res.jointChoice);
    res.numJointChoiceEnd = nnz(res.jointChoice(endIndices));
    res.jointChoiceAverage = conv(res.jointChoice, MA_filter, 'valid')/w;
    
    % compute reaction times differences  
    res.dltReactionTime = res.reactionTime(1,:) - res.reactionTime(2,:);
    res.dltDecisionTime = res.decisionTime(1,:) - res.decisionTime(2,:);
  
    %compute share of cases when first playe was first, i.e. his total RT was lower
    firstChoice = zeros(1, nCorrectTrial);
    firstChoice(res.dltReactionTime + res.dltMoveTime < 0) = 1;  
    res.shareFirstChoice = mean(firstChoice);
    res.shareFirstChoiceEnd = mean(firstChoice(endIndices));

    res.corrReactionTimes = corr(res.reactionTime(1, :), res.reactionTime(2, :));
    res.corrReactionTimesEnd = corr(res.reactionTime(1, endIndices), res.reactionTime(2, endIndices));
    res.corrDecisionTimes'= corr(res.decisionTime(1, :), res.decisionTime(2, :));                               
    res.corrDecisionTimesEnd = corr(res.decisionTime(1, endIndices), res.decisionTime(2, endIndices));                                
    res.corrJointChoiceWithReactionTime(1) = corr(res.reactionTime(1, :), res.jointChoice);                               
    res.corrJointChoiceWithReactionTime(2) = corr(res.reactionTime(2, :), res.jointChoice);                               
    res.corrJointChoiceWithReactionTimeEnd(1) = corr(res.reactionTime(1, endIndices), res.jointChoice(endIndices));                               
    res.corrJointChoiceWithReactionTimeEnd(2) = corr(res.reactionTime(2, endIndices), res.jointChoice(endIndices));                               
    res.corrJointChoiceWithDecisionTime(1) = corr(res.decisionTime(1, :), res.jointChoice);                               
    res.corrJointChoiceWithDecisionTime(2) = corr(res.decisionTime(2, :), res.jointChoice);                               
    res.corrJointChoiceWithDecisionTimeEnd(1) = corr(res.decisionTime(1, endIndices), res.jointChoice(endIndices));                               
    res.corrJointChoiceWithDecisionTimeEnd(2) = corr(res.decisionTime(2, endIndices), res.jointChoice(endIndices));                               
    res.corrJointChoiceWithDeltaReactionTime = corr(dltReactionTime, res.jointChoice);                               
    res.corrJointChoiceWithDeltaReactionTimeEnd = corr(dltReactionTime(endIndices), res.jointChoice(endIndices));                               
    res.corrJointChoiceWithDeltaDecisionTime = corr(dltDecisionTime, res.jointChoice);                               
    res.corrJointChoiceWithDeltaDecisionTimeEnd = corr(dltDecisionTime(endIndices), res.jointChoice(endIndices));                                   
    
    %plot joint choice rates
    xt = w:nCorrectTrial;
    figure
    set( axes,'fontsize', FontSize, 'FontName', 'Times');
    plot (xt, res.jointChoiceAverage, 'b', 'linewidth', LineWidth);  
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' Share of joint choices ', 'fontsize', FontSize, 'FontName', 'Times');
    set( gcf, 'PaperUnits','centimeters' );
    xSize = 24; ySize = 12;
    xLeft = 0; yTop = 0;
    set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
    print ( '-depsc', '-r300', [session.name '_choices.eps']); 

    %plot reaction times 
    figure
    set( axes,'fontsize', FontSize, 'FontName', 'Times');
    hold on;
    plot (1:nCorrectTrial, res.reactionTime(1,:), 'r--', 'linewidth', LineWidth); 
    plot (1:nCorrectTrial, res.reactionTime(2,:), 'b--', 'linewidth', LineWidth); 
    plot (1:nCorrectTrial, res.totalReactionTime(1,:), 'r', 'linewidth', LineWidth); 
    plot (1:nCorrectTrial, res.totalReactionTime(2,:), 'b', 'linewidth', LineWidth); 
    hold off;  
    legend([session.playerName{1} 'decision time'], [session.playerName{2} 'decision time'], [session.playerName{1} 'total reaction time'], [session.playerName{2} 'total reaction time'], 'location', 'NorthWest');    
    title('Reaction times') 
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    set( gcf, 'PaperUnits','centimeters' );
    xSize = 24; ySize = 12;
    xLeft = 0; yTop = 0;
    set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
    print ( '-depsc', '-r300', [session.name '_RT.eps']); 


    %plot difference of reaction Times 
    figure
    set( axes,'fontsize', FontSize, 'FontName', 'Times');
    subplot(3, 1, 1);
    hold on;
    plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
    plot (1:nCorrectTrial, res.dltReactionTime + res.dltMoveTime, 'b', 'linewidth', LineWidth); 
    hold off;  
    title(['\Delta Total reaction time: ', session.playerName{1}, ' - ', session.playerName{2}]); 
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    subplot(3, 1, 2);
    hold on;
    plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
    plot (1:nCorrectTrial, res.dltReactionTime, 'b', 'linewidth', LineWidth);
    hold off;  
    title(['\Delta Decision time: ', session.playerName{1}, ' - ', session.playerName{2}]);
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    subplot(3, 1, 3);
    hold on;
    plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
    plot (1:nCorrectTrial, res.dltMoveTime, 'b', 'linewidth', LineWidth);
    hold off;
    title(['\Delta Movement time: ', session.playerName{1}, ' - ', session.playerName{2}]);
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    set( gcf, 'PaperUnits','centimeters' );
    xSize = 24; ySize = 12;
    xLeft = 0; yTop = 0;
    set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
    print ( '-depsc', '-r300', [session.name '_deltaRT.eps']); 
 end
end

    