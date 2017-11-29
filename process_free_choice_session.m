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
    releaseTime - array of times from presentation of the target till fixation point release
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
    endSize - stored value of the 'endSize',  
  (the following fields contain info on successful free choice or informed trials only)
    'ownChoice' - whether own (more benefitial target) was selected;
    'reactionTime' - time from target onset to reaching the target;
    'releaseTime' - time from target onset to fixation release;
    'dltReactionTime' - reactionTime of Player 1 - reactionTime of Player 2
    'dltReleaseTime' - releaseTime of Player 1 - releaseTime of Player 2
    'chosenPos' - array of chosen target positions indices
    'jointChoice' - whether the same target was selected;
   
    'jointChoiceAverage' - rate of selecting the same target,
                           computed in overlapping windows of 'w' trials;

   (values in the following fields are computed either over all trials or over 
   the last 'endSize' trials, the latter case is indicated by suffix 'End')    
    'numChoiceOfPos'
    'numChoiceOfPosEnd'  - number of choices of target in a given position (for statistical analysis);
    'shareChoiceOfPos'
    'shareChoiceOfPosEnd'  - share number of choices of target in a given position;
    'medianReactionTime' - median time from target onset to reaching the target
    'medianReleaseTime' - median time from target onset to fixation release
    'shareOfJointChoiceWrtPosition'                 
    'shareOfJointChoiceWrtPositionEnd' - share of joint choices for various target position selected by subject    
    'numJointChoice' 
    'numJointChoiceEnd' - number of joint choices                     
    'shareFirstChoices'
    'shareFirstChoicesEnd',  - share of trials where Player 1 reached the target earlier;       
    'corrReactionTimes', 
    'corrReactionTimesEnd' - correlation of reaction times
    'corrReleaseTimes', 
    'corrReleaseTimesEnd' - correlation of sum of reaction times and move times    
   (correlations of jount choices with ...) 
    'corrJointChoiceWithReactionTime' 
    'corrJointChoiceWithReactionTimeEnd' - ... reaction times for each player
    'corrJointChoiceWithReleaseTime', 
    'corrJointChoiceWithReleaseTimeEnd'  - total reach times for each player
    'corrJointChoiceWithDeltaReactionTime', 
    'corrJointChoiceWithDeltaReactionTimeEnd'  - ... Player 1 reaction time - Player 2 reaction time     
    'corrJointChoiceWithDeltaReleaseTime', 
    'corrJointChoiceWithDeltaReleaseTimeEnd'  - Player 1 total reach time - Player 2 total reach time    
 
!!!Please, note that some of the fields are defined only for 2 players 
%}
function res = process_free_choice_session(session, endSize, w)
	
	SCPDirs = GetDirectoriesByHostName();
	SCPDirs.OutputDir = fullfile(SCPDirs.SCP_DATA_BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', 'ANALYSES', SCPDirs.CurrentHostName);	
	Options.OutFormat = '.pdf';


  MA_filter = ones(1, w);
  FontSize = 18;
  LineWidth = 1.2;
  
  %consider only successful informed trials (they are the same for both)        
  correctIndices = find((session.trialStatus(1, :) == session.TRIAL_STATUS.SUCCESS) & ...
                        (session.chosenPos(1, :) ~= 0) & ...
                        ((session.trialType(1, :) == session.TRIAL_TYPE.FREE)));
%                        ((session.trialType(1, :) == session.TRIAL_TYPE.FREE) | ...
%                         (session.trialType(1, :) == session.TRIAL_TYPE.INFORMED) ) );                       
  nCorrectTrial = length(correctIndices);
  endSize = min(endSize, nCorrectTrial);
  nAveragedTrial = nCorrectTrial - w + 1;
  
  nTarget = length(session.TARGET_POS.ALL);

  res = struct('nTrial',nCorrectTrial, ...
               'endSize', endSize, ... 
               'reactionTime', zeros(session.nPlayer, nCorrectTrial), ...
               'releaseTime', zeros(session.nPlayer, nCorrectTrial), ...             
               'dltReactionTime', zeros(1, nCorrectTrial), ...
               'dltReleaseTime', zeros(1, nCorrectTrial), ...               
               'chosenPos', zeros(session.nPlayer, nCorrectTrial), ...   
               'jointChoice', zeros(1, nCorrectTrial),...     
               'jointChoiceAverage', zeros(1, nAveragedTrial),... 
               'numChoiceOfPos', zeros(session.nPlayer, nTarget), ...               
               'numChoiceOfPosEnd', zeros(session.nPlayer, nTarget), ...
               'shareChoiceOfPos', zeros(session.nPlayer, nTarget), ...
               'shareChoiceOfPosEnd', zeros(session.nPlayer, nTarget), ...           
               'medianReactionTime', zeros(session.nPlayer, nTarget), ...                 
               'medianReleaseTime', zeros(session.nPlayer, nTarget), ...
               'shareOfJointChoiceWrtPosition', zeros(session.nPlayer, nTarget), ...                 
               'shareOfJointChoiceWrtPositionEnd', zeros(session.nPlayer, nTarget), ...               
               'numJointChoice', 0, ... 
               'numJointChoiceEnd', 0, ... 
               'shareFirstChoice', 0, ... 
               'shareFirstChoiceEnd', 0, ...                 
               'corrReactionTimes', 0, ... 
               'corrReactionTimesEnd', 0, ... 
               'corrReleaseTimes', 0, ...                                
               'corrReleaseTimesEnd', 0, ...  
               'corrJointReactionTimes', 0, ...                  
               'corrJointReleaseTimes', 0, ...                                             
               'corrJointChoiceWithReactionTime', zeros(session.nPlayer, 1), ... 
               'corrJointChoiceWithReactionTimeEnd', zeros(session.nPlayer, 1), ... 
               'corrJointChoiceWithReleaseTime', zeros(session.nPlayer, 1), ... 
               'corrJointChoiceWithReleaseTimeEnd', zeros(session.nPlayer, 1), ... 
               'corrJointChoiceWithDeltaReactionTime', 0,...       
               'corrJointChoiceWithDeltaReactionTimeEnd', 0,...       
               'corrJointChoiceWithDeltaReleaseTime', 0,...       
               'corrJointChoiceWithDeltaReleaseTimeEnd', 0);       
  
  % compute reaction times in sec
  res.reactionTime = (session.moveTime(:, correctIndices) + session.releaseTime(:, correctIndices))/1000;
  res.releaseTime = session.releaseTime(:, correctIndices)/1000;
  
  endIndices = nCorrectTrial-endSize+1:nCorrectTrial;
  res.chosenPos = session.chosenPos(:, correctIndices);
  for iPlayer = 1:session.nPlayer
    for iPos = 1:length(session.TARGET_POS.ALL)
      posIndices = (res.chosenPos(iPlayer, :) == session.TARGET_POS.ALL(iPos));
      res.numChoiceOfPos(iPlayer, iPos) = nnz(posIndices);
      res.numChoiceOfPosEnd(iPlayer, iPos) = nnz(posIndices(endIndices));
      res.medianReactionTime(iPlayer, iPos) = median(res.reactionTime(iPlayer, posIndices));
      res.medianReleaseTime(iPlayer, iPos) = median(res.releaseTime(iPlayer, posIndices));
    end
  end
  res.shareChoiceOfPos = res.numChoiceOfPos/nCorrectTrial;
  res.shareChoiceOfPosEnd = res.numChoiceOfPosEnd/endSize;
  
  if (session.nPlayer > 1)    
    %set jointChoice to 1 for those trials where chosen target positions are inverse
    %TODO: add explicit X and Y target coordinates to avoid confusion 
    res.jointChoice(res.chosenPos(1, :) == -res.chosenPos(2, :)) = 1;
    res.numJointChoice = nnz(res.jointChoice);
    res.numJointChoiceEnd = nnz(res.jointChoice(endIndices));
    res.jointChoiceAverage = conv(res.jointChoice, MA_filter, 'valid')/w;
    
    % compute reaction times differences  
    res.dltReactionTime = res.reactionTime(1,:) - res.reactionTime(2,:);
    res.dltReleaseTime = res.releaseTime(1,:) - res.releaseTime(2,:);
  
    %compute share of cases when first playe was first, i.e. his total RT was lower
    firstChoice = zeros(1, nCorrectTrial);
    firstChoice(res.dltReactionTime < 0) = 1;  
    res.shareFirstChoice = mean(firstChoice);
    res.shareFirstChoiceEnd = mean(firstChoice(endIndices));
    
    for iPlayer = 1:session.nPlayer
      for iPos = 1:length(session.TARGET_POS.ALL)
        posIndices = (res.chosenPos(iPlayer, :) == session.TARGET_POS.ALL(iPos));
        res.shareOfJointChoiceWrtPosition(iPlayer, iPos) = nnz(res.jointChoice(posIndices))/max(nnz(posIndices), 1);                
        res.shareOfJointChoiceWrtPositionEnd(iPlayer, iPos) = nnz(res.jointChoice(posIndices(endIndices)))/max(nnz(posIndices(endIndices)), 1);                
      end
    end
    
    res.corrReactionTimes = corr(res.reactionTime(1, :)', res.reactionTime(2, :)');
    res.corrReactionTimesEnd = corr(res.reactionTime(1, endIndices)', res.reactionTime(2, endIndices)');
    res.corrReleaseTimes = corr(res.releaseTime(1, :)', res.releaseTime(2, :)');                               
    res.corrReleaseTimesEnd = corr(res.releaseTime(1, endIndices)', res.releaseTime(2, endIndices)');                                
    res.corrJointReactionTimes = corr(res.reactionTime(1, res.jointChoice > 0)', res.reactionTime(2, res.jointChoice > 0)');
    res.corrJointReleaseTimes = corr(res.releaseTime(1, res.jointChoice > 0)', res.releaseTime(2, res.jointChoice > 0)');                               
    res.corrJointChoiceWithReactionTime(1) = corr(res.reactionTime(1, :)', res.jointChoice');                               
    res.corrJointChoiceWithReactionTime(2) = corr(res.reactionTime(2, :)', res.jointChoice');                               
    res.corrJointChoiceWithReactionTimeEnd(1) = corr(res.reactionTime(1, endIndices)', res.jointChoice(endIndices)');                               
    res.corrJointChoiceWithReactionTimeEnd(2) = corr(res.reactionTime(2, endIndices)', res.jointChoice(endIndices)');                               
    res.corrJointChoiceWithReleaseTime(1) = corr(res.releaseTime(1, :)', res.jointChoice');                               
    res.corrJointChoiceWithReleaseTime(2) = corr(res.releaseTime(2, :)', res.jointChoice');                               
    res.corrJointChoiceWithReleaseTimeEnd(1) = corr(res.releaseTime(1, endIndices)', res.jointChoice(endIndices)');                               
    res.corrJointChoiceWithReleaseTimeEnd(2) = corr(res.releaseTime(2, endIndices)', res.jointChoice(endIndices)');                               
    res.corrJointChoiceWithDeltaReactionTime = corr(res.dltReactionTime', res.jointChoice');                               
    res.corrJointChoiceWithDeltaReactionTimeEnd = corr(res.dltReactionTime(endIndices)', res.jointChoice(endIndices)');                               
    res.corrJointChoiceWithDeltaReleaseTime = corr(res.dltReleaseTime', res.jointChoice');                               
    res.corrJointChoiceWithDeltaReleaseTimeEnd = corr(res.dltReleaseTime(endIndices)', res.jointChoice(endIndices)');                                   
    
    %plot joint choice rates
    xt = w:nCorrectTrial;
    figh = figure('Name', '_choices');
    set( axes,'fontsize', FontSize, 'FontName', 'Times');
    plot (xt, res.jointChoiceAverage, 'b', 'linewidth', LineWidth);  
    axis( [w, nCorrectTrial, 0, 1.0] );
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' Share of joint choices ', 'fontsize', FontSize, 'FontName', 'Times');
    set( gcf, 'PaperUnits','centimeters' );
    xSize = 24; ySize = 12;
    xLeft = 0; yTop = 0;
    set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
	write_out_figure(figh, fullfile(SCPDirs.OutputDir, [session.name, '_choices', Options.OutFormat]));
    %print ( '-depsc', '-r300', [session.name '_choices.eps']); 

    %plot reaction times 
    figh = figure('Name', '_RT');
    set( axes,'fontsize', FontSize, 'FontName', 'Times');
    hold on;
    plot (1:nCorrectTrial, res.releaseTime(1,:), 'r--', 'linewidth', LineWidth); 
    plot (1:nCorrectTrial, res.releaseTime(2,:), 'b--', 'linewidth', LineWidth); 
    plot (1:nCorrectTrial, res.reactionTime(1,:), 'r', 'linewidth', LineWidth); 
    plot (1:nCorrectTrial, res.reactionTime(2,:), 'b', 'linewidth', LineWidth); 
    hold off;  
    axis( [0, nCorrectTrial, 0.15, max(max(res.reactionTime))-0.15]);
    legend([session.playerName{1} ' release time'], [session.playerName{2} ' release time'], [session.playerName{1} ' total reaction time'], [session.playerName{2} ' total reaction time'], 'location', 'NorthWest');    
    title('Reaction times', 'fontsize', FontSize, 'FontName', 'Times'); 
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');
    set( gcf, 'PaperUnits','centimeters' );
    xSize = 24; ySize = 20;
    xLeft = 0; yTop = 0;
    set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
	write_out_figure(figh, fullfile(SCPDirs.OutputDir, [session.name, '_RT', Options.OutFormat]));
    %print ( '-depsc', '-r300', [session.name '_RT.eps']); 


    %plot difference of reaction Times 
    figh = figure('Name', '_deltaRT');
    set( axes,'fontsize', FontSize, 'FontName', 'Times');
    subplot(3, 1, 1);
    hold on;
    plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
    plot (1:nCorrectTrial, res.dltReactionTime, 'b', 'linewidth', LineWidth); 
    hold off;  
    title(['\Delta Total reaction time: ' session.playerName{1} ' - ' session.playerName{2}], 'fontsize', FontSize, 'FontName', 'Times'); 
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    subplot(3, 1, 2);
    hold on;
    plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
    plot (1:nCorrectTrial, res.dltReleaseTime, 'b', 'linewidth', LineWidth);
    hold off;  
    title(['\Delta Release time: ' session.playerName{1} ' - ' session.playerName{2}], 'fontsize', FontSize, 'FontName', 'Times');
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    subplot(3, 1, 3);
    hold on;
    plot (1:nCorrectTrial, zeros(1, nCorrectTrial), 'k--', 'linewidth', 1);  
    plot (1:nCorrectTrial, res.dltReactionTime - res.dltReleaseTime, 'b', 'linewidth', LineWidth);
    hold off;
    title(['\Delta Movement time: ' session.playerName{1} ' - ' session.playerName{2}], 'fontsize', FontSize, 'FontName', 'Times');
    axis tight;
    set( gca, 'fontsize', FontSize, 'FontName', 'Times');
    xlabel( ' Number of trial ', 'fontsize', FontSize, 'FontName', 'Times');
    ylabel( ' time [s] ', 'fontsize', FontSize, 'FontName', 'Times');

    set( gcf, 'PaperUnits','centimeters' );
    xSize = 24; ySize = 30;
    xLeft = 0; yTop = 0;
    set( gcf,'PaperPosition', [ xLeft yTop xSize ySize ] );
	write_out_figure(figh, fullfile(SCPDirs.OutputDir, [session.name, '_deltaRT', Options.OutFormat]));
    %print ( '-depsc', '-r300', [session.name '_deltaRT.eps']); 
 end
end

    