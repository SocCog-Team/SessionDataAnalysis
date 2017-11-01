% check_coordination tests whether there is a coordination between two players 
% or if they are making choices ignoring each other 
%
% INPUT
%   - isOwnChoice - 2xN array of booleans 
%     isOwnChoice(i,j) = 1 indicated that player i at trial j selected own target;
%   - sideChoice - 2xN array of booleans 
%     sideChoice(i,j) = 1 indicated that player i at trial j selected side 1;
%
% OUTPUT:
%   - partnerInluenceOnSide - 2-element vector indicating whether the choice
%     of side for player i is influenced by partner choices;
%   - partnerInluenceOnTarget - 2-element vector indicating whether the choice
%     of target for player i is influenced by partner choices;
%
%   if partnerInluenceOnSide(i) == partnerInluenceOnTarget(i) == 1 then
%   the choices of player i are most likely not independent on the choices 
%   of the partner
%

function [partnerInluenceOnSide, partnerInluenceOnTarget] = ...
          check_coordination(isOwnChoice, sideChoice)
  sameChoice = xor(isOwnChoice(1,:), isOwnChoice(2,:));
  partnerInluenceOnSide = zeros(1, 2);
  partnerInluenceOnTarget = zeros(1, 2);  
  for i = 1:2 % loop over players
    for iTable = 1:2 % loop over tables: 1st for targets, 2nd for sides
      if (iTable == 1)
        x = isOwnChoice(i, :);
      else
        x = sideChoice(i, :);
      end  
      nSameCase1 = nnz(x & sameChoice);
      nDifCase1 = nnz(x & (~sameChoice));
      nSameCase2 = nnz((~x) & sameChoice);
      nDifCase2 = nnz((~x) & (~sameChoice));
      
      % first we test whether number of SAME choices is larger than number
      % of choices of each side/target. If yes, this is a clear indication
      % that player tends to choose the same target as the partner
      nSameTotal = nSameCase1 + nSameCase2;
      nTotal = nSameCase1 + nSameCase2 + nDifCase1 + nDifCase2;
      nCaseTotal = max(nSameCase1 + nDifCase1, nSameCase2 + nDifCase2);
      
      p1 = nSameTotal/nTotal;
      p2 = nCaseTotal/nTotal;
      pAver = (p1 + p2)/2;
      z = (p1 - p2)/sqrt((2/nCaseTotal)*pAver*(1-pAver));
      % tests are computed for alpha = 0.01
      if (z > 2.58) % # of SAME choices is significanly larger than of  any side/target
        isInfluence = 1;
      else  % if not - compute fisher test
        contMatrix = [nSameCase1, nSameCase2; nDifCase1, nDifCase2];
        isInfluence = fishertest(contMatrix, 'Alpha',0.01);
      end  
      if (iTable == 1) 
        partnerInluenceOnTarget(i) = isInfluence;
      else  
        partnerInluenceOnSide(i) = isInfluence;        
      end  
    end   
  end  
end
