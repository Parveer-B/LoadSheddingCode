function [allsequences,bestsequence,cost] = ngreedywrestorebsdmockcost(n,mpc,removedbuses,cutlines, origloss)
%Programming the n + greedy approach with new cost function and line based
%restoration times. Restore based mockcost
%   Detailed explanation goes here
define_constants;
%create a struct of the sequences for the current iteration
cursequences = repmat(struct('sequence', [], 'cost', 0, 'mockcost' ,0, 'lossafteriter', origloss, 'totalrestored', 0, 'iterrestored', 0, 'totaltime', 0), 1, 1);
%create a struct of the sequences for the next iteration
allsequences = cell(size(removedbuses, 1), 1);
newsequences = 0;
for i=1:min(n, size(removedbuses, 1)-1)
    for j=1:size(cursequences, 1)
        for k=1:size(removedbuses, 1)
            if ~ismember(removedbuses(k, 1), cursequences(j).sequence) %check if bus is not already in the sequence
                toaddsequence = [cursequences(j).sequence; removedbuses(k, 1)]; %new sequence
                lossafteriter = addbusandsim(mpc, removedbuses, cutlines, toaddsequence); %get total loss of buses using this sequence
                lines1 = size(cutlines(cutlines(:, T_BUS) == removedbuses(k, 1), :), 1);
                lines2 = size(cutlines(cutlines(:, F_BUS) == removedbuses(k, 1), :), 1);
                iterrestored = cursequences(j).lossafteriter - lossafteriter;
                totaltime = cursequences(j).totaltime + lines1 + lines2;
                if isa(newsequences, 'double') %create newsequence on first go through. Please find a better way to do this
                    newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2),'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', iterrestored, 'totaltime', totaltime);
                else %append to newsequences
                    newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', iterrestored, 'totaltime', totaltime)];
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

if n ~= size(removedbuses, 1)
    sequencecosts = [cursequences.mockcost];
    [~, idx] = max(sequencecosts);
    cursequences = cursequences(idx);
end

for i=n+1:size(removedbuses, 1)-1
    for j=1:size(removedbuses,1) %I could add another loop if we're iterating through more than one previous sequence
        if ~ismember(removedbuses(j, 1), cursequences.sequence)
            toaddsequence = [cursequences.sequence; removedbuses(j, 1)];
            lossafteriter = addbusandsim(mpc, removedbuses, cutlines, toaddsequence);
            lines1 = size(cutlines(cutlines(:, T_BUS) == removedbuses(j, 1), :), 1);
            lines2 = size(cutlines(cutlines(:, F_BUS) == removedbuses(j, 1), :), 1);
            iterrestored = cursequences.lossafteriter - lossafteriter;
            totaltime = cursequences.totaltime + lines1 + lines2;
            if isa(newsequences, 'double')
                newsequences = struct('sequence', toaddsequence, 'cost', cursequences.cost + cursequences.lossafteriter*(lines1 + lines2), 'mockcost', cursequences.mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', iterrestored, 'totaltime', totaltime);
            else
                newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences.cost + cursequences.lossafteriter*(lines1 + lines2), 'mockcost', cursequences.mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', iterrestored, 'totaltime', totaltime)];
            end
        end
    end
    allsequences{i} = newsequences;
    sequencecosts = [newsequences.mockcost];
    [~, idx] = max(sequencecosts);
    cursequences = newsequences(idx);
    newsequences = 0;
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
    if isa(newsequences, 'double')
        newsequences = struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', cursequences(j).lossafteriter - lossafteriter, 'totaltime', totaltime);
    else
        newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(j).cost + cursequences(j).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(j).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', cursequences(j).lossafteriter - lossafteriter, 'totaltime', totaltime)];
    end
end
allsequences{end} = newsequences;
sequencecosts = [newsequences.mockcost];
[~, idx] = max(sequencecosts);
cursequence = newsequences(idx);
newsequences = 0;


bestsequence = cursequence.sequence;
cost = cursequence.cost;

end %end of function