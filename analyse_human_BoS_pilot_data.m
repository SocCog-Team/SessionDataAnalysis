clear variables;
N_PLAYERS = 2;

experimentFolder = 'human_bos_pilot\\';
experimentName = {'20170425T160951.A_21001.B_22002.SCP_00.log', ...
                  '20170426T102304.A_21003.B_22004.SCP_00.log', ...
                  '20170426T133343.A_21005.B_12006.SCP_00.log', ...
                  '20170427T092352.A_21007.B_12008.SCP_00.log', ...
                  '20170427T132036.A_21009.B_12010.SCP_00.log'};                              
nFiles = length(experimentName);

minJoinReward = 2;
w = 8; 
endSize = 100;
ownTargetType = 1;
isVerticalChoice = true;
for iFile = 1:nFiles
  session(iFile) = extract_session_data([experimentFolder experimentName{iFile}], isVerticalChoice);  
  res(iFile) = process_BoS_session(session(iFile), ownTargetType, minJoinReward, endSize, w);
end

disp([res.shareError]);
disp([res.shareErrorEnd]);
disp([res.shareOwnChoices]);
disp([res.shareOwnChoicesEnd]);
disp([res.shareJointChoices]);
disp([res.shareJointChoicesEnd]);
disp([res.rewardMeanValue]);
disp([res.rewardMeanValueEnd]);
disp([res.ownAfterOwnCondProp]);
disp([res.ownAfterOwnCondPropEnd]);

disp([res.shareBottomChoices]);
disp([res.shareBottomChoicesEnd]);
disp([res.shareBottomChoicesAmongOwn]);
disp([res.shareBottomChoicesAmongOwnEnd]);

disp([res.shareFirstChoices]);
disp([res.shareFirstChoicesEnd]);