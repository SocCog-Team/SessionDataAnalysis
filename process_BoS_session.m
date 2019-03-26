%{
function process_BoS_session computes characteristics of informed sessions where
  2 players are engaged in a vertical Bach-or-Stravinsky game 
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
  
  ownTargetType - type of own target to be searched in chosenTarget  
  minJoinReward - minimal reward value obtained for cooperation 
  endSize - number of "stationary" successful trials taken from the end of the session
  w - window length for averaging
  
OUTPUT:    
  res - structure with information on the informed trials outcomes
    endSize - stored value of the 'endSize',
  (the following fields contain info on successful informed trials only)
    'ownChoice' - whether own (more benefitial target) was selected;
    'positiveReward' - reward value for the trial; 
    'bottomChoice' - whether bottom target was selected;
    'reactionTime' - time from target onset to reaching the target;
    'decisionTime' - time from target onset to fixation release;
    'dltReactionTime' - reactionTime of Player 1 - reactionTime of Player 2
    'dltDecisionTime' - decisionTime of Player 1 - decisionTime of Player 2
    'meanReward' - mean reward obtained by the two players;
    'jointChoice' - whether the same target was selected;
  (values in the following fields are computed in overlapping windows of 'w' trials)  
    'ownChoiceAverage' - rate of selecting own target;
    'bottomChoiceAverage' - rate of selecting bottom target;
    'meanRewardAverage' - average reward of two players;
  (values in the following fields are computed either over all trials or over 
   the last 'endSize' trials, the latter case is indicated by suffix 'End')    
    'shareError'
    'shareErrorEnd'  - share of errorneous informed trials;
    'shareOwnChoices'
    'shareOwnChoicesEnd'  - share of own choices;
    'shareJointChoices' 
    'shareJointChoicesEnd' - share of joint choices                     
    'shareBottomChoices' 
    'shareBottomChoicesEnd' - share of bottom choices
    'shareFirstChoices'
    'shareFirstChoicesEnd',  - share of trials where Player 1 reached the target earlier;       
    'ownAfterOwnCondProp'
    'ownAfterOwnCondPropEnd' - share of own choices that are followed by another own choice;                       
    'rewardMeanValue' 
    'rewardMeanValueEnd' - mean reward obtained by the two players;                       
    'shareBottomChoicesAmongOwn'
    'shareBottomChoicesAmongOwnEnd' - share of own choices that are also bottom choices;          
%}
function res = process_BoS_session(session, ownTargetType, minJoinReward, endSize, w)
  %(reward, choice, topReach, reactionTime, experimentName, w)

  MA_filter = ones(1, w);
  FontSize = 18;
  LineWidth = 1.2;
  
  %consider only successful informed trials (they are the same for both)        
  correctIndices = find((session.trialStatus(1, :) == session.TRIAL_STATUS.SUCCESS) & ...
                        (session.trialType(1, :) == session.TRIAL_TYPE.INFORMED)); 
  nCorrectTrial = length(correctIndices);
  endSize = min(endSize, nCorrectTrial);
  nAveragedTrial = nCorrectTrial - w + 1;

  res = struct('endSize', endSize, ... 
               'ownChoice', zeros(session.nPlayer, nCorrectTrial), ...
               'positiveReward', zeros(session.nPlayer, nCorrectTrial), ...
               'bottomChoice', zeros(session.nPlayer, nCorrectTrial), ...
               'reactionTime', zeros(session.nPlayer, nCorrectTrial), ...
               'decisionTime', zeros(session.nPlayer, nCorrectTrial), ...
               'dltReactionTime', zeros(1, nCorrectTrial), ...
               'dltDecisionTime', zeros(1, nCorrectTrial), ...               
               'meanReward', zeros(1, nCorrectTrial),...
               'jointChoice', zeros(1, nCorrectTrial),...                    
               'ownChoiceAverage', zeros(session.nPlayer, nAveragedTrial), ...
               'bottomChoiceAverage', zeros(session.nPlayer, nAveragedTrial), ...
               'meanRewardAverage', zeros(1, nAveragedTrial),...             
               'shareError',  0, ...
               'shareErrorEnd',  0, ...                     
               'shareOwnChoices', zeros(session.nPlayer, 1), ... 
               'shareOwnChoicesEnd', zeros(session.nPlayer, 1), ...   
               'shareJointChoices', zeros(session.nPlayer, 1), ... 
               'shareJointChoicesEnd', zeros(session.nPlayer, 1), ...                        
               'shareBottomChoices', zeros(session.nPlayer, 1), ... 
               'shareBottomChoicesEnd', zeros(session.nPlayer, 1), ...  
               'shareFirstChoices', 0, ... 
               'shareFirstChoicesEnd', 0, ...                 
               'ownAfterOwnCondProp', zeros(session.nPlayer, 1), ... 
               'ownAfterOwnCondPropEnd', zeros(session.nPlayer, 1), ...                        
               'rewardMeanValue', 0, ... 
               'rewardMeanValueEnd', 0, ...                        
               'shareBottomChoicesAmongOwn', zeros(session.nPlayer, 1), ... 
               'shareBottomChoicesAmongOwnEnd', zeros(session.nPlayer, 1));            
    
  res.positiveReward = session.reward(:, correctIndices);
  res.meanReward = sum(res.positiveReward, 1)/session.nPlayer;
  res.rewardMeanValue = mean(res.meanReward);
  res.rewardMeanValueEnd = mean(res.meanReward(end-endSize+1:end));
  res.meanRewardAverage = conv(res.meanReward, MA_filter, 'valid')/w; 
  
  %set jointChoice to 1 for those trials where reward was above joinReward
  res.jointChoice = (res.meanReward > minJoinReward);
  res.shareJointChoices = mean(res.jointChoice, 2);
  res.shareJointChoicesEnd = mean(res.jointChoice(end-endSize+1:end), 2);

  res.shareError = (session.nTrial - nCorrectTrial)/session.nTrial;
  res.shareErrorEnd = (endSize - length(find(correctIndices > session.nTrial - endSize)))/endSize;   
  
  %set ownChoice to 1 for those trials where own preferred target was chosen
%  res.ownChoice(1, session.chosenTarget(1, correctIndices) == TARGET_TYPE.TYPE1) = 1;
%  res.ownChoice(2, session.chosenTarget(2, correctIndices) == TARGET_TYPE.TYPE2) = 1;
  res.ownChoice = 1 - bitand(session.positiveReward, 1); %1 - bitand(2,1) = 1 - bitand(4,1) = 1 
                                                         %1 - bitand(1,1) = 1 - bitand(3,1) = 0  
  res.shareOwnChoices = mean(res.ownChoice, 2);
  res.shareOwnChoicesEnd = mean(res.ownChoice(:, end-endSize+1:end), 2);

  %set bottomChoice to 1 for those trials where top target was chosen
  res.bottomChoice(abs(session.chosenPos(:, correctIndices) - session.TARGET_POS.BOTTOM) < 2) = 1; 
  res.shareBottomChoices = mean(res.bottomChoice, 2);
  res.shareBottomChoicesEnd = mean(res.bottomChoice(:, end-endSize+1:end), 2);
  
  %compute share of own choices that fall to the bottom target
  bottomChoicesAmongOwn = res.ownChoice & res.bottomChoice;
  res.shareBottomChoicesAmongOwn = mean(bottomChoicesAmongOwn, 2)./res.shareOwnChoices;
  res.shareBottomChoicesAmongOwnEnd = mean(bottomChoicesAmongOwn, 2)./res.shareOwnChoicesEnd;

  % compute reaction times in sec and compute their differences
  res.reactionTime = (session.moveTime(:, correctIndices) + session.decisionTime(:, correctIndices))/1000;
  res.decisionTime = session.decisionTime(:, correctIndices)/1000;
  res.dltReactionTime = res.reactionTime(1,:) - res.reactionTime(2,:);
  res.dltDecisionTime = res.decisionTime(1,:) - res.decisionTime(2,:);
  
  %compute share of cases when first playe was first, i.e. his total RT was lower
  firstChoices = zeros(1, nCorrectTrial);
  firstChoices(res.dltReactionTime + res.dltMoveTime < 0) = 1;  
  res.shareFirstChoices = mean(firstChoices);
  res.shareFirstChoicesEnd = mean(firstChoices(end-endSize+1:end));
  
  for iPlayer = 1:session.nPlayer
    res.ownChoiceAverage(iPlayer, :) = conv(res.ownChoice(iPlayer, :), MA_filter, 'valid')/w;
    res.bottomChoiceAverage(iPlayer, :) = conv(res.bottomChoice(iPlayer, :), MA_filter, 'valid')/w;  

    isOwnChosen = zeros(1, session.nTrial);
    isOwnChosen((session.chosenTarget(iPlayer, :) == ownTargetType) & ...
                (session.trialType == session.TRIAL_TYPE.FREE) & ... 
                (session.trialStatus == session.TRIAL_STATUS.SUCCESS)) = 1;
    for iTrial = 1:session.nTrial-1
      if (isOwnChosen(iTrial) == 1) && (isOwnChosen(iTrial + 1) == 1)
        res.ownAfterOwnCondProp(iPlayer) = res.ownAfterOwnCondProp(iPlayer) + 1;
        if (iTrial >= session.nTrial-endSize+1)
          res.ownAfterOwnCondPropEnd(iPlayer) = res.ownAfterOwnCondPropEnd(iPlayer) + 1;
        end  
      end  
    end 
    res.ownAfterOwnCondProp = res.ownAfterOwnCondProp/sum(isOwnChosen(1:session.nTrial-1), 2);
  end

  %compute amount of own choices among last 100 successful trial except the final trial
  %(which cannot be followed by any trial)
  denomEnd = sum(find(res.ownChoice(:, nCorrectTrial - endSize + 1:end-1) > 0)); 
  res.ownAfterOwnCondPropEnd = res.ownAfterOwnCondPropEnd/denomEnd;     

  %plot aveerage reward values
  xt = w:nCorrectTrial;
  figure
  set( axes,'fontsize', FontSize, 'FontName', 'Times');
  plot (xt, res.meanRewardAverage, 'm', 'linewidth', LineWidth);  
  axis( [w, nCorrectTrial, 1.5, 3.6] );
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' average reward ', 'fontsize', FontSize, 'FontName', 'Times');
  set( gcf, 'PaperUnits','centimeters' );
  xSize = 24; ySize = 12;
  xLeft = 0; yTop = 0;
  set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
  print ( '-depsc', '-r300', [session.name '_rewards.eps']); 

  %plot own choice rates 
  figure
  set( axes,'fontsize', FontSize, 'FontName', 'Times');
  hold on;
  plot (xt, res.ownChoiceAverage(1, :), 'r--', 'linewidth', LineWidth+1);
  plot (xt, res.ownChoiceAverage(2, :), 'b', 'linewidth', LineWidth);  
  hold off;
  legend('Player 1', 'Player 2', 'location', 'NorthWest');
  axis tight;
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' Share of own choices ', 'fontsize', FontSize, 'FontName', 'Times');
  set( gcf, 'PaperUnits','centimeters' );
  xSize = 24; ySize = 12;
  xLeft = 0; yTop = 0;
  set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
  print ( '-depsc', '-r300', [session.name '_choices.eps']); 
  
  
  %plot difference of reaction Times 
  figure
  set( axes,'fontsize', FontSize, 'FontName', 'Times');
	subplot(3, 1, 1);
  hold on;
  plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
  plot (1:nCorrectTrial, res.dltReactionTime + res.dltMoveTime, 'b', 'linewidth', LineWidth); 
  hold off;  
  title('\Delta Total reaction time') 
  axis tight;
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

  subplot(3, 1, 2);
  hold on;
  plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
  plot (1:nCorrectTrial, res.dltReactionTime, 'b', 'linewidth', LineWidth);
  hold off;  
  title('\Delta Decision time') 
  axis tight;
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');
  
  subplot(3, 1, 3);
  hold on;
  plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
  plot (1:nCorrectTrial, res.dltMoveTime, 'b', 'linewidth', LineWidth);
  hold off;
  title('\Delta Movement time') 
  axis tight;
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');
  
  set( gcf, 'PaperUnits','centimeters' );
  xSize = 24; ySize = 12;
  xLeft = 0; yTop = 0;
  set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
  print ( '-depsc', '-r300', [session.name '_RT.eps']); 
 
  
  %plot own choice rate of Player 2 vs Player 1 and indicate directions of changes
  dOwnRate = zeros(session.nPlayer, nAveragedTrial);
  for iPlayer = 1:session.nPlayer   
    dOwnRate(iPlayer, 1:end-1) = (res.ownChoiceAverage(iPlayer, 2:end) ...
                                    - res.ownChoiceAverage(iPlayer, 1:end-1))/10;    
    %changeValue = ((1:nAveragedTrial) - nAveragedTrial/2)/(10*w*nAveragedTrial);
  end  
  %dZfictive = zeros(nAveragedTrial, 1);
  %dZindices = (1:nAveragedTrial)'/nAveragedTrial;
  nTrajPlotPos = w + 1; %positions may have values from 0 to 1 with step 1/w
  nCountourPoints = nTrajPlotPos + 2; %we take to additional points at borders to make countours visible
  dimTransition = 3; %transition in each direction is either -1, 0 or +1
  contourIndices = (-1:w+1)/w;
  rateValueFrequency = zeros(nCountourPoints);
  transitionFreq = zeros(nTrajPlotPos, nTrajPlotPos, dimTransition^2);
  for iTrial = 1:nAveragedTrial   
    xIndex = floor(w*res.ownChoiceAverage(1, iTrial)) + 2;
    yIndex = floor(w*res.ownChoiceAverage(2, iTrial)) + 2;  
    if (iTrial > 1)
      transitionIndex = (xIndex - xIndexLast)*dimTransition + yIndex - yIndexLast + 1;
      transitionFreq(xIndexLast, yIndexLast, transitionIndex) = ...
          transitionFreq(xIndexLast, yIndexLast, transitionIndex) + 1;
    end      
    rateValueFrequency(yIndex, xIndex) = rateValueFrequency(yIndex, xIndex) + 1;
    xIndexLast = xIndex - 1;
    yIndexLast = yIndex - 1;   
  end  
  for i = 1:nTrajPlotPos
    for j = 1:nTrajPlotPos
      transitionFreq(i, j, 5) = 0; %ignore remaining at the same value
      denom = max(transitionFreq(i, j, :));
      if denom > 0
        transitionFreq(i, j, :) = transitionFreq(i, j, :)/denom;
      end  
    end
  end 
  %multiply each vector of rate by it's relative frequency
  xIndex = floor(w*res.ownChoiceAverage(1, 1)) + 2;
  yIndex = floor(w*res.ownChoiceAverage(2, 1)) + 2;  
  for iTrial = 2:nAveragedTrial
    xIndexLast = xIndex - 1;
    yIndexLast = yIndex - 1;        
    xIndex = floor(w*res.ownChoiceAverage(1, iTrial)) + 2;
    yIndex = floor(w*res.ownChoiceAverage(2, iTrial)) + 2;  
    transitionIndex = (xIndex - xIndexLast)*dimTransition + yIndex - yIndexLast + 1;
    for iPlayer = 1:session.nPlayer
      dOwnRate(iPlayer, iTrial - 1) = dOwnRate(iPlayer, iTrial - 1)*transitionFreq(xIndexLast, yIndexLast, transitionIndex);
    end  
  end  
  %{
  figure
  set( axes,'fontsize', FontSize, 'FontName', 'Times');
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' frequency of choosing red for the Player 1', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' frequency of choosing blue for the Player 2 ', 'fontsize', FontSize, 'FontName', 'Times');
  comet(ownProbAverage1, ownProbAverage2);
  %}
  
  figure
  %subplot(2,2,1) 
  set( axes,'fontsize', FontSize, 'FontName', 'Times');
  hold on;
  contour(contourIndices, contourIndices, rateValueFrequency);
  quiver(res.ownChoiceAverage(1, :), res.ownChoiceAverage(2, :), dOwnRate(1,:), dOwnRate(2,:), 'b', 'linewidth', LineWidth);
  hold off;
  axis tight;
  set( gca, 'fontsize', FontSize, 'FontName', 'Times');
  xlabel( ' Share of own choices for the 1st player ', 'fontsize', FontSize, 'FontName', 'Times');
  ylabel( ' Share of own choices for the 2nd player ', 'fontsize', FontSize, 'FontName', 'Times');

  set( gcf, 'PaperUnits','centimeters' );
  xSize = 24; ySize = 24;
  xLeft = 0; yTop = 0;
  set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );  
  print ( '-depsc', '-r300', [session.name '_choicesXY.eps']);     
end

    