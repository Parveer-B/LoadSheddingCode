function [allsequences,bestsequence,cost] = keepx(keepn,mpc,removedbuses,cutlines, origloss)
%Greedy but instead of keeping the best sequence, we keep the best n
%sequences before continuing
%   Detailed explanation goes here
define_constants;
%create a struct of the sequences for the current iteration
cursequences = repmat(struct('sequence', [], 'cost', 0, 'mockcost' ,0, 'lossafteriter', origloss, 'totalrestored', 0, 'iterrestored', 0, 'totaltime', 0), 1, 1);
%create a struct of the sequences for the next iteration
allsequences = cell(size(removedbuses, 1), 1);
newsequences = 0;
for i=1:size(removedbuses, 1)-1
    for j=1:size(cursequences, 1)
        for k=1:size(removedbuses, 1)
            if ~ismember(removedbuses(k, 1), cursequences(j).sequence) %check if bus is not already in the sequence
                toaddsequence = [cursequences(j).sequence; removedbuses(k, 1)]; %new sequence
                lossafteriter = addbusandsim(mpc, removedbuses, cutlines, toaddsequence); %get total loss of buses using this sequence
                lines1 = size(cutlines(cutlines(:, T_BUS) == removedbuses(k, 1), :), 1);
                lines2 = size(cutlines(cutlines(:, F_BUS) == removedbuses(k, 1), :), 1);
                iterrestored = cursequences(j).lossafteriter - lossafteriter;
                totalrestored = origloss - lossafteriter;
                totaltime = cursequences(j).totaltime + lines1 + lines2;
                if isa(newsequences, 'double') %create newsequence on first go through. Please find a better way to do this
                    newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2),'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime);
                else %append to newsequences
                    newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime)];
                end
            end
        end
    end
    if i==size(removedbuses, 1)-1 %if it's the second last iter, just keep all of them, we aren't running more sims
         allsequences{i} = newsequences;
         cursequences = newsequences;
         newsequences = 0;
    else
        allsequences{i} = newsequences; %save sequences so we don't lose information
        sequencecosts = [newsequences.mockcost];
        [~, idxs] = maxk(sequencecosts, keepn);
        cursequences = newsequences(idxs); %update cursequences for the next iteration
        newsequences = 0;
    end
end

%do the last iteration here, can be done without simming. This assumes there was no load shed to begin with
for j=1:size(cursequences, 1)
    bustoadd = setdiff(removedbuses(:, 1),cursequences(j).sequence);
    toaddsequence = [cursequences(j).sequence; bustoadd];
    lines1 = size(cutlines(cutlines(:, T_BUS) == bustoadd, :), 1);
    lines2 = size(cutlines(cutlines(:, F_BUS) == bustoadd, :), 1);
    lossafteriter = 0;
    iterrestored = cursequences(j).lossafteriter - lossafteriter;
    totaltime = cursequences(j).totaltime + lines1 + lines2;
    totalrestored = origloss - lossafteriter;
    if isa(newsequences, 'double')
        newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime);
    else
        newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime)];
    end
end

allsequences{end} = newsequences;
sequencecosts = [newsequences.cost];
[~, idx] = min(sequencecosts);
cursequence = newsequences(idx);

bestsequence = cursequence.sequence;
cost = cursequence.cost;

end