function [allsequences,bestsequence,cost] = ngreedy(n,mpc,removedbuses,cutlines, origloss)
%Programming the n + greedy approach
% This approach entails finding all of the n long sequences for bus
% restoration before finding the best one, and continuing to add the best
% one from there on after. You end up doing around
% busesremoved!/(busesremoved-n)!
define_constants;

%create a struct of the sequences for the current iteration
cursequences = repmat(struct('sequence', [], 'cost', 0, 'lossafteriter', origloss, 'totalrestored', 0, 'iterrestored', 0), 1, 1);
%create a struct of the sequences for the next iteration
allsequences = cell(size(removedbuses, 1), 1);
newsequences = 0;
for i=1:n
    for j=1:size(cursequences, 1)
        for k=1:size(removedbuses, 1)
            if ~ismember(removedbuses(k, 1), cursequences(j).sequence) %check if bus is not already in the sequence
                toaddsequence = [cursequences(j).sequence; removedbuses(k, 1)]; %new sequence
                lossafteriter = addbusandsim(mpc, removedbuses, cutlines, toaddsequence); %get total loss of buses using this sequence
                if isa(newsequences, 'double') %create newsequence on first go through. Please find a better way to do this
                    newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + lossafteriter, 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', cursequences(j).lossafteriter - lossafteriter);
                else %append to newsequences
                    newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + lossafteriter, 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', cursequences(j).lossafteriter - lossafteriter)];
                end
            end
        end
    end
    allsequences{i} = newsequences; %save sequences so we don't lose information
    cursequences = newsequences; %update cursequences for the next iteration
    newsequences = 0;
end
%may want to add lossafteriter thing so we see the loss of each iteration in
%allsequences
sequencecosts = [cursequences.cost];
[~, idx] = min(sequencecosts);
cursequence = cursequences(idx);

for i=n+1:size(removedbuses, 1)
    for j=1:size(removedbuses,1) %I could add another loop if we're iterating through more than one previous sequence
        if ~ismember(removedbuses(j, 1), cursequence.sequence)
            toaddsequence = [cursequence.sequence; removedbuses(j, 1)];
            lossafteriter = addbusandsim(mpc, removedbuses, cutlines, toaddsequence);
            if isa(newsequences, 'double')
                newsequences = struct('sequence', toaddsequence, 'cost', cursequence.cost + lossafteriter, 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', cursequence.lossafteriter - lossafteriter);
            else
                newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequence.cost + lossafteriter, 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', cursequence.lossafteriter - lossafteriter)];
            end
        end
    end
    allsequences{i} = newsequences;
    sequencecosts = [newsequences.cost];
    [~, idx] = min(sequencecosts);
    cursequence = newsequences(idx);
    newsequences = 0;
end

bestsequence = cursequence.sequence;
cost = cursequence.cost;

end %end of function