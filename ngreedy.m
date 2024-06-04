function [allsequences,bestsequence,cost] = ngreedy(n,mpc,removedbuses,cutlines)
%Programming the n + greedy approach
% This approach entails finding all of the n long sequences for bus
% restoration before finding the best one, and continuing to add the best
% one from there on after. You end up doing around
% busesremoved!/(busesremoved-n)!
define_constants;

%create a struct of the sequences for the current iteration
cursequences = repmat(struct('sequence', [], 'loss', 0), size(removedbuses, 1), 1);
%create a struct of the sequences for the next iteration
allsequences = cell(removedbuses, 1);
for i=1:n
    for j=1:size(cursequences, 1)
        for k=1:size(removedbuses, 1)
            if ~ismember(removedbuses(k, 1), cursequences(j).sequence) %check if bus is not already in the sequence
                toaddsequence = [cursequences(j).sequence; removedbuses(k, 1)]; %new sequence
                totalloss = addbusandsim(mpc, removedbuses, cutlines, toaddsequence); %get total loss of buses using this sequence and the next bus
                if j==1 && k==1 %create newsequence on first go through
                    newsequences = struct('sequence', toaddsequence, 'loss', cursequences(j).loss + totalloss);
                else %append to newsequences
                    newsequences = [newsequences; struct('sequence', toaddsequence, 'loss', cursequences(j).loss + totalloss)];
                end
            end
        end
    end
    allsequences{i} = newsequences; %save sequences so we don't lose information
    cursequences = newsequences; %update cursequences for the next iteration
end

sequencecosts = [cursequences.loss];
[~, idx] = min(sequencecosts);
cursequence = cursequences(idx);

for i=n+1:size(removedbuses, 1)
    for j=1:size(removedbuses,1) %I could add another loop if we're iterating through more than one previous sequence
        if ~ismember(removedbuses(j, 1), cursequence.sequence)
            toaddsequence = [cursequence.sequence; removedbuses(j, 1)];
            totalloss = addbusandsim(mpc, removedbuses, cutlines, toaddsequence);
            if j==1
                newsequences = struct('sequence', toaddsequence, 'loss', cursequence.loss + totalloss);
            else
                newsequences = [newsequences; struct('sequence', toaddsequence, 'loss', cursequence.loss + totalloss)];
            end
        end
    end
    allsequences{i} = newsequences;
    sequencecosts = [newsequences.loss];
    [~, idx] = min(sequencecosts);
    cursequence = newsequences(idx);
end

bestsequence = cursequence.sequence;
cost = cursequence.loss;

end %end of function