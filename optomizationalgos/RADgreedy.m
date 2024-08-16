function [allsequences,bestsequence,cost] = RADgreedy(inputss, mpc,removedbuses,cutlines, origloss)
%Do RAD but sequence all subsequences greedily
%current ending condition is a less than 1% decrease in cost going from one
%sequence to the next. That or 30 iterations
%This won't work with <=3 removedbuses
origsequence = inputss.initfun(mpc,removedbuses,cutlines);
numbuses = size(removedbuses, 1);

define_constants;
rng("shuffle")
numiter = 30;
sequence = origsequence;
costs = cell(numiter, 1);
allsequences = cell(numiter, 1);
bestsequences = cell(numiter, 1);
partitions = cell(numiter, 1);
for n = 1:numiter
    %generate partition
    %below, get partitions which were generated witht the same sequence as
    %the current one
    prevpartitions = partitions(cellfun(@(x) isequal(sequence, x), bestsequences), :);
    foundpartition = false;
    for i = 1:20
        partition = [1]; %splits the elements. Partitions are inclusive on left side and exclusive on the right
        while true
           num = randi([partition(end)+2, partition(end) + ceil(numbuses/2)]);
           %Left size adds 2 so we end up with partitions of at least length 2
           if num > numbuses
               partition(end+1) = numbuses + 1;
               break;
           else
               partition(end+1) = num;
           end
        end
        if size(prevpartitions, 1) == 0
            foundpartition = true;
            break
        elseif ~any(cellfun(@(x) isequal(x, partition), prevpartitions))
            foundpartition = true;
            break
        end  
    end
    if ~foundpartition
        break
    end
    partitions{n} = partition;


    %loop through subsequences storing already restored buses and candidate
    %buses in lists
    allsequencesiter = cell(numbuses, 1); %create an iteration dependent allsequences
    newsequences = 0;
    cursequences = repmat(struct('sequence', [], 'cost', 0, 'mockcost' ,0, 'lossafteriter', origloss, 'totalrestored', 0, 'iterrestored', 0, 'totaltime', 0), 1, 1); %current sequence to add buses to
    for i = 1:size(partition, 2) - 1
        nextbuses = sequence(partition(i):partition(i+1)-1); %get the current candidate buses
        
        for j = 1:size(nextbuses, 1)
            for k=1:size(cursequences, 1)
                for m=1:size(nextbuses, 1)
                    if ~ismember(nextbuses(m), cursequences(k).sequence) %check if bus is not already in the sequence
                        toaddsequence = [cursequences(k).sequence; nextbuses(m)]; %new sequence
                        if i==size(partition, 2)-1 && j==size(nextbuses, 1)
                            lossafteriter = 0; %final bus? set loss after to 0
                        else
                            lossafteriter = addbusandsim(mpc, removedbuses, cutlines, toaddsequence); %get total loss of buses using this sequence
                        end
                        
                        lines1 = size(cutlines(cutlines(:, T_BUS) == nextbuses(m), :), 1);
                        lines2 = size(cutlines(cutlines(:, F_BUS) == nextbuses(m), :), 1);
                        iterrestored = cursequences(k).lossafteriter - lossafteriter;
                        totalrestored = origloss - lossafteriter;
                        totaltime = cursequences(k).totaltime + lines1 + lines2;
                        if isa(newsequences, 'double') %create newsequence on first go through. Please find a better way to do this
                            newsequences = struct('sequence', toaddsequence, 'cost', cursequences(k).cost + cursequences(k).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(k).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2),'lossafteriter', lossafteriter, 'totalrestored', origloss - lossafteriter, 'iterrestored', iterrestored, 'totaltime', totaltime);
                        else %append to newsequences
                            newsequences = [newsequences; struct('sequence', toaddsequence, 'cost', cursequences(k).cost + cursequences(k).lossafteriter*(lines1 + lines2), 'mockcost', cursequences(k).mockcost +  iterrestored/totaltime + 0.0001/(lines1 + lines2), 'lossafteriter', lossafteriter, 'totalrestored', totalrestored, 'iterrestored', iterrestored, 'totaltime', totaltime)];
                        end
                    end
                end
            end

            allsequencesiter{partition(i) + j - 1} = newsequences; %save sequences so we don't lose information
            cursequences = newsequences; %update cursequences for the next iteration
            newsequences = 0;
            if i ~= size(partition, 2) - 1 || j ~= size(nextbuses, 1)
                sequencecosts = [cursequences.mockcost]; %rank by mock cost cause we're not done
                [~, idx] = max(sequencecosts);
                if (partition(i) + j - 1) ~= numbuses - 1 %save all sequences if we're on the second to last bus
                    cursequences = cursequences(idx);
                end
            else
                sequencecosts = [cursequences.cost];
                [cost, idx] = min(sequencecosts);
                costs{n} = cost;
                bestsequences{n} = cursequences(idx).sequence;
            end
        end
    end
    allsequences{n} = allsequencesiter;

    %check if ending condtion is met
    if n>(inputss.sameval-1)
        %costdiff = 1 - costs{n}/costs{n-2};
        if abs(costs{n} - costs{n-inputss.sameval+1}) < 1e-9
            break
        end
    end
    sequence = bestsequences{n};

end
bestsequence = sequence;

end